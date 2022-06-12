#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KBSubtitleTagType) {
    KBSubtitleTagTypeOff,
    KBSubtitleTagTypeAuto,
    KBSubtitleTagTypeOn,
};

@interface KBAVInfoPanelMediaOption: NSObject {
    
}
@property (nonatomic,readonly) NSString * displayName;
@property (nonatomic,readonly) NSString * languageCode;
@property (nonatomic,readonly) AVMediaSelectionOption * mediaSelectionOption;
@property (readwrite, assign) NSInteger mediaIndex; //VLC specific
@property (nonatomic,readonly) BOOL selected;
@property (nonatomic, copy, nullable) void (^selectedBlock)(KBAVInfoPanelMediaOption *selected);
@property (readonly) KBSubtitleTagType tag;
-(id)initWithLanguageCode:(NSString * _Nullable)code displayName:(NSString *)name mediaSelectionOption:(AVMediaSelectionOption *_Nullable)option tag:(KBSubtitleTagType)tag index:(NSInteger)mediaIndex;
-(id)initWithLanguageCode:(NSString * _Nullable)code displayName:(NSString *)name mediaSelectionOption:(AVMediaSelectionOption *_Nullable)option tag:(KBSubtitleTagType)tag;
-(void)setIsSelected:(BOOL)selected;
+(id)optionOff;
+(id)optionAuto;
@end

NS_ASSUME_NONNULL_END
