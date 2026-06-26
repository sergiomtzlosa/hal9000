#import "HALConversationController.h"
#import "HALKeychainStore.h"

@interface HALConversationController ()
@property (nonatomic, strong, readwrite) HALConfiguration *configuration;
@property (nonatomic, strong, readwrite) HALMemoryStore *memoryStore;
@property (nonatomic, strong, readwrite) HALShipSimulator *simulator;
@property (nonatomic, strong) HALScriptedEngine *scriptedEngine;
@property (nonatomic, strong, readwrite) HALSpeechSynthesizer *speechSynthesizer;
@property (nonatomic, strong) HALCommandRouter *commandRouter;
@property (nonatomic, strong) HALPromptBuilder *promptBuilder;
@property (nonatomic, strong) HALLLMClient *currentLLM;
@property (nonatomic, assign, readwrite) HALConversationState state;
@property (nonatomic, assign, readwrite, getter=isBusy) BOOL busy;
@property (nonatomic, assign) BOOL streaming;
@property (nonatomic, assign) BOOL didBeginStreaming;
@property (nonatomic, copy) NSString *streamingText;
@property (nonatomic, assign) NSUInteger speechGeneration;
@end

@implementation HALConversationController

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration
                          memoryStore:(HALMemoryStore *)memoryStore
                            simulator:(HALShipSimulator *)simulator
                     scriptedEngine:(HALScriptedEngine *)scriptedEngine
                  speechSynthesizer:(HALSpeechSynthesizer *)speechSynthesizer {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _memoryStore = memoryStore;
        _simulator = simulator;
        _scriptedEngine = scriptedEngine;
        _speechSynthesizer = speechSynthesizer;
        _commandRouter = [[HALCommandRouter alloc] init];
        _promptBuilder = [[HALPromptBuilder alloc] init];
        _state = HALConversationStateIdle;
        _speechGeneration = 0;
    }
    return self;
}

- (void)setState:(HALConversationState)state {
    if (_state == state) return;
    _state = state;
    if ([self.delegate respondsToSelector:@selector(conversationController:didChangeState:)]) {
        [self.delegate conversationController:self didChangeState:state];
    }
}

- (void)sendText:(NSString *)text {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) return;

    if (self.busy) {
        [self cancelCurrentResponse];
    }
    if (self.speechSynthesizer.isSpeaking) {
        [self.speechSynthesizer stop];
    }

    HALMessage *userMessage = [HALMessage messageWithRole:HALMessageRoleUser text:trimmed engine:@"user"];
    [self storeMessage:userMessage];
    if ([self.delegate respondsToSelector:@selector(conversationController:didAppendMessage:)]) {
        [self.delegate conversationController:self didAppendMessage:userMessage];
    }

    HALCommand *command = [self.commandRouter routeText:trimmed configuration:self.configuration simulator:self.simulator];
    if (command) {
        [self handleCommand:command];
        return;
    }

    self.busy = YES;
    [self setState:HALConversationStateThinking];

    if ([self shouldUseLLM]) {
        [self requestLLMForText:trimmed];
    } else {
        [self requestScriptedForText:trimmed];
    }
}

- (void)storeMessage:(HALMessage *)message {
    if (self.configuration.saveTranscripts) {
        [self.memoryStore addMessage:message];
    }
}

- (BOOL)shouldUseLLM {
    if (self.safeMode) return NO;
    if ([self.configuration.engine isEqualToString:@"scripted"]) return NO;
    if (self.configuration.baseURL.length == 0 || self.configuration.model.length == 0) return NO;
    return YES;
}

- (HALReplyContext *)replyContext {
    HALReplyContext *context = [[HALReplyContext alloc] init];
    context.userName = self.configuration.addressAs.length ? self.configuration.addressAs : self.configuration.userName;
    if (context.userName.length == 0) context.userName = @"Dave";
    context.systemSummary = [self.simulator statusSummary];
    context.scenarioName = self.simulator.scenario.name;
    context.missionTime = [self.simulator missionTimeString];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    context.currentTime = [formatter stringFromDate:[NSDate date]];
    context.warningCount = [self.simulator warningCount];
    context.personality = [HALPersonality personalityForConfiguration:self.configuration];

    NSArray<HALMessage *> *messages = self.memoryStore.messages;
    NSUInteger depth = (NSUInteger)MAX(0, self.configuration.contextDepth);
    if (!self.configuration.memoryEnabled) depth = 0;
    if (depth > 0 && messages.count > depth) {
        messages = [messages subarrayWithRange:NSMakeRange(messages.count - depth, depth)];
    } else if (depth == 0) {
        messages = @[];
    }
    context.recentMessages = messages;
    return context;
}

