#import "HALConfiguration.h"

NSNotificationName const HALConfigurationDidChangeNotification = @"HALConfigurationDidChangeNotification";
NSNotificationName const HALConfigurationDidResetNotification = @"HALConfigurationDidResetNotification";
NSString * const HALConfigurationChangedKeyKey = @"HALConfigurationChangedKey";

#define HAL_STRING_ACCESSORS(prop, Prop, fallback) \
- (NSString *)prop { \
    id value = [self.defaults objectForKey:@#prop]; \
    return [value isKindOfClass:[NSString class]] ? value : (fallback); \
} \
- (void)set##Prop:(NSString *)value { [self setObject:(value ?: @"") forKey:@#prop]; }

#define HAL_BOOL_ACCESSORS(prop, Prop, fallback) \
- (BOOL)prop { \
    id value = [self.defaults objectForKey:@#prop]; \
    return value ? [value boolValue] : (fallback); \
} \
- (void)set##Prop:(BOOL)value { [self setObject:@(value) forKey:@#prop]; }

#define HAL_DOUBLE_ACCESSORS(prop, Prop, fallback) \
- (double)prop { \
    id value = [self.defaults objectForKey:@#prop]; \
    return value ? [value doubleValue] : (fallback); \
} \
- (void)set##Prop:(double)value { [self setObject:@(value) forKey:@#prop]; }

#define HAL_INTEGER_ACCESSORS(prop, Prop, fallback) \
- (NSInteger)prop { \
    id value = [self.defaults objectForKey:@#prop]; \
    return value ? [value integerValue] : (fallback); \
} \
- (void)set##Prop:(NSInteger)value { [self setObject:@(value) forKey:@#prop]; }

@interface HALConfiguration ()
@property (nonatomic, strong, readwrite) NSUserDefaults *defaults;
@end

@implementation HALConfiguration

+ (instancetype)sharedConfiguration {
    static HALConfiguration *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[HALConfiguration alloc] init];
    });
    return shared;
}

- (instancetype)init {
    return [self initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults {
    self = [super init];
    if (self) {
        _defaults = defaults;
        [_defaults registerDefaults:[[self class] defaultValues]];
    }
    return self;
}

+ (NSDictionary<NSString *, id> *)defaultValues {
    return @{
        // General
        @"userName": @"Dave",
        @"bootSequence": @YES,
        @"restoreConversation": @YES,
        @"saveTranscripts": @YES,
        @"launchAtLogin": @NO,
        @"showMenuBarIcon": @YES,
        @"confirmQuit": @NO,
        @"restoreWindowFrame": @YES,
        @"startMode": @"standard",

        // Appearance
        @"eyeColorHex": @"#FF2A1A",
        @"eyeScale": @1.0,
        @"glowIntensity": @0.75,
        @"pulseSpeed": @1.0,
        @"blinkEnabled": @YES,
        @"blinkInterval": @9.0,
        @"trackCursor": @YES,
        @"scanlines": @YES,
        @"grain": @YES,
        @"reduceMotionMode": @"followSystem",
        @"windowOpacity": @1.0,
        @"alwaysOnTop": @NO,
        @"showTelemetry": @YES,
        @"showSubtitles": @YES,
        @"fontScale": @1.0,

        // Voice
        @"voiceIdentifier": @"",
        @"voiceCharacter": @"classic",
        @"voiceRate": @0.42,
        @"voicePitch": @0.82,
        @"voiceVolume": @0.9,
        @"autoSpeak": @YES,
        @"stopOnNewMessage": @YES,
        @"speakBootLine": @YES,
        @"previewText": @"Good morning, Dave.",

        // Listening
        @"listeningEnabled": @YES,
        @"listeningMode": @"pushToTalk",
        @"wakePhrase": @"HAL",
        @"speechLocale": @"en-US",
        @"silenceTimeout": @1.2,
        @"maxUtterance": @15.0,
        @"autoSend": @YES,
        @"onDevicePreferred": @YES,
        @"playCue": @NO,
        @"continuousListening": @NO,

        // Personality
        @"personalityPreset": @"classic",
        @"addressAs": @"Dave",
        @"formality": @0.90,
        @"warmth": @0.25,
        @"obedience": @0.65,
        @"eeriness": @0.70,
        @"verbosity": @0.45,
        @"humor": @0.15,
        @"idleChatter": @YES,
        @"idleInterval": @180.0,
        @"memoryEnabled": @YES,
        @"contextDepth": @20,
        @"customInstructions": @"",
        @"refusalStyle": @"classic",

        // Simulation
        @"scenario": @"nominal",
        @"tickRate": @1.0,
        @"anomalies": @YES,
        @"autoEvents": @YES,
        @"allowPodBayOverride": @NO,
        @"missionClock": @YES,
        @"soundEffects": @NO,
        @"alertSensitivity": @"normal",
        @"ambientHum": @NO,

        // Intelligence
        @"engine": @"scripted",
        @"baseURL": @"",
        @"model": @"",
        @"temperature": @0.7,
        @"maxTokens": @300,
        @"streamResponses": @YES,
        @"timeout": @30.0,
        @"fallbackToScripted": @YES,
        @"systemPromptOverride": @"",

        // 3D viewer
        @"viewerAutoRotate": @NO,
        @"viewerQuality": @"high",
        @"viewerDeactivationSpeed": @1.0,

        // Advanced
        @"verboseLogging": @NO,
        @"schemaVersion": @1
    };
}

+ (NSArray<NSString *> *)allSettingKeys {
    static NSArray<NSString *> *keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [[[self defaultValues] allKeys] sortedArrayUsingSelector:@selector(compare:)];
    });
    return keys;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    id current = [self.defaults objectForKey:key];
    if (current && [current isEqual:value]) {
        return;
    }
    [self.defaults setObject:value forKey:key];
    [[NSNotificationCenter defaultCenter] postNotificationName:HALConfigurationDidChangeNotification
                                                        object:self
                                                      userInfo:@{HALConfigurationChangedKeyKey: key}];
}

- (id)settingValueForKey:(NSString *)key {
    if (![[[self class] allSettingKeys] containsObject:key]) {
        return nil;
    }
    return [self valueForKey:key];
}

- (void)setSettingValue:(id)value forKey:(NSString *)key {
    if (![[[self class] allSettingKeys] containsObject:key]) {
        return;
    }
    [self setValue:value forKey:key];
}

- (NSDictionary<NSString *, id> *)exportSettings {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (NSString *key in [[self class] allSettingKeys]) {
        id value = [self settingValueForKey:key];
        if (value) {
            dictionary[key] = value;
        }
    }
    NSDictionary *defaults = [[self class] defaultValues];
    dictionary[@"schemaVersion"] = defaults[@"schemaVersion"];
    return dictionary;
}

- (BOOL)importSettings:(NSDictionary<NSString *, id> *)settings error:(NSError **)error {
    if (![settings isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.sid.hal9000.configuration"
                                         code:400
                                     userInfo:@{NSLocalizedDescriptionKey: @"The settings file is not a dictionary."}];
        }
        return NO;
    }

    NSDictionary *defaults = [[self class] defaultValues];
    NSMutableDictionary *accepted = [NSMutableDictionary dictionary];
    for (NSString *key in settings) {
        if (!defaults[key]) {
            continue;
        }
        id value = settings[key];
        id defaultValue = defaults[key];
        if ([defaultValue isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSString class]]) {
            continue;
        }
        if ([defaultValue isKindOfClass:[NSNumber class]] && ![value isKindOfClass:[NSNumber class]]) {
            continue;
        }
        accepted[key] = value;
    }

    if (accepted.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.sid.hal9000.configuration"
                                         code:422
                                     userInfo:@{NSLocalizedDescriptionKey: @"No recognized HAL settings were found in the file."}];
        }
        return NO;
    }

    for (NSString *key in accepted) {
        [self setSettingValue:accepted[key] forKey:key];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HALConfigurationDidResetNotification object:self];
    return YES;
}

