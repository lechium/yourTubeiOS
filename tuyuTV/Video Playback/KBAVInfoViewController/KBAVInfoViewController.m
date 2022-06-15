//
//  KBAVInfoViewController.m
//  Ethereal
//
//  Created by kevinbradley on 1/9/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "KBAVInfoViewController.h"
#import "UIView+AL.h"
#import "UIStackView+Helper.h"
#import "KBSlider.h"
#import "UIImageView+WebCache.h"
#import <MediaAccessibility/MediaAccessibility.h>
#import "KBMoreButton.h"
#import "KBTextPresentationViewController.h"
#import "EXTScope.h"
#import "KBAction.h"
#import "KBSliderImages.h"
#import "KBVideoPlaybackProtocol.h"
#import "KBAVInfoPanelContentViewController.h"
#import "KBAVInfoPanelDescriptionViewController.h"
#import "KBAVMetaData.h"
#import "KBAVInfoPanelSubtitlesViewController.h"


@interface KBAVInfoViewController () <KBAVInfoPanelSubtitlesDelegate> {
    KBAVMetaData *_metadata;
    __weak AVPlayerItem *_playerItem;
    BOOL _observing;
    NSArray *_subtitleData;
    KBAVInfoStyle _infoStyle;
}
@property UIView *visibleView;
@property UIView *divider;
@property NSLayoutConstraint *heightConstraint;
@property NSLayoutConstraint *topConstraint;
@property KBAVInfoPanelDescriptionViewController *descriptionViewController;
@property KBAVInfoPanelSubtitlesViewController *subtitleViewController;
@property UIFocusGuide *tabBarBottomFocusGuide;
@end

#define TOP_PADDING 60.0
#define SIDE_PADDING 90.0

/*
 cy# [player audioTracks]
 @[@{"handler_name":"English","creation_time":"2016-06-05T06:37:30.000000Z","language":"eng"},@{"handler_name":"English","creation_time":"2016-06-05T06:37:30.000000Z","language":"eng"}]
 */

@implementation KBAVInfoViewController

/*
 `(
         {
         "BPS-eng" = 170;
         "DURATION-eng" = "00:21:34.949000000";
         "NUMBER_OF_BYTES-eng" = 27675;
         "NUMBER_OF_FRAMES-eng" = 630;
         "_STATISTICS_TAGS-eng" = "BPS DURATION NUMBER_OF_FRAMES NUMBER_OF_BYTES";
         "_STATISTICS_WRITING_APP-eng" = "mkvmerge v47.0.0 ('Black Flag') 64-bit";
         "_STATISTICS_WRITING_DATE_UTC-eng" = "2020-09-28 01:02:14";
         language = eng;
     }
 )
 */

- (void)setInfoStyle:(KBAVInfoStyle)infoStyle {
    _infoStyle = infoStyle;
}

- (KBAVInfoStyle)infoStyle {
    return _infoStyle;
}


/*

- (void)setSubtitleData:(NSArray *)subtitleData {
    //_subtitleData = subtitleData;
    __block NSMutableArray *_newArray = [NSMutableArray new];
    [subtitleData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        KBAVInfoPanelMediaOption *opt = [[KBAVInfoPanelMediaOption alloc] initWithLanguageCode:obj[@"language"] displayName:obj[@"language"] mediaSelectionOption:nil tag:KBSubtitleTagTypeOn];
        @weakify(self)
        opt.selectedBlock = ^(KBAVInfoPanelMediaOption * _Nonnull selected) {
            //self_weak_.pl
            PlayerViewController *ffAVP = (PlayerViewController *)[self_weak_ parentViewController];
            FFAVPlayerController *player = (FFAVPlayerController*)[ffAVP player];
            if ([player respondsToSelector:@selector(switchSubtitleStream:)]){
                [player setEnableBuiltinSubtitleRender:true];
                [player switchSubtitleStream:(int)idx];
            }
            
        };
        [_newArray addObject:opt];
    }];
    _subtitleData = _newArray;
    //do other stuff
}

- (NSArray *)subtitleData {
    return _subtitleData;
}
*/
- (NSArray *)preferredFocusEnvironments {
    if (self.tempTabBar){
        if (self.descriptionViewController.summaryView.canFocus){
            //DLog(@"allowing desc label to focus");
            return @[self.tempTabBar, self.descriptionViewController.summaryView];
        }
        return @[self.tempTabBar];
    } else if (self.infoButton) {
        if (self.descriptionViewController.summaryView.canFocus){
            //DLog(@"allowing desc label to focus");
            return @[self.infoButton, self.descriptionViewController.summaryView];
        }
        return @[self.infoButton];
    }
    return nil;
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (playerItem != _playerItem) {
        if (_observing){
            [self removeObserver];
        }
    }
    _playerItem = playerItem;
    if (!_observing){
        [self addObserver];
    }
    [self checkSubtitleOptions];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        if (self.playbackStatusChanged){
            self.playbackStatusChanged(status);
        }
        if (status == AVPlayerItemStatusReadyToPlay){
            [self checkSubtitleOptions];
            [self refreshMetadata];
        }
    }
}

