#import "HALLLMClient.h"
#import "HALConfiguration.h"
#import "HALSSEParser.h"

static NSString * const HALLLMErrorDomain = @"com.sid.hal9000.llm";

@interface HALLLMClient () <NSURLSessionDataDelegate>
@property (nonatomic, strong, readwrite) HALConfiguration *configuration;
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) HALSSEParser *parser;
@property (nonatomic, copy) void (^deltaBlock)(NSString *delta);
@property (nonatomic, copy) void (^completionBlock)(NSError * _Nullable error);
@property (nonatomic, assign) BOOL streaming;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, assign) BOOL httpError;
@property (nonatomic, assign) NSInteger httpStatus;
@property (nonatomic, strong) NSMutableData *errorData;
@end

@implementation HALLLMClient

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration apiKey:(NSString *)apiKey {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _apiKey = [apiKey copy];
        _parser = [[HALSSEParser alloc] init];
        _errorData = [NSMutableData data];
    }
    return self;
}

- (NSURL *)completionsURL {
    NSString *base = [self.configuration.baseURL stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (base.length == 0) return nil;
    if ([base hasSuffix:@"/chat/completions"]) {
        return [NSURL URLWithString:base];
    }
    base = [base stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    return [NSURL URLWithString:[base stringByAppendingString:@"/chat/completions"]];
}

- (NSError *)errorWithMessage:(NSString *)message code:(NSInteger)code {
    return [NSError errorWithDomain:HALLLMErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @"Unknown LLM error"}];
}

- (void)streamMessages:(NSArray<NSDictionary<NSString *, id> *> *)messages
               onDelta:(void (^)(NSString *delta))onDelta
            completion:(void (^)(NSError * _Nullable error))completion {
    [self cancel];
    self.finished = NO;
    self.cancelled = NO;
    self.httpError = NO;
    self.httpStatus = 0;
    [self.errorData setLength:0];
    [self.parser reset];
    self.deltaBlock = onDelta;
    self.completionBlock = completion;

    NSURL *url = [self completionsURL];
    if (!url) {
        [self finishWithError:[self errorWithMessage:@"Set a valid LLM base URL in Settings → Intelligence." code:401]];
        return;
    }
    if (self.configuration.model.length == 0) {
        [self finishWithError:[self errorWithMessage:@"Set an LLM model name in Settings → Intelligence." code:402]];
        return;
    }

    NSMutableDictionary *body = [@{
        @"model": self.configuration.model,
        @"messages": messages,
        @"temperature": @(self.configuration.temperature),
        @"max_tokens": @(self.configuration.maxTokens),
        @"stream": @(self.configuration.streamResponses)
    } mutableCopy];

    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (!bodyData) {
        [self finishWithError:jsonError ?: [self errorWithMessage:@"Could not encode the LLM request." code:403]];
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = bodyData;
    request.timeoutInterval = MAX(5.0, self.configuration.timeout);
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    if (self.apiKey.length > 0) {
        [request setValue:[@"Bearer " stringByAppendingString:self.apiKey] forHTTPHeaderField:@"Authorization"];
    }

    if (self.configuration.streamResponses) {
        [self startStreamingRequest:request];
    } else {
        [self startNonStreamingRequest:request];
    }
}

- (void)startStreamingRequest:(NSURLRequest *)request {
    self.streaming = YES;
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = MAX(5.0, self.configuration.timeout);
    sessionConfig.timeoutIntervalForResource = MAX(15.0, self.configuration.timeout * 2);
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:queue];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

- (void)startNonStreamingRequest:(NSURLRequest *)request {
    self.streaming = NO;
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = MAX(5.0, self.configuration.timeout);
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig];
    __weak typeof(self) weakSelf = self;
    self.task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        if (error) {
            [self finishWithError:error];
            return;
        }
        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
            [self finishWithError:[self errorWithMessage:[NSString stringWithFormat:@"LLM HTTP %ld: %@", (long)http.statusCode, body] code:http.statusCode]];
            return;
        }
        NSError *jsonError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSString *content = [self contentFromObject:object];
        // Retain the block locally. finishWithError: clears the property, and
        // invoking a nil block pointer is a crash (unlike messaging nil).
        void (^deltaBlock)(NSString *) = self.deltaBlock;
        if (content.length > 0 && deltaBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ deltaBlock(content); });
        }
        if ([content length] == 0 && ![object isKindOfClass:[NSDictionary class]]) {
            [self finishWithError:jsonError ?: [self errorWithMessage:@"The LLM returned an unreadable response." code:502]];
            return;
        }
        [self finishWithError:nil];
    }];
    [self.task resume];
}