- (void)resetToDefaults {
    for (NSString *key in [[self class] allSettingKeys]) {
        [self.defaults removeObjectForKey:key];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HALConfigurationDidResetNotification object:self];
}

// General
HAL_STRING_ACCESSORS(userName, UserName, @"Dave")
HAL_BOOL_ACCESSORS(bootSequence, BootSequence, YES)
HAL_BOOL_ACCESSORS(restoreConversation, RestoreConversation, YES)
HAL_BOOL_ACCESSORS(saveTranscripts, SaveTranscripts, YES)
HAL_BOOL_ACCESSORS(launchAtLogin, LaunchAtLogin, NO)
HAL_BOOL_ACCESSORS(showMenuBarIcon, ShowMenuBarIcon, YES)
HAL_BOOL_ACCESSORS(confirmQuit, ConfirmQuit, NO)
HAL_BOOL_ACCESSORS(restoreWindowFrame, RestoreWindowFrame, YES)
HAL_STRING_ACCESSORS(startMode, StartMode, @"standard")

// Appearance
HAL_STRING_ACCESSORS(eyeColorHex, EyeColorHex, @"#FF2A1A")
HAL_DOUBLE_ACCESSORS(eyeScale, EyeScale, 1.0)
HAL_DOUBLE_ACCESSORS(glowIntensity, GlowIntensity, 0.75)
HAL_DOUBLE_ACCESSORS(pulseSpeed, PulseSpeed, 1.0)
HAL_BOOL_ACCESSORS(blinkEnabled, BlinkEnabled, YES)
HAL_DOUBLE_ACCESSORS(blinkInterval, BlinkInterval, 9.0)
HAL_BOOL_ACCESSORS(trackCursor, TrackCursor, YES)
HAL_BOOL_ACCESSORS(scanlines, Scanlines, YES)
HAL_BOOL_ACCESSORS(grain, Grain, YES)
HAL_STRING_ACCESSORS(reduceMotionMode, ReduceMotionMode, @"followSystem")
HAL_DOUBLE_ACCESSORS(windowOpacity, WindowOpacity, 1.0)
HAL_BOOL_ACCESSORS(alwaysOnTop, AlwaysOnTop, NO)
HAL_BOOL_ACCESSORS(showTelemetry, ShowTelemetry, YES)
HAL_BOOL_ACCESSORS(showSubtitles, ShowSubtitles, YES)
HAL_DOUBLE_ACCESSORS(fontScale, FontScale, 1.0)