- (void)refreshMetadata {
    _metadata.isHD = [self isHD];
    [self setMetadata:_metadata];
}

- (void)removeObserver {
    [_playerItem removeObserver:self forKeyPath:@"status"];
    _observing = false;
}

- (void)addObserver {
    [_playerItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
    _observing = true;
}

- (AVPlayerItem *)playerItem {
    return _playerItem;
}

- (void)setMetadata:(KBAVMetaData *)metadata {
    _metadata = metadata;
    _descriptionViewController.metadata = metadata;
}

+ (NSDateComponentsFormatter *)sharedTimeFormatter {
    static dispatch_once_t minOnceToken;
    static NSDateComponentsFormatter *sharedTime = nil;
    if(sharedTime == nil) {
        dispatch_once(&minOnceToken, ^{
            sharedTime = [[NSDateComponentsFormatter alloc] init];
            sharedTime.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
            sharedTime.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute;
        });
    }
    return sharedTime;
}

- (KBAVMetaData *)metadata {
    return _metadata;
}

- (void)setupLegacy {
    _visibleView = [[UIView alloc] initForAutoLayout];
    _visibleView.layer.masksToBounds = true;
    _visibleView.layer.cornerRadius = 27;
    [self.view addSubview:_visibleView];
    _heightConstraint = [_visibleView.heightAnchor constraintEqualToConstant:430];
    _heightConstraint.active = true;
    [_visibleView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:SIDE_PADDING].active = true;
    _topConstraint = [_visibleView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-510];
    _topConstraint.active = true;
    [_visibleView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-SIDE_PADDING].active = true;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.translatesAutoresizingMaskIntoConstraints = false;
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false;
    [_visibleView addSubview:blurView];
    [blurView autoPinEdgesToSuperviewEdges];
    [_visibleView addSubview:vibrancyEffectView];
    [vibrancyEffectView autoPinEdgesToSuperviewEdges];
    _tempTabBar = [[UITabBar alloc] initForAutoLayout];
    [_visibleView addSubview:_tempTabBar];
    _tempTabBar.itemSpacing = 100;
    _tempTabBar.delegate = self;
    UITabBarItem *tbi = [[UITabBarItem alloc] initWithTitle:@"Info" image:nil tag:0];
    UITabBarItem *tbt = [[UITabBarItem alloc] initWithTitle:@"Subtitles" image:nil tag:1];
    _tempTabBar.items = @[tbi, tbt];
    [_tempTabBar.widthAnchor constraintEqualToAnchor:_visibleView.widthAnchor].active = true;
    [_tempTabBar.leadingAnchor constraintEqualToAnchor:_visibleView.leadingAnchor].active = true;
    [_tempTabBar.trailingAnchor constraintEqualToAnchor:_visibleView.trailingAnchor].active = true;
    [_tempTabBar.topAnchor constraintEqualToAnchor:_visibleView.topAnchor constant:10].active = true;
    _divider = [[UIView alloc] initForAutoLayout];
    [_divider autoConstrainToSize:CGSizeMake(1640, 1)];
    [_visibleView addSubview:_divider];
    [_divider.centerXAnchor constraintEqualToAnchor:_visibleView.centerXAnchor].active = true;
    _divider.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
    [_divider.topAnchor constraintEqualToAnchor:_tempTabBar.bottomAnchor constant:30].active = true;
    self.view.alpha = 0;
    _tabBarBottomFocusGuide = [[UIFocusGuide alloc] init];
    [self.view addLayoutGuide:_tabBarBottomFocusGuide];
    [_tabBarBottomFocusGuide.topAnchor constraintEqualToAnchor:self.tempTabBar.bottomAnchor].active = true;
    [_tabBarBottomFocusGuide.heightAnchor constraintEqualToConstant:40].active = true;
    [_tabBarBottomFocusGuide.leadingAnchor constraintEqualToAnchor:self.tempTabBar.leadingAnchor].active = true;
    [_tabBarBottomFocusGuide.trailingAnchor constraintEqualToAnchor:self.tempTabBar.trailingAnchor].active = true;
    //_tabBarBottomFocusGuide.preferredFocusEnvironments = @[self.toggleTypeButton];

}

- (void)setupNew {
    //self.infoButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.infoButton = [KBButton buttonWithType:KBButtonTypeText];
    self.infoButton.translatesAutoresizingMaskIntoConstraints = false;
    [self.infoButton setTitle:@"Info" forState:UIControlStateNormal];
    [self.infoButton.titleLabel setFont:[UIFont boldSystemFontOfSize:24]];
    //[self.infoButton.heightAnchor constraintEqualToConstant:62].active = true;
    [self.infoButton autoConstrainToSize:CGSizeMake(100, 62)];
    [self.view addSubview:self.infoButton];
    [self.infoButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:60].active = true;
    [self.infoButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:15].active = true;
    @weakify(self);
    self.infoButton.focusChanged = ^(BOOL focused, UIFocusHeading heading) {
        if (self_weak_.infoFocusChanged){
            self_weak_.infoFocusChanged(focused, heading);
        }
    };
    _visibleView = [[UIView alloc] initForAutoLayout];
    _visibleView.layer.masksToBounds = true;
    _visibleView.layer.cornerRadius = 27;
    [self.view addSubview:_visibleView];
    _heightConstraint = [_visibleView.heightAnchor constraintEqualToConstant:255];
    _heightConstraint.active = true;
    [_visibleView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:SIDE_PADDING+15].active = true;
    _topConstraint = [_visibleView.topAnchor constraintEqualToAnchor:self.infoButton.bottomAnchor constant:30];
    _topConstraint.active = true;
    [_visibleView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-(SIDE_PADDING+15)].active = true;
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.translatesAutoresizingMaskIntoConstraints = false;
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false;
    [_visibleView addSubview:blurView];
    [blurView autoPinEdgesToSuperviewEdges];
    [_visibleView addSubview:vibrancyEffectView];
    [vibrancyEffectView autoPinEdgesToSuperviewEdges];
    _tabBarBottomFocusGuide = [[UIFocusGuide alloc] init];
    [self.view addLayoutGuide:_tabBarBottomFocusGuide];
    [_tabBarBottomFocusGuide.topAnchor constraintEqualToAnchor:self.infoButton.bottomAnchor].active = true;
    [_tabBarBottomFocusGuide.heightAnchor constraintEqualToConstant:40].active = true;
    [_tabBarBottomFocusGuide.leadingAnchor constraintEqualToAnchor:self.infoButton.leadingAnchor].active = true;
    [_tabBarBottomFocusGuide.trailingAnchor constraintEqualToAnchor:self.infoButton.trailingAnchor].active = true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.infoStyle = KBAVInfoStyleNew;
    self.view.backgroundColor = [UIColor clearColor];
    if (self.infoStyle == KBAVInfoStyleLegacy){
        [self setupLegacy];
    } else if (self.infoStyle == KBAVInfoStyleNew) {
        [self setupNew];
    }
}

- (void)updateFocusIfNeeded {
    //LOG_SELF;
    [super updateFocusIfNeeded];
    if (self.descriptionViewController.summaryView.canFocus) {
        //DLog(@"can focus?");
        _tabBarBottomFocusGuide.preferredFocusEnvironments = @[self.descriptionViewController.summaryView];
    }
}

- (void)showView:(UIView *)view withHeight:(CGFloat)height animated:(BOOL)animated {
    if (!animated){
        view.alpha = 1.0;
        self->_heightConstraint.constant = height;
        [self.view layoutIfNeeded];
        return;
    }
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_heightConstraint.constant = height;
        view.alpha = 1.0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)changeHeight:(CGFloat)height animated:(BOOL)animated {
    if (!animated){
            self->_heightConstraint.constant = height;
            [self.view layoutIfNeeded];
        return;
    }
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_heightConstraint.constant = height;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)attachToView:(KBSlider *)theView inController:(UIViewController *)pvc {
    [self.view layoutIfNeeded];
    [pvc addChildViewController:self];
    UIView *myView = self.view;
    myView.translatesAutoresizingMaskIntoConstraints = false;
    [pvc.view addSubview:myView];
    self.view.accessibilityViewIsModal = true;
    self.view.alpha = 0;
    _visibleView.alpha = 1;
    [self didMoveToParentViewController:pvc];
    [myView.topAnchor constraintEqualToAnchor:theView.bottomAnchor constant:12].active = true;
    [_visibleView.leadingAnchor constraintEqualToAnchor:theView.leadingAnchor].active = true;
    [_visibleView.trailingAnchor constraintEqualToAnchor:theView.trailingAnchor].active = true;
    theView.attachedView = myView;
    [self addDescriptionController];
    [self.parentViewController.view setNeedsFocusUpdate];
    [self.parentViewController.view updateFocusIfNeeded];
}

- (void)showWithCompletion:(void(^_Nullable)(void))block {
    if (self.delegate) {
        [self.delegate willShowAVViewController];
    }
}

- (void)showFromViewController:(UIViewController *)pvc {
    if (self.infoStyle == KBAVInfoStyleNew) {
        return;
    }
    if (self.delegate) {
        [self.delegate willShowAVViewController];
    }
    [self.view layoutIfNeeded];
    [pvc addChildViewController:self];
    [pvc.view addSubview:self.view];
    self.view.accessibilityViewIsModal = true;
    _visibleView.alpha = 0;
    [self didMoveToParentViewController:pvc];
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_topConstraint.constant = TOP_PADDING;
        self.view.alpha = 1;
        self->_visibleView.alpha = 1;
        [self.view layoutIfNeeded];
        
    }
                     completion:^(BOOL finished) {
        [self.parentViewController.view setNeedsFocusUpdate];
        [self.parentViewController.view updateFocusIfNeeded];
        [self addDescriptionController];
        [self addSubtitleViewController];
    }];
}