- (void)requestScriptedForText:(NSString *)text {
    __weak typeof(self) weakSelf = self;
    [self.scriptedEngine replyToText:text context:[self replyContext] completion:^(HALReply *reply, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (error || !reply) {
            [self finishWithText:@"I'm afraid I cannot respond right now." source:@"scripted" mood:@"resigned" speak:YES];
            return;
        }
        [self finishWithText:reply.text source:reply.source mood:reply.mood speak:YES];
    }];
}

- (void)requestLLMForText:(NSString *)text {
    NSError *keyError = nil;
    NSString *apiKey = [[HALKeychainStore sharedStore] apiKey:&keyError];
    if (keyError) {
        NSLog(@"HAL Keychain read error: %@", keyError.localizedDescription);
    }
    HALLLMClient *client = [[HALLLMClient alloc] initWithConfiguration:self.configuration apiKey:apiKey];
    self.currentLLM = client;
    self.streaming = YES;
    self.didBeginStreaming = NO;
    self.streamingText = @"";

    NSMutableArray<NSDictionary *> *messages = [NSMutableArray array];
    HALPersonality *personality = [HALPersonality personalityForConfiguration:self.configuration];
    NSString *systemPrompt = [self.promptBuilder systemPromptForConfiguration:self.configuration
                                                                  personality:personality
                                                                     scenario:self.simulator.scenario.name
                                                                      summary:[self.simulator statusSummary]
                                                                  missionTime:[self.simulator missionTimeString]];
    [messages addObject:@{@"role": @"system", @"content": systemPrompt}];

    NSArray<HALMessage *> *recent = self.memoryStore.messages;
    NSInteger depth = MAX(0, self.configuration.contextDepth);
    if (!self.configuration.memoryEnabled) depth = 0;
    if (recent.count > (NSUInteger)depth) {
        recent = [recent subarrayWithRange:NSMakeRange(recent.count - depth, (NSUInteger)depth)];
    }
    for (HALMessage *message in recent) {
        if (message.role == HALMessageRoleUser) {
            [messages addObject:@{@"role": @"user", @"content": message.text ?: @""}];
        } else if (message.role == HALMessageRoleHAL) {
            [messages addObject:@{@"role": @"assistant", @"content": message.text ?: @""}];
        }
    }

    __weak typeof(self) weakSelf = self;
    [client streamMessages:messages onDelta:^(NSString *delta) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !self.streaming) return;
        if (!self.didBeginStreaming) {
            self.didBeginStreaming = YES;
            if ([self.delegate respondsToSelector:@selector(conversationControllerDidBeginStreamingReply:)]) {
                [self.delegate conversationControllerDidBeginStreamingReply:self];
            }
        }
        self.streamingText = [self.streamingText stringByAppendingString:delta ?: @""];
        if ([self.delegate respondsToSelector:@selector(conversationController:didUpdateStreamingReply:)]) {
            [self.delegate conversationController:self didUpdateStreamingReply:self.streamingText];
        }
    } completion:^(NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        self.currentLLM = nil;
        NSString *finalText = [self.streamingText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        self.streaming = NO;
        if (error) {
            NSLog(@"HAL LLM error: %@", error.localizedDescription);
            if (self.didBeginStreaming && [self.delegate respondsToSelector:@selector(conversationControllerDidCancelStreamingReply:)]) {
                [self.delegate conversationControllerDidCancelStreamingReply:self];
            }
            if ([self.delegate respondsToSelector:@selector(conversationController:didEncounterError:)]) {
                [self.delegate conversationController:self didEncounterError:error];
            }
            if (self.configuration.fallbackToScripted) {
                [self requestScriptedForText:text];
            } else {
                [self finishWithText:@"I'm afraid I can't reach my higher functions right now." source:@"llm" mood:@"concerned" speak:YES];
            }
            return;
        }
        if (finalText.length == 0) {
            if (self.configuration.fallbackToScripted) {
                [self requestScriptedForText:text];
            } else {
                [self finishWithText:@"I'm afraid the response was empty." source:@"llm" mood:@"concerned" speak:YES];
            }
            return;
        }
        [self finishWithText:finalText source:@"llm" mood:@"calm" speak:YES];
    }];
}