- (void)cancel {
    self.cancelled = YES;
    if (self.task) {
        [self.task cancel];
    }
    [self.session invalidateAndCancel];
    self.session = nil;
    self.task = nil;
}

- (void)finishWithError:(NSError *)error {
    if (self.finished) return;
    self.finished = YES;
    [self.session finishTasksAndInvalidate];
    self.session = nil;
    self.task = nil;
    void (^completion)(NSError *) = self.completionBlock;
    self.completionBlock = nil;
    self.deltaBlock = nil;
    if (completion) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
    }
}

- (nullable NSString *)contentFromObject:(id)object {
    if (![object isKindOfClass:[NSDictionary class]]) return nil;
    NSArray *choices = ((NSDictionary *)object)[@"choices"];
    if ([choices isKindOfClass:[NSArray class]] && choices.count > 0) {
        NSDictionary *choice = choices[0];
        if ([choice isKindOfClass:[NSDictionary class]]) {
            NSDictionary *message = choice[@"message"];
            if ([message isKindOfClass:[NSDictionary class]] && [message[@"content"] isKindOfClass:[NSString class]]) {
                return message[@"content"];
            }
            NSDictionary *delta = choice[@"delta"];
            if ([delta isKindOfClass:[NSDictionary class]] && [delta[@"content"] isKindOfClass:[NSString class]]) {
                return delta[@"content"];
            }
            if ([choice[@"text"] isKindOfClass:[NSString class]]) {
                return choice[@"text"];
            }
        }
    }
    if ([object[@"response"] isKindOfClass:[NSString class]]) {
        return object[@"response"];
    }
    NSDictionary *message = object[@"message"];
    if ([message isKindOfClass:[NSDictionary class]] && [message[@"content"] isKindOfClass:[NSString class]]) {
        return message[@"content"];
    }
    return nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;
    if ([http isKindOfClass:[NSHTTPURLResponse class]]) {
        self.httpStatus = http.statusCode;
        if (http.statusCode < 200 || http.statusCode >= 300) {
            self.httpError = YES;
        }
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.httpError) {
        [self.errorData appendData:data];
        return;
    }
    NSArray<NSDictionary *> *events = [self.parser appendData:data];
    for (NSDictionary *event in events) {
        if ([event[@"done"] boolValue]) {
            continue;
        }
        NSString *content = [self contentFromObject:event];
        void (^deltaBlock)(NSString *) = self.deltaBlock;
        if (content.length > 0 && deltaBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ deltaBlock(content); });
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.cancelled) {
        [self finishWithError:[self errorWithMessage:@"The LLM request was cancelled." code:NSURLErrorCancelled]];
        return;
    }
    if (self.httpError) {
        NSString *body = [[NSString alloc] initWithData:self.errorData encoding:NSUTF8StringEncoding] ?: @"";
        [self finishWithError:[self errorWithMessage:[NSString stringWithFormat:@"LLM HTTP %ld: %@", (long)self.httpStatus, body] code:self.httpStatus ?: 500]];
        return;
    }
    if (error) {
        [self finishWithError:error];
        return;
    }
    [self finishWithError:nil];
}

@end
