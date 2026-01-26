#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const HALConfigurationDidChangeNotification;
extern NSNotificationName const HALConfigurationDidResetNotification;
extern NSString * const HALConfigurationChangedKeyKey;

@interface HALConfiguration : NSObject

@property (nonatomic, strong, readonly) NSUserDefaults *defaults;

+ (instancetype)sharedConfiguration;
- (instancetype)initWithUserDefaults:(NSUserDefaults *)defaults NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

+ (NSDictionary<NSString *, id> *)defaultValues;
+ (NSArray<NSString *> *)allSettingKeys;

- (id)settingValueForKey:(NSString *)key;
- (void)setSettingValue:(id)value forKey:(NSString *)key;

- (NSDictionary<NSString *, id> *)exportSettings;
- (BOOL)importSettings:(NSDictionary<NSString *, id> *)settings error:(NSError **)error;
- (void)resetToDefaults;

// General
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) BOOL bootSequence;
@property (nonatomic, assign) BOOL restoreConversation;
@property (nonatomic, assign) BOOL saveTranscripts;
@property (nonatomic, assign) BOOL launchAtLogin;
@property (nonatomic, assign) BOOL showMenuBarIcon;
@property (nonatomic, assign) BOOL confirmQuit;
@property (nonatomic, assign) BOOL restoreWindowFrame;
@property (nonatomic, copy) NSString *startMode;

// Appearance
@property (nonatomic, copy) NSString *eyeColorHex;
@property (nonatomic, assign) double eyeScale;
@property (nonatomic, assign) double glowIntensity;
@property (nonatomic, assign) double pulseSpeed;
@property (nonatomic, assign) BOOL blinkEnabled;
@property (nonatomic, assign) double blinkInterval;
@property (nonatomic, assign) BOOL trackCursor;
@property (nonatomic, assign) BOOL scanlines;
@property (nonatomic, assign) BOOL grain;
@property (nonatomic, copy) NSString *reduceMotionMode;
@property (nonatomic, assign) double windowOpacity;
@property (nonatomic, assign) BOOL alwaysOnTop;
@property (nonatomic, assign) BOOL showTelemetry;
@property (nonatomic, assign) BOOL showSubtitles;
@property (nonatomic, assign) double fontScale;

// Voice
@property (nonatomic, copy) NSString *voiceIdentifier;
@property (nonatomic, copy) NSString *voiceCharacter;
@property (nonatomic, assign) double voiceRate;
@property (nonatomic, assign) double voicePitch;
@property (nonatomic, assign) double voiceVolume;
@property (nonatomic, assign) BOOL autoSpeak;
@property (nonatomic, assign) BOOL stopOnNewMessage;
@property (nonatomic, assign) BOOL speakBootLine;
@property (nonatomic, copy) NSString *previewText;

// Listening
@property (nonatomic, assign) BOOL listeningEnabled;
@property (nonatomic, copy) NSString *listeningMode;
@property (nonatomic, copy) NSString *wakePhrase;
@property (nonatomic, copy) NSString *speechLocale;
@property (nonatomic, assign) double silenceTimeout;
@property (nonatomic, assign) double maxUtterance;
@property (nonatomic, assign) BOOL autoSend;
@property (nonatomic, assign) BOOL onDevicePreferred;
@property (nonatomic, assign) BOOL playCue;
@property (nonatomic, assign) BOOL continuousListening;

// Personality
@property (nonatomic, copy) NSString *personalityPreset;
@property (nonatomic, copy) NSString *addressAs;
@property (nonatomic, assign) double formality;
@property (nonatomic, assign) double warmth;
@property (nonatomic, assign) double obedience;
@property (nonatomic, assign) double eeriness;
@property (nonatomic, assign) double verbosity;
@property (nonatomic, assign) double humor;
@property (nonatomic, assign) BOOL idleChatter;
@property (nonatomic, assign) double idleInterval;
@property (nonatomic, assign) BOOL memoryEnabled;
@property (nonatomic, assign) NSInteger contextDepth;
@property (nonatomic, copy) NSString *customInstructions;
@property (nonatomic, copy) NSString *refusalStyle;

// Simulation
@property (nonatomic, copy) NSString *scenario;
@property (nonatomic, assign) double tickRate;
@property (nonatomic, assign) BOOL anomalies;
@property (nonatomic, assign) BOOL autoEvents;
@property (nonatomic, assign) BOOL allowPodBayOverride;
@property (nonatomic, assign) BOOL missionClock;
@property (nonatomic, assign) BOOL soundEffects;
@property (nonatomic, copy) NSString *alertSensitivity;
@property (nonatomic, assign) BOOL ambientHum;

// Intelligence
@property (nonatomic, copy) NSString *engine;
@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, assign) double temperature;
@property (nonatomic, assign) NSInteger maxTokens;
@property (nonatomic, assign) BOOL streamResponses;
@property (nonatomic, assign) double timeout;
@property (nonatomic, assign) BOOL fallbackToScripted;
@property (nonatomic, copy) NSString *systemPromptOverride;

// 3D viewer
@property (nonatomic, assign) BOOL viewerAutoRotate;
@property (nonatomic, copy) NSString *viewerQuality;
@property (nonatomic, assign) double viewerDeactivationSpeed;

// Advanced
@property (nonatomic, assign) BOOL verboseLogging;
@property (nonatomic, assign) NSInteger schemaVersion;

@end

NS_ASSUME_NONNULL_END