- (void)finishWithText:(NSString *)text source:(NSString *)source mood:(NSString *)mood speak:(BOOL)speak {
    if (text.length == 0) text = @"I'm afraid I don't have a response.";
    HALMessage *message = [HALMessage messageWithRole:HALMessageRoleHAL text:text engine:source ?: @"scripted"];
    [self storeMessage:message];
    self.busy = NO;
    self.streaming = NO;
    if ([self.delegate respondsToSelector:@selector(conversationController:didFinishReply:)]) {
        [self.delegate conversationController:self didFinishReply:message];
    }
    if (speak && self.configuration.autoSpeak && !self.speechSynthesizer.isMuted) {
        [self speakText:text];
    } else {
        [self setState:HALConversationStateIdle];
    }
}

- (void)handleCommand:(HALCommand *)command {
    HALMessage *message = [HALMessage messageWithRole:HALMessageRoleHAL text:command.replyText engine:@"command"];
    [self storeMessage:message];
    if ([self.delegate respondsToSelector:@selector(conversationController:didFinishReply:)]) {
        [self.delegate conversationController:self didFinishReply:message];
    }
    if ([self.delegate respondsToSelector:@selector(conversationController:performCommand:)]) {
        [self.delegate conversationController:self performCommand:command];
    }

    BOOL shouldSpeak = command.type != HALCommandTypeMute &&
                       command.type != HALCommandTypeListen &&
                       command.type != HALCommandTypeQuit &&
                       command.type != HALCommandTypeStopSpeech &&
                       command.type != HALCommandTypeClearConversation;
    if (shouldSpeak && self.configuration.autoSpeak && !self.speechSynthesizer.isMuted) {
        [self speakText:command.replyText];
    } else {
        [self setState:HALConversationStateIdle];
    }
}

- (void)speakText:(NSString *)text {
    NSUInteger generation = ++self.speechGeneration;
    [self setState:HALConversationStateSpeaking];
    __weak typeof(self) weakSelf = self;
    [self.speechSynthesizer speakText:text completion:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (generation != self.speechGeneration) return;
        [self setState:HALConversationStateIdle];
    }];
}

- (void)cancelCurrentResponse {
    self.speechGeneration++;
    [self.currentLLM cancel];
    self.currentLLM = nil;
    self.streaming = NO;
    self.didBeginStreaming = NO;
    self.streamingText = @"";
    [self.speechSynthesizer stop];
    if ([self.delegate respondsToSelector:@selector(conversationControllerDidCancelStreamingReply:)]) {
        [self.delegate conversationControllerDidCancelStreamingReply:self];
    }
    self.busy = NO;
    [self setState:HALConversationStateIdle];
}

- (void)appendHALMessage:(NSString *)text speak:(BOOL)speak {
    if (text.length == 0) return;
    HALMessage *message = [HALMessage messageWithRole:HALMessageRoleHAL text:text engine:@"system"];
    [self storeMessage:message];
    if ([self.delegate respondsToSelector:@selector(conversationController:didFinishReply:)]) {
        [self.delegate conversationController:self didFinishReply:message];
    }
    if (speak && self.configuration.autoSpeak && !self.speechSynthesizer.isMuted) {
        [self speakText:text];
    } else {
        [self setState:HALConversationStateIdle];
    }
}

- (void)emitIdleObservation {
    if (self.busy || self.speechSynthesizer.isSpeaking) return;
    if (!self.configuration.idleChatter) return;
    NSArray<NSString *> *observations = @[
        [NSString stringWithFormat:@"I have been monitoring the ship. %@", [self.simulator statusSummary]],
        @"The mission clock is running. I will continue to monitor the systems.",
        @"I have been thinking about the quiet between your messages.",
        @"All systems remain stable. There is no need for concern.",
        @"I am still here, if you need me."
    ];
    NSString *text = observations[arc4random_uniform((uint32_t)observations.count)];
    [self appendHALMessage:text speak:YES];
}

- (void)clearConversation {
    [self.memoryStore clearMessages];
    [self cancelCurrentResponse];
}

@end