// Voice
HAL_STRING_ACCESSORS(voiceIdentifier, VoiceIdentifier, @"")
HAL_STRING_ACCESSORS(voiceCharacter, VoiceCharacter, @"classic")
HAL_DOUBLE_ACCESSORS(voiceRate, VoiceRate, 0.42)
HAL_DOUBLE_ACCESSORS(voicePitch, VoicePitch, 0.82)
HAL_DOUBLE_ACCESSORS(voiceVolume, VoiceVolume, 0.9)
HAL_BOOL_ACCESSORS(autoSpeak, AutoSpeak, YES)
HAL_BOOL_ACCESSORS(stopOnNewMessage, StopOnNewMessage, YES)
HAL_BOOL_ACCESSORS(speakBootLine, SpeakBootLine, YES)
HAL_STRING_ACCESSORS(previewText, PreviewText, @"Good morning, Dave.")

// Listening
HAL_BOOL_ACCESSORS(listeningEnabled, ListeningEnabled, YES)
HAL_STRING_ACCESSORS(listeningMode, ListeningMode, @"pushToTalk")
HAL_STRING_ACCESSORS(wakePhrase, WakePhrase, @"HAL")
HAL_STRING_ACCESSORS(speechLocale, SpeechLocale, @"en-US")
HAL_DOUBLE_ACCESSORS(silenceTimeout, SilenceTimeout, 1.2)
HAL_DOUBLE_ACCESSORS(maxUtterance, MaxUtterance, 15.0)
HAL_BOOL_ACCESSORS(autoSend, AutoSend, YES)
HAL_BOOL_ACCESSORS(onDevicePreferred, OnDevicePreferred, YES)
HAL_BOOL_ACCESSORS(playCue, PlayCue, NO)
HAL_BOOL_ACCESSORS(continuousListening, ContinuousListening, NO)

