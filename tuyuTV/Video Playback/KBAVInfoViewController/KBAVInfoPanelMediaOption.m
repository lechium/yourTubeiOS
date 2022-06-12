#import "KBAVInfoPanelMediaOption.h"
#import <MediaAccessibility/MediaAccessibility.h>

@interface KBAVInfoPanelMediaOption() {
    NSString* _displayName;
    NSString* _languageCode;
    AVMediaSelectionOption* _mediaSelectionOption;
    NSInteger _tag;
    BOOL _selected;
}

@end

@implementation KBAVInfoPanelMediaOption

- (KBSubtitleTagType)tag {
    return _tag;
}

- (void)setTag:(KBSubtitleTagType)tag {
    _tag = tag;
}

- (NSString *)description {
    NSString *og = [super description];
    return [NSString stringWithFormat:@"%@ %@ option: %@, selected: %d mediaIndex: %lu", og, _displayName, _mediaSelectionOption, _selected, _mediaIndex];
}

-(BOOL)selected {
    return _selected;
}

-(void)setIsSelected:(BOOL)selected {
    _selected = selected;
}

+(id)optionOff {
    KBAVInfoPanelMediaOption *opt = [[KBAVInfoPanelMediaOption alloc]initWithLanguageCode:nil displayName:@"Off" mediaSelectionOption:nil tag:KBSubtitleTagTypeOff];
    MACaptionAppearanceDisplayType type = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    if (type == kMACaptionAppearanceDisplayTypeForcedOnly) {
        [opt setIsSelected:true];
    }
    return opt;
}

+(id)optionAuto {
    KBAVInfoPanelMediaOption *opt = [[KBAVInfoPanelMediaOption alloc]initWithLanguageCode:nil displayName:@"Auto" mediaSelectionOption:nil tag:KBSubtitleTagTypeAuto];
    MACaptionAppearanceDisplayType type = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    if (type == kMACaptionAppearanceDisplayTypeAutomatic) {
        [opt setIsSelected:true];
    }
    return opt;
}

- (void)setDisplayName:(NSString *)displayName {
    _displayName = displayName;
}

- (NSString *)displayName {
    return _displayName;
}

- (NSString *)languageCode {
    return _languageCode;
}

- (AVMediaSelectionOption *)mediaSelectionOption {
    return _mediaSelectionOption;
}

- (void)setLanguageCode:(NSString *)languageCode {
    _languageCode = languageCode;
}

- (void)setMediaSelectionOption:(AVMediaSelectionOption *)mediaSelectionOption {
    _mediaSelectionOption = mediaSelectionOption;
}


-(id)initWithLanguageCode:(NSString * _Nullable)code displayName:(NSString *)displayName mediaSelectionOption:(AVMediaSelectionOption *_Nullable)option tag:(KBSubtitleTagType)tag index:(NSInteger)mediaIndex {
    self = [super init];
    if (self) {
        _displayName = displayName;
        _languageCode = code;
        _mediaIndex = mediaIndex;
        _tag = tag;
    }
    return self;
}

- (id)initWithLanguageCode:(NSString *_Nullable)code displayName:(NSString *)displayName mediaSelectionOption:(AVMediaSelectionOption * _Nullable)mediaSelectionOption tag:(KBSubtitleTagType)tag {
    self = [super init];
    if (self) {
        _displayName = displayName;
        _languageCode = code;
        _mediaSelectionOption = mediaSelectionOption;
        _tag = tag;
    }
    return self;
}

@end