- (void)closeWithCompletion:(void(^_Nullable)(void))block {
    if (self.infoStyle == KBAVInfoStyleNew) {
        return;
    }
    if (self.delegate) {
        [self.delegate willHideAVViewController];
    }
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self->_topConstraint.constant = -510;
        self->_visibleView.alpha = 0;
        self.view.alpha = 0;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        
        if (block) {
            block();
        }
    }];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];

}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    switch(item.tag) {
        case 0: //info
            //self.descriptionViewController.view.alpha = 1;
            self.subtitleViewController.view.alpha = 0;
            self.subtitleViewController.view.userInteractionEnabled = false;
            [self showView:self.descriptionViewController.view withHeight:430 animated:true];
            //[self changeHeight:430 animated:true];
            break;
        case 1: //subs
            self.descriptionViewController.view.alpha = 0;
            //self.subtitleViewController.view.alpha = 1;
            self.subtitleViewController.view.userInteractionEnabled = true;
            [self showView:self.subtitleViewController.view withHeight:200 animated:true];
            //[self changeHeight:200 animated:true];
            break;
    }
}

+ (BOOL)areSubtitlesAlwaysOn {
    MACaptionAppearanceDisplayType type = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    return type == kMACaptionAppearanceDisplayTypeAlwaysOn;
}


