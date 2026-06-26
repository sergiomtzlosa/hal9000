#import <Cocoa/Cocoa.h>

@class HALConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface HALSettingsPane : NSViewController <NSTextFieldDelegate>

@property (nonatomic, strong) HALConfiguration *configuration;

- (instancetype)initWithConfiguration:(HALConfiguration *)configuration;

- (NSStackView *)scrollableStack;
- (NSTextField *)sectionTitle:(NSString *)title;
- (NSTextField *)rowLabel:(NSString *)text;
- (NSTextField *)helpText:(NSString *)text;
- (NSStackView *)rowWithLabel:(NSString *)label control:(NSView *)control;
- (NSStackView *)rowWithLabel:(NSString *)label control:(NSView *)control valueLabel:(nullable NSTextField *)valueLabel;

- (NSButton *)checkboxWithTitle:(NSString *)title key:(NSString *)key;
- (NSSlider *)sliderWithKey:(NSString *)key minimum:(double)minimum maximum:(double)maximum;
- (NSSlider *)addSliderRowWithKey:(NSString *)key label:(NSString *)label minimum:(double)minimum maximum:(double)maximum;
- (NSTextField *)textFieldWithKey:(NSString *)key placeholder:(NSString *)placeholder;
- (NSTextField *)multilineTextFieldWithKey:(NSString *)key height:(CGFloat)height;
- (NSPopUpButton *)popupWithKey:(NSString *)key options:(NSArray<NSDictionary<NSString *, NSString *> *> *)options;
- (NSColorWell *)colorWellWithKey:(NSString *)key;
- (NSButton *)buttonWithTitle:(NSString *)title action:(SEL)action;

- (NSTextField *)valueLabelForSlider:(NSSlider *)slider;
- (void)setSliderValue:(double)value forSlider:(NSSlider *)slider;

- (void)boolChanged:(NSButton *)sender;
- (void)sliderChanged:(NSSlider *)sender;
- (void)textChanged:(NSTextField *)sender;
- (void)popupChanged:(NSPopUpButton *)sender;
- (void)colorChanged:(NSColorWell *)sender;

@end

NS_ASSUME_NONNULL_END