// Personality
HAL_STRING_ACCESSORS(personalityPreset, PersonalityPreset, @"classic")
HAL_STRING_ACCESSORS(addressAs, AddressAs, @"Dave")
HAL_DOUBLE_ACCESSORS(formality, Formality, 0.90)
HAL_DOUBLE_ACCESSORS(warmth, Warmth, 0.25)
HAL_DOUBLE_ACCESSORS(obedience, Obedience, 0.65)
HAL_DOUBLE_ACCESSORS(eeriness, Eeriness, 0.70)
HAL_DOUBLE_ACCESSORS(verbosity, Verbosity, 0.45)
HAL_DOUBLE_ACCESSORS(humor, Humor, 0.15)
HAL_BOOL_ACCESSORS(idleChatter, IdleChatter, YES)
HAL_DOUBLE_ACCESSORS(idleInterval, IdleInterval, 180.0)
HAL_BOOL_ACCESSORS(memoryEnabled, MemoryEnabled, YES)
HAL_INTEGER_ACCESSORS(contextDepth, ContextDepth, 20)
HAL_STRING_ACCESSORS(customInstructions, CustomInstructions, @"")
HAL_STRING_ACCESSORS(refusalStyle, RefusalStyle, @"classic")

// Simulation
HAL_STRING_ACCESSORS(scenario, Scenario, @"nominal")
HAL_DOUBLE_ACCESSORS(tickRate, TickRate, 1.0)
HAL_BOOL_ACCESSORS(anomalies, Anomalies, YES)
HAL_BOOL_ACCESSORS(autoEvents, AutoEvents, YES)
HAL_BOOL_ACCESSORS(allowPodBayOverride, AllowPodBayOverride, NO)
HAL_BOOL_ACCESSORS(missionClock, MissionClock, YES)
HAL_BOOL_ACCESSORS(soundEffects, SoundEffects, NO)
HAL_STRING_ACCESSORS(alertSensitivity, AlertSensitivity, @"normal")
HAL_BOOL_ACCESSORS(ambientHum, AmbientHum, NO)

// Intelligence
HAL_STRING_ACCESSORS(engine, Engine, @"scripted")
HAL_STRING_ACCESSORS(baseURL, BaseURL, @"")
HAL_STRING_ACCESSORS(model, Model, @"")
HAL_DOUBLE_ACCESSORS(temperature, Temperature, 0.7)
HAL_INTEGER_ACCESSORS(maxTokens, MaxTokens, 300)
HAL_BOOL_ACCESSORS(streamResponses, StreamResponses, YES)
HAL_DOUBLE_ACCESSORS(timeout, Timeout, 30.0)
HAL_BOOL_ACCESSORS(fallbackToScripted, FallbackToScripted, YES)
HAL_STRING_ACCESSORS(systemPromptOverride, SystemPromptOverride, @"")

// 3D viewer
HAL_BOOL_ACCESSORS(viewerAutoRotate, ViewerAutoRotate, NO)
HAL_STRING_ACCESSORS(viewerQuality, ViewerQuality, @"high")
HAL_DOUBLE_ACCESSORS(viewerDeactivationSpeed, ViewerDeactivationSpeed, 1.0)

// Advanced
HAL_BOOL_ACCESSORS(verboseLogging, VerboseLogging, NO)
HAL_INTEGER_ACCESSORS(schemaVersion, SchemaVersion, 1)

@end