- (NSArray <KBAVInfoPanelMediaOption *> *)subtitleOptions {
    MACaptionAppearanceDisplayType type = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    NSMutableArray *opts = [NSMutableArray new];
    AVAsset *asset = [_playerItem asset];
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    KBAVInfoPanelMediaOption *off = [KBAVInfoPanelMediaOption optionOff];
    off.selectedBlock = ^(KBAVInfoPanelMediaOption * _Nonnull selected) {
        [selected setIsSelected:true];
        [self.playerItem selectMediaOption:nil inMediaSelectionGroup:group];
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        if ([self.delegate respondsToSelector:@selector(subtitlesChangedVisibility:)]) {
            [self.delegate subtitlesChangedVisibility:false];
        }
    };
    KBAVInfoPanelMediaOption *autoOpt = [KBAVInfoPanelMediaOption optionAuto];
    autoOpt.selectedBlock = ^(KBAVInfoPanelMediaOption * _Nonnull selected) {
        [selected setIsSelected:true];
        [self.playerItem selectMediaOptionAutomaticallyInMediaSelectionGroup:group];
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
        if ([self.delegate respondsToSelector:@selector(subtitlesChangedVisibility:)]) {
            [self.delegate subtitlesChangedVisibility:false];
        }
    };
    [opts addObject:off];
    [opts addObject:autoOpt];
    if (group) {
        
        AVMediaSelectionOption *opt = [group defaultOption];
        //DLog(@"opt extendedLanguageTag: %@", [opt extendedLanguageTag]);
        //DLog(@"opt displayName: %@", [opt displayName]);
        
        KBAVInfoPanelMediaOption *sub = [[KBAVInfoPanelMediaOption alloc] initWithLanguageCode:[opt extendedLanguageTag] displayName:[opt displayName] mediaSelectionOption:opt tag:2]; //TODO: make tag smarter here
        if (type == kMACaptionAppearanceDisplayTypeAlwaysOn) {
            [sub setIsSelected:true];
        }
        sub.selectedBlock = ^(KBAVInfoPanelMediaOption * _Nonnull selected) {
            DLog(@"selected block: %@", selected);
            [selected setIsSelected:true];
            [self.playerItem selectMediaOption:selected.mediaSelectionOption inMediaSelectionGroup:group];
            MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
            if ([self.delegate respondsToSelector:@selector(subtitlesChangedVisibility:)]) {
                [self.delegate subtitlesChangedVisibility:true];
            }
        };
        
        [opts addObject:sub];
    }
    return opts;
}

