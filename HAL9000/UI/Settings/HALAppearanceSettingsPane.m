#import "HALAppearanceSettingsPane.h"
#import "HALTheme.h"

@implementation HALAppearanceSettingsPane

- (void)loadView {
    NSStackView *stack = [self scrollableStack];
    [stack addArrangedSubview:[self sectionTitle:@"Eye & Atmosphere"]];
    [stack addArrangedSubview:[self helpText:@"The eye is the primary state indicator. Changes apply live."]];

    NSColorWell *color = [self colorWellWithKey:@"eyeColorHex"];
    [stack addArrangedSubview:[self rowWithLabel:@"Eye color" control:color]];

    [self addSliderRowWithKey:@"eyeScale" label:@"Eye scale" minimum:0.75 maximum:1.4];
    [self addSliderRowWithKey:@"glowIntensity" label:@"Glow intensity" minimum:0.0 maximum:1.0];
    [self addSliderRowWithKey:@"pulseSpeed" label:@"Pulse speed" minimum:0.4 maximum:2.0];
    [self addSliderRowWithKey:@"blinkInterval" label:@"Blink interval (s)" minimum:3.0 maximum:60.0];
    [self addSliderRowWithKey:@"windowOpacity" label:@"Window opacity" minimum:0.75 maximum:1.0];
    [self addSliderRowWithKey:@"fontScale" label:@"Text scale" minimum:0.9 maximum:1.25];

    [stack addArrangedSubview:[self checkboxWithTitle:@"Aperture blinks" key:@"blinkEnabled"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Eye follows the cursor" key:@"trackCursor"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"CRT scanlines" key:@"scanlines"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Sensor grain" key:@"grain"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Keep the window above other apps" key:@"alwaysOnTop"]];

    [stack addArrangedSubview:[self sectionTitle:@"Layout"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Show ship telemetry sidebar" key:@"showTelemetry"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Show cinema subtitles" key:@"showSubtitles"]];
    NSPopUpButton *reduceMotion = [self popupWithKey:@"reduceMotionMode" options:@[
        @{@"title": @"Follow System", @"value": @"followSystem"},
        @{@"title": @"Always reduce motion", @"value": @"on"},
        @{@"title": @"Never reduce motion", @"value": @"off"}
    ]];
    [stack addArrangedSubview:[self rowWithLabel:@"Reduce motion" control:reduceMotion]];

    [stack addArrangedSubview:[self sectionTitle:@"3D Records"]];
    [stack addArrangedSubview:[self checkboxWithTitle:@"Auto-rotate the HAL model" key:@"viewerAutoRotate"]];
    NSPopUpButton *quality = [self popupWithKey:@"viewerQuality" options:@[
        @{@"title": @"High — 4× MSAA + shadows", @"value": @"high"},
        @{@"title": @"Medium — 2× MSAA", @"value": @"medium"}
    ]];
    [stack addArrangedSubview:[self rowWithLabel:@"Render quality" control:quality]];
    [self addSliderRowWithKey:@"viewerDeactivationSpeed" label:@"Deactivation speed" minimum:0.5 maximum:2.0];
}

@end
