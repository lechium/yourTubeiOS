//
//  KBAVInfoViewController.h
//  Ethereal
//
//  Created by kevinbradley on 1/9/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "KBSlider.h"
#import "KBButton.h"
#import "KBAVInfoPanelMediaOption.h"
#import "KBAVMetaData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol KBAVInfoPanelMediaOptionSelectionDelegate <NSObject>
-(void)mediaOptionCollectionViewController:(id)arg1 didSelectMediaOption:(id)arg2;
@end

@protocol KBAVInfoPanelSubtitlesDelegate <NSObject>
-(void)viewController:(id)viewController didSelectSubtitleOption:(id)option;
@end


typedef NS_ENUM(NSInteger, KBAVInfoStyle) {
    KBAVInfoStyleLegacy,
    KBAVInfoStyleNew,
};

@protocol KBAVInfoViewControllerDelegate <NSObject>
@optional
- (void)willShowAVViewController;
- (void)willHideAVViewController;
@end

@interface KBAVInfoViewController : UIViewController <UITabBarDelegate>

@property UITabBar *tempTabBar;
@property KBButton *infoButton;
@property (nonatomic, weak) AVPlayerItem *playerItem;
@property (nonatomic, weak) id <KBAVInfoViewControllerDelegate> delegate;
@property (nonatomic, copy, nullable) void (^playbackStatusChanged)(AVPlayerItemStatus status);
@property (nonatomic, copy, nullable) void (^infoFocusChanged)(BOOL focused, UIFocusHeading direction);
@property (readwrite, assign) KBAVInfoStyle infoStyle;
@property (nonatomic, strong) NSArray <KBAVInfoPanelMediaOption *> *vlcSubtitleData;
@property (nonatomic, strong) NSArray <KBAVInfoPanelMediaOption *> *vlcAudioData;

@property (nonatomic, strong, nullable) NSLayoutConstraint *descriptionViewLeadingAnchor;

- (void)attachToView:(KBSlider *)theView inController:(UIViewController *)pvc;
- (void)showWithCompletion:(void(^_Nullable)(void))block;
- (BOOL)isHD;
- (BOOL)hasClosedCaptions;
/*
- (NSArray *)subtitleData;
- (void)setSubtitleData:(NSArray *)subtitleData;
 */
+ (NSDateComponentsFormatter *)sharedTimeFormatter;
- (void)showFromViewController:(UIViewController *)pvc;
- (void)closeWithCompletion:(void(^_Nullable)(void))block;
- (void)setMetadata:(KBAVMetaData *)metadata;
+ (BOOL)areSubtitlesAlwaysOn;
- (BOOL)shouldDismissView;
- (BOOL)subtitlesOn;
- (void)toggleSubtitles:(BOOL)on;
@end

NS_ASSUME_NONNULL_END