- (KBMenu *)createSubtitleMenu {
    NSArray<KBAVInfoPanelMediaOption *> *vlcSubtitleData = [self subtitleOptions];
    __block NSMutableArray *menuArray = [NSMutableArray new];
    [vlcSubtitleData enumerateObjectsUsingBlock:^(KBAVInfoPanelMediaOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        KBAction *action = [KBAction actionWithTitle:obj.displayName image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
            action.state = KBMenuElementStateOn;
            if (obj.selectedBlock){
                obj.selectedBlock(obj);
            }
        }];
        action.state = KBMenuElementStateOff;
        if (obj.selected){
            action.state = KBMenuElementStateOn;
        }
        [menuArray addObject:action];
    }];
    KBMenu *menu = [KBMenu menuWithTitle:@"Subtitles" image:[KBSliderImages captionsImage] identifier:nil options:KBMenuOptionsDisplayInline | KBMenuOptionsSingleSelection children:menuArray];
    return menu;
}


- (void)addSubtitleViewController {
    if (!_subtitleViewController) {
        _subtitleViewController = [[KBAVInfoPanelSubtitlesViewController alloc] initWithItems:[self subtitleOptions]];
        [self.view layoutIfNeeded];
        [self addChildViewController:_subtitleViewController];
        UIView *subView = _subtitleViewController.view;
        subView.translatesAutoresizingMaskIntoConstraints = false;
        [_visibleView addSubview:subView];
        [subView.topAnchor constraintEqualToAnchor:_divider.bottomAnchor constant:20].active = true;
        [subView.widthAnchor constraintEqualToConstant:1320].active = true;
        [subView.bottomAnchor constraintEqualToAnchor:_visibleView.bottomAnchor constant:0].active = true;
        [subView autoCenterHorizontallyInSuperview];
        subView.userInteractionEnabled = false;
        _subtitleViewController.delegate = self;
        subView.alpha = 0;
    }
  
}

- (void)addDescriptionController {
    if (!_descriptionViewController) {
        _descriptionViewController = [KBAVInfoPanelDescriptionViewController new];
        _descriptionViewController.infoStyle = self.infoStyle;
        [_descriptionViewController setMetadata:_metadata];
        [self.view layoutIfNeeded];
        [self addChildViewController:_descriptionViewController];
        UIView *descView = _descriptionViewController.view;
        descView.translatesAutoresizingMaskIntoConstraints = false;
        [_visibleView addSubview:descView];
        if (self.infoStyle == KBAVInfoStyleLegacy) {
            [descView.topAnchor constraintEqualToAnchor:_divider.bottomAnchor constant:10].active = true;
            [descView.bottomAnchor constraintEqualToAnchor:_visibleView.bottomAnchor constant:0].active = true;
            [descView autoCenterHorizontallyInSuperview];
        } else if (self.infoStyle == KBAVInfoStyleNew) {
            [descView.topAnchor constraintEqualToAnchor:_visibleView.topAnchor constant:30].active = true;
            [descView.bottomAnchor constraintEqualToAnchor:_visibleView.bottomAnchor constant:-30].active = true;
            _descriptionViewLeadingAnchor = [descView.leadingAnchor constraintEqualToAnchor:_visibleView.leadingAnchor constant:800];
            _descriptionViewLeadingAnchor.active = true;
        }
        //[descView.widthAnchor constraintEqualToConstant:1320].active = true;
        
        //DLog(@"desc view: %@", _descriptionViewController.contentView);
        [self setNeedsFocusUpdate];
        
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //DLog(@"desc view: %@", _descriptionViewController.contentView);
}

- (BOOL)isHD {
    if (_playerItem){
        AVAsset *asset = [_playerItem asset];
        CGSize trackSize = CGSizeZero;
        AVAssetTrack *track = [[asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual] firstObject];
        if (track) {
            trackSize = track.naturalSize;
        } else {
            AVPlayerItemTrack *track = [[_playerItem tracks] firstObject]; //TODO make smarter to be certain its video
            //DLog(@"track: %@", track);
            trackSize = [[track assetTrack] naturalSize];
            //trackSize = asset.naturalSize;
        }
        //CGSize trackSize = [track naturalSize];
        //DLog(@"trackSize: %@", NSStringFromCGSize(trackSize));
        return trackSize.width >= 1280;
    }
    if (_metadata){
        return _metadata.isHD;
    }
    return false;
}

- (BOOL)hasClosedCaptions {
    AVAsset *asset = [_playerItem asset];
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    return (group);
}

- (BOOL)subtitlesOn {
    AVAsset *asset = [_playerItem asset];
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    AVMediaSelection *selection = [_playerItem currentMediaSelection];
    AVMediaSelectionOption *selected = [selection selectedMediaOptionInMediaSelectionGroup:group];
    return (selected);
    //selectedMediaOptionInMediaSelectionGroup
}

- (void)toggleSubtitles:(BOOL)on {
    if (!_playerItem) return;
    AVAsset *asset = [_playerItem asset];
    AVMediaSelectionGroup *group = [asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    if (on) {
        AVMediaSelectionOption *opt = [group defaultOption];
        [_playerItem selectMediaOption:opt inMediaSelectionGroup:group];
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
    } else {
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        [_playerItem selectMediaOption:nil inMediaSelectionGroup:group];
    }
}

- (void)checkSubtitleOptions {
    MACaptionAppearanceDisplayType type = MACaptionAppearanceGetDisplayType(kMACaptionAppearanceDomainUser);
    switch(type) {
        case kMACaptionAppearanceDisplayTypeForcedOnly:
            break;
            
        case kMACaptionAppearanceDisplayTypeAutomatic:
            break;
            
        case kMACaptionAppearanceDisplayTypeAlwaysOn:
            [self toggleSubtitles:true];
            break;
    }
}

-(void)viewController:(id)viewController didSelectSubtitleOption:(KBAVInfoPanelMediaOption *)option {
    if (option.tag == KBSubtitleTagTypeOff && option.selectedBlock == nil) {
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeForcedOnly);
        [self toggleSubtitles:false];
        [_subtitleViewController setSelectedSubtitleOptionIndex:0];
    } else if (option.tag == KBSubtitleTagTypeAuto) {
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAutomatic);
        [self toggleSubtitles:false];
        [_subtitleViewController setSelectedSubtitleOptionIndex:1];
    } else if (option.mediaSelectionOption != nil) {
        MACaptionAppearanceSetDisplayType(kMACaptionAppearanceDomainUser, kMACaptionAppearanceDisplayTypeAlwaysOn);
        [_subtitleViewController setSelectedSubtitleOptionIndex:2];
        [self toggleSubtitles:true];
    } else if (option.selectedBlock != nil) {
        option.selectedBlock(option);
    }
    [self closeWithCompletion:nil];
}


- (BOOL)shouldDismissView {
    if (self.infoStyle == KBAVInfoStyleNew) return true;
    UIFocusSystem *fs = [UIFocusSystem focusSystemForEnvironment:self];
    Class cls = NSClassFromString(@"UITabBarButton"); //FIXME: this could get flagged
    if (self.infoStyle == KBAVInfoStyleNew) {
        cls = [UIButton class];
    }
    return [[fs focusedItem] isKindOfClass:cls];
}

@end
