//
//  YTTVPlayerViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/2/16.
//
//


#import "TYTVHistoryManager.h"
#import "YTTVPlayerViewController.h"
#import "KBSlider.h"
#import "EXTScope.h"
#import "KBAVInfoViewController.h"
#import "KBButton.h"
#import "KBSliderImages.h"
#import "KBBulletinView.h"
#import "KBAction.h"
#import "KBMenu.h"
#import "KBContextMenuRepresentation.h"
#import "KBContextMenuView.h"
#import "UIView+AL.h"

@interface YTTVPlayerViewController () <KBAVInfoViewControllerDelegate, KBContextMenuViewDelegate, KBButtonMenuDelegate> {
    NSURL *_mediaURL;
    BOOL _ffActive;
    BOOL _rwActive;
    NSTimer *_rightHoldTimer;
    NSTimer *_leftHoldTimer;
    NSTimer *_rewindTimer;
    NSTimer *_ffTimer;
    KBContextMenuView *_visibleContextView;
    NSObject *_periodicTimeToken;
    KBAVMetaData *_meta;
    NSString *_lastStarted;
    NSInteger _tempDuration;
}

@property UIActivityIndicatorView *loadingSpinner;
@property UIPress *ignorePress;
@property KBSlider *transportSlider;
@property KBButton *subtitleButton;
@property KBButton *audioButton;
@property BOOL wasPlaying; //keeps track if we were playing when scrubbing started
@property AVPlayerLayer *playerLayer;
@property KBAVInfoViewController *avInfoViewController;
@property UITapGestureRecognizer *leftTap;
@property UITapGestureRecognizer *rightTap;

@end

@implementation YTTVPlayerViewController

@synthesize mediaIsLocal, titleTimer;

- (void)menuShown:(KBContextMenuView *)menu from:(KBButton *)button {
    //TLog(@"menu: %@ show from: %@", menu, button);
    _visibleContextView = menu;
    self.audioButton.userInteractionEnabled = false;
    self.transportSlider.userInteractionEnabled = false;
    self.subtitleButton.userInteractionEnabled = false;
    [self setNeedsFocusUpdate];
    [self updateFocusIfNeeded];
}

- (void)itemSelected:(KBMenuElement *)item menu:(KBContextMenuView *)menu from:(KBButton *)button {
    //LOG_CMD;
    //TLog(@"menu item: %@", item);
}

- (NSArray *) preferredFocusEnvironments {
    if ([self contextViewVisible]){
        return @[_visibleContextView];
    }
    if ([self avInfoPanelShowing]) {
        return @[self.transportSlider];
    }
    //return @[self.transportSlider];
    return @[self.transportSlider, self.subtitleButton, self.audioButton];
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context {
    if (context.previouslyFocusedView == self.subtitleButton && context.nextFocusedView == self.transportSlider && context.focusHeading == UIFocusHeadingLeft) {
        return false;
    }
    return true;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    //TLog(@"updated focused view: %@", context.nextFocusedView);
    if ([context.nextFocusedView isKindOfClass:UICollectionViewCell.class]){
        [self.transportSlider resetHideTimer];
    }
    if ([self.subtitleButton isFocused]){
        // self.transportSlider.fadeOutTransport = false;
        [self.transportSlider setFadeOutTime:8.0];
    } else if ([self.transportSlider isFocused]) {
        [self.transportSlider setFadeOutTime:3.0];
        self.transportSlider.fadeOutTransport = true;
    }
    if ([self avInfoPanelShowing]) {
        if ([self.transportSlider isFocused]) {
            [self hideAVInfoView];
        }
    }
}


- (BOOL)contextViewVisible {
    return (_visibleContextView);
}

- (void)destroyContextView {
    _visibleContextView = nil;
    self.subtitleButton.opened = false;
    self.audioButton.opened = false;
    self.transportSlider.userInteractionEnabled = true;
    self.subtitleButton.userInteractionEnabled = true;
    self.audioButton.userInteractionEnabled = true;
}

- (void)selectedItem:(nonnull KBMenuElement *)item {
    LOG_CMD;
}


- (void)dismissContextViewIfNecessary {
    
    [_visibleContextView showContextView:false completion:^{
        [self.subtitleButton setOpened:false];
        [self.audioButton setOpened:false];
        [self destroyContextView];
    }];
    return;
    if (self.audioButton.opened) {
        [self.audioButton dismissMenuWithCompletion:^{
            [self.subtitleButton setOpened:false];
            [self.audioButton setOpened:false];
            [self destroyContextView];
        }];
    } else if (self.subtitleButton.opened) {
        [self.subtitleButton dismissMenuWithCompletion:^{
            [self.subtitleButton setOpened:false];
            [self.audioButton setOpened:false];
            [self destroyContextView];
        }];
    }
}


- (void)menuHidden:(KBContextMenuView *)menu from:(KBButton *)button {
    [self destroyContextView];
    if (button == self.subtitleButton) {
        self.subtitleButton.menu = [_avInfoViewController createSubtitleMenu];
    } else if (button == self.audioButton) {
        self.audioButton.menu = [self createPlaylistMenu];
    }
}

- (KBYTQueuePlayer *)queuePlayer {
    return (KBYTQueuePlayer *) _player;
}

- (void)selectMedia:(KBYTMedia *)media atIndex:(NSInteger)index {
    LOG_CMD;
}

- (NSArray <KBAction *> *)playlistItems {
    NSMutableArray *plItems = [NSMutableArray new];
    NSArray <YTPlayerItem *> *items = (NSArray <YTPlayerItem *>*)[[self queuePlayer] items];
    NSInteger idx = 0;
    for (YTPlayerItem *item in items) {
        KBYTMedia *media = (KBYTMedia*)[item associatedMedia];
        if (media){
            KBAction *action = [KBAction actionWithTitle:media.title image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
                [self selectMedia:media atIndex:idx];
            }];
            [plItems addObject:action];
        }
        idx++;
    }
    if (plItems.count == 0) {
        return @[];
    }
    return [plItems subarrayWithRange:NSMakeRange(0, 4)];
}

- (KBMenu *)playlistItemsMenu {
    return [KBMenu menuWithTitle:@"Items" image:nil identifier:nil options:KBMenuOptionsDisplayInline children:[self playlistItems]];
}

- (KBMenu *)createPlaylistMenu {
    LOG_CMD;
    @weakify(self);
    __block NSMutableArray *items = [NSMutableArray new];
    if ([[self queuePlayer] hasPreviousItem]){
        KBAction *previousItem = [KBAction actionWithTitle:@"Play Previous Item" image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
            [[self_weak_ queuePlayer] playPreviousItem];
        }];
        [items addObject:previousItem];
    }
    if ([[self queuePlayer] hasNextItem]) {
        KBAction *nextItem = [KBAction actionWithTitle:@"Play Next Item" image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
            [[self_weak_ queuePlayer] advanceToNextItem];
        }];
        [items addObject:nextItem];
    }
    return [KBMenu menuWithTitle:@"Playlist" image:[KBSliderImages playlistImage] identifier:nil options:KBMenuOptionsDisplayInline children:items];
}

- (KBMenu *)createAudioMenu {
    KBAction *testItemOne = [KBAction actionWithTitle:@"Full Dynamic Range" image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
        TLog(@"%@ selected", action);
    }];
    testItemOne.state = KBMenuElementStateOn;
    testItemOne.attributes = KBMenuElementAttributesDestructive;
    KBAction *testItemsThree = [KBAction actionWithTitle:@"Reduce Loud Sounds" image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
        TLog(@"%@ selected", action);
    }];
    testItemsThree.attributes = KBMenuElementAttributesToggle;
    KBAction *testItemTwo = [KBAction actionWithTitle:@"Unknown" image:nil identifier:nil handler:^(__kindof KBAction * _Nonnull action) {
        TLog(@"%@ selected", action);
        if (action.state == KBMenuElementStateOn) {
            action.state = KBMenuElementStateOff;
        } else {
            action.state = KBMenuElementStateOn;
        }
    }];
    testItemTwo.state = KBMenuElementStateOn;
    KBMenu *firstMenu = [KBMenu menuWithTitle:@"Audio Range" image:nil identifier:nil options:KBMenuOptionsDisplayInline children:@[testItemOne, testItemsThree]];
    KBMenu *secondMenu = [KBMenu menuWithTitle:@"Audio Track" image:nil identifier:nil options:KBMenuOptionsDisplayInline | KBMenuOptionsSingleSelection children:@[testItemTwo]];
    return [KBMenu menuWithTitle:@"Audio" image:[KBSliderImages audioImage] identifier:nil options:KBMenuOptionsDisplayInline | KBMenuOptionsSingleSelection children:@[firstMenu, secondMenu]];
}

- (void)menuTapped:(UITapGestureRecognizer *)gestRecognizer {
    //TLog(@"menu tapped");
    if (gestRecognizer.state == UIGestureRecognizerStateEnded){
        if ([self avInfoPanelShowing]) {
            [self hideAVInfoView];
        } else if ([self contextViewVisible]) {
            [self dismissContextViewIfNecessary];
        } else if ([self.transportSlider isScrubbing]) {
            [self.transportSlider setIsScrubbing:false];
            [self.transportSlider setCurrentTime:self.transportSlider.currentTime];
            [self.player play];
        } else {
            [self.player pause]; //actually need to 'stop' here?
            [self dismissViewControllerAnimated:true completion:nil];
        }
    }
}

- (BOOL)avInfoPanelShowing {
    if (self.avInfoViewController.infoStyle == KBAVInfoStyleNew) {
        return self.transportSlider.frame.origin.y == 550;
    }
    return self.avInfoViewController.view.alpha;
}

- (void)hideAVInfoView {
    if (!self.avInfoPanelShowing) return;
    if (_avInfoViewController.infoStyle == KBAVInfoStyleNew) {
        [self slideDownInfo];
        return;
    }
    [_avInfoViewController closeWithCompletion:^{
        self.transportSlider.userInteractionEnabled = true;
        self.transportSlider.hidden = false; //likely frivolous
    }];
}

- (void)slideDownInfo {
    [_transportSlider fadeIn];
    _transportSlider.fadeOutTransport = true;
    [self.view layoutIfNeeded];
    @weakify(self);
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self_weak_.transportSlider.frame = CGRectMake(100, 850, 1700, 105);
        [self_weak_.view layoutIfNeeded];
    } completion:nil];
}


- (void)slideUpInfo {
    _transportSlider.fadeOutTransport = false;
    [_transportSlider hideSliderOnly];
    [self.view layoutIfNeeded];
    @weakify(self);
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self_weak_.transportSlider.frame = CGRectMake(100, 550, 1700, 105);
        [self_weak_.view layoutIfNeeded];
    } completion:nil];
}

- (void)createAndSetMeta:(KBYTMedia *)item {
    KBAVMetaData *meta = [KBAVMetaData new];
    if (!item){
        item = (KBYTMedia*)[[_player currentItem] associatedMedia];
    }
    meta.title = item.author;
    meta.subtitle = item.title;
    //TLog(@"duration: %@", item.duration);
    meta.duration = [[item duration] integerValue];
    meta.summary = item.details;
    NSString *artworkPath = item.images[@"medium"];
    if (artworkPath == nil)
        artworkPath = item.images[@"standard"];
    if (artworkPath == nil)
        artworkPath = item.images[@"high"];
    meta.imageURL = [NSURL URLWithString:artworkPath];
    [self.avInfoViewController setMetadata:meta];
}

- (void)showAVInfoView {
    if (self.avInfoPanelShowing) return;
    if (!_avInfoViewController){
        _avInfoViewController = [KBAVInfoViewController new];
        [self createAndSetMeta:nil];
    }
    if (_avInfoViewController.infoStyle == KBAVInfoStyleNew) {
        [self slideUpInfo];
        return;
    }
    self.transportSlider.userInteractionEnabled = false;
    [self.transportSlider hideSliderAnimated:true];
    [_avInfoViewController showFromViewController:self];
}

- (void)togglePlayPause {
    if (_transportSlider.currentSeekSpeed != KBSeekSpeedNone) {
        [_ffTimer invalidate];
        [_rewindTimer invalidate];
        [_transportSlider seekResume];
        return;
    }
    [_transportSlider setScrubMode:KBScrubModeNone];
    switch (_player.timeControlStatus) {
        case AVPlayerTimeControlStatusPlaying:
            [_player pause];
            self.transportSlider.isPlaying = false; //shouldnt be necessary
            break;
            
        case AVPlayerTimeControlStatusPaused:
            
            [self updateProgress:_player.currentTime];
            [_player play];
            _transportSlider.isPlaying = true;
            _transportSlider.isScrubbing = false;
            break;
            
        default:
            [_player pause];
            self.transportSlider.isPlaying = false;
            break;
            
    }
}

- (void)updateProgress:(CMTime)time {
    CGFloat progress = time.value/time.timescale;
    self.transportSlider.currentTime = progress;
}

- (void)viewDidLoad {
    LOG_CMD;
    [super viewDidLoad];
    [self setupPlaybackControls];
    
}

- (KBYTMedia *)currentMediaItemIfAvailable {
    YTPlayerItem *playerItem = (YTPlayerItem*)[self.player currentItem];
    return (KBYTMedia*)[playerItem associatedMedia];
}

- (void)setupPlaybackControls {
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:_playerLayer];
    _loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _loadingSpinner.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:_loadingSpinner];
    [_loadingSpinner autoCenterInSuperview];
    [_loadingSpinner startAnimating];
    [self createSliderIfNecessary];
    [self.view addSubview:_transportSlider];
    _avInfoViewController = [KBAVInfoViewController new];
    //[self createAndSetMeta];
    _avInfoViewController.infoStyle = KBAVInfoStyleNew;
    [_avInfoViewController attachToView:_transportSlider inController:self];
    [_transportSlider setSliderMode:KBSliderModeTransport];
    [_transportSlider setCurrentTime:0];
    _transportSlider.fadeOutTransport = true;
    [_transportSlider setIsContinuous:false];
    [_transportSlider setAvPlayer:self.player];
    
    _subtitleButton = [KBButton buttonWithType:KBButtonTypeImage];
    _subtitleButton.alpha = 0;
    _subtitleButton.showsMenuAsPrimaryAction = true;
    [_subtitleButton autoConstrainToSize:CGSizeMake(68, 68)];
    [self.view addSubview:_subtitleButton];
    _subtitleButton.menu = [_avInfoViewController createSubtitleMenu];
    _subtitleButton.menuDelegate = self;
    _audioButton = [KBButton buttonWithType:KBButtonTypeImage];
    _audioButton.alpha = 0;
    _audioButton.showsMenuAsPrimaryAction = true;
    [_audioButton autoConstrainToSize:CGSizeMake(68, 68)];
    [self.view addSubview:_audioButton];
    
    //[self updateSubtitleButtonState];
    [_subtitleButton.bottomAnchor constraintEqualToAnchor:_transportSlider.topAnchor constant:60].active = true;
    //[_subtitleButton.trailingAnchor constraintEqualToAnchor:_transportSlider.trailingAnchor].active = true;
    _subtitleButton.layer.masksToBounds = true;
    _subtitleButton.layer.cornerRadius = 68/2;
    
    [_audioButton.bottomAnchor constraintEqualToAnchor:_transportSlider.topAnchor constant:60].active = true;
    [_audioButton.trailingAnchor constraintEqualToAnchor:_transportSlider.trailingAnchor].active = true;
    _audioButton.layer.masksToBounds = true;
    _audioButton.layer.cornerRadius = 68/2;
    //_audioButton.menu = [self createPlaylistMenu];
    _audioButton.menuDelegate = self;
    [_audioButton.leftAnchor constraintEqualToAnchor:_subtitleButton.rightAnchor constant:0].active = true;
    
    @weakify(self);
    _transportSlider.sliderFading = ^(CGFloat direction, BOOL animated) {
        [self_weak_ dismissContextViewIfNecessary];
        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                self_weak_.subtitleButton.alpha = direction;
                self_weak_.audioButton.alpha = direction;
                if ([self_weak_ contextViewVisible] && direction == 0){
                    //[self_weak_ testShowContextView];
                }
            } completion:^(BOOL finished) {
                if (direction == 0) {
                    if ([self_weak_.subtitleButton isFocused] || [self_weak_.audioButton isFocused]){
                        [self_weak_ setNeedsFocusUpdate];
                    }
                }
            }];
        } else {
            self_weak_.subtitleButton.alpha = direction;
            self_weak_.audioButton.alpha = direction;
        }
    };
    
    _avInfoViewController.playbackStatusChanged = ^(AVPlayerItemStatus status) {
        //TLog(@"playback status changed");
        if (status == AVPlayerItemStatusReadyToPlay) {
            [self_weak_.loadingSpinner stopAnimating];
            YTPlayerItem *playerItem = (YTPlayerItem*)[self_weak_.player currentItem];
            KBYTMedia *media = (KBYTMedia*)[playerItem associatedMedia];
            if (media){
                [self_weak_ createAndSetMeta:media];
                [self_weak_.transportSlider setTotalDuration:playerItem.durationDouble];
                self_weak_.transportSlider.title = media.author;
                self_weak_.transportSlider.subtitle = media.title;
                [self_weak_.transportSlider fadeInIfNecessary];
            }
        } else {
            [self_weak_.loadingSpinner startAnimating];
        }
    };
    
    [self addPeriodicTimeObserver];
    _avInfoViewController.playerItem = _player.currentItem;
    //[self.player observeStatus];
    
    _transportSlider.timeSelectedBlock = ^(CGFloat currentTime) {
        self_weak_.transportSlider.value = currentTime;
        [self_weak_ sliderMoved:self_weak_.transportSlider];
    };
    
    _transportSlider.scanStartedBlock = ^(CGFloat currentTime, KBSeekDirection direction) {
        if (direction == KBSeekDirectionRewind){
            [self_weak_ startRewinding];
        } else if (direction == KBSeekDirectionFastForward) {
            [self_weak_ startFastForwarding];
        }
    };
    
    _transportSlider.scanEndedBlock = ^(KBSeekDirection direction) {
        if (direction == KBSeekDirectionRewind){
            [self_weak_ stopRewinding];
        } else if (direction == KBSeekDirectionFastForward) {
            [self_weak_ stopFastForwarding];
        }
    };
    
    _transportSlider.stepVideoBlock = ^(KBStepDirection direction) {
        if (direction == KBStepDirectionForwards){
            [self_weak_ stepVideoForwards];
        } else if (direction == KBStepDirectionBackwards){
            [self_weak_ stepVideoBackwards];
        }
    };
    _avInfoViewController.infoFocusChanged = ^(BOOL focused, UIFocusHeading direction) {
        if (focused) {
            BOOL contains = (direction & UIFocusHeadingDown) != 0;
            if (contains) {
                if (![self_weak_ avInfoPanelShowing]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self_weak_ showAVInfoView];
                    });
                }
            } else {
                [self_weak_ setNeedsFocusUpdate];
            }
        }
    };
    
    UITapGestureRecognizer *menuTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuTapped:)];
    menuTap.numberOfTapsRequired = 1;
    menuTap.allowedPressTypes = @[@(UIPressTypeMenu)];
    [self.view addGestureRecognizer:menuTap];
    
    _leftTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftTapHandler:)];
    _leftTap.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    _leftTap.delegate = self;
    [self.view addGestureRecognizer:_leftTap];
    
    _rightTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightTapHandler:)];
    _rightTap.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    _rightTap.delegate = self;
    [self.view addGestureRecognizer:_rightTap];
    
    _avInfoViewController.delegate = self;
    UILongPressGestureRecognizer *longRightPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightLongPress:)];
    longRightPress.allowedPressTypes = @[@(UIPressTypeRightArrow)];
    [longRightPress requireGestureRecognizerToFail:_rightTap];
    [self.view addGestureRecognizer:longRightPress];
    
    UILongPressGestureRecognizer *longLeftPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftLongPress:)];
    longLeftPress.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
    [longLeftPress requireGestureRecognizerToFail:_leftTap];
    [self.view addGestureRecognizer:longLeftPress];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press {
    //ELog(@"shouldReceivePress: %@", gestureRecognizer);
    if (gestureRecognizer == _leftTap || gestureRecognizer == _rightTap){
        if ([press kb_isSynthetic]){
            //ELog(@"no synth for you!");
            return FALSE;
        }
    }
    return TRUE;
}

- (void)leftTapHandler:(UITapGestureRecognizer *)gestureRecognizer {
    if (!_transportSlider.isFocused) {
        return;
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (_transportSlider.currentSeekSpeed != KBSeekSpeedNone) {
            KBSeekSpeed speed = [_transportSlider handleSeekingPressType:UIPressTypeLeftArrow];
            if (speed == KBSeekSpeedNone) {
                [_rewindTimer invalidate];
                [_ffTimer invalidate];
            }
        } else {
            [self stepVideoBackwards];
        }
    }
}

- (void)rightTapHandler:(UITapGestureRecognizer *)gestureRecognizer {
    if (!_transportSlider.isFocused) {
        return;
    }
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (_transportSlider.currentSeekSpeed != KBSeekSpeedNone) {
            KBSeekSpeed speed = [_transportSlider handleSeekingPressType:UIPressTypeRightArrow];
            if (speed == KBSeekSpeedNone) {
                [_rewindTimer invalidate];
                [_ffTimer invalidate];
            }
        } else {
            [self stepVideoForwards];
        }
    }
}

- (void)handleRightLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [_ffTimer invalidate];
        [_rewindTimer invalidate];
        [self startFastForwarding];
    }
}

- (void)handleLeftLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [_ffTimer invalidate];
        [_rewindTimer invalidate];
        [self startRewinding];
    }
}


- (void)setCurrentTime:(CGFloat)currentTime {
    //_transportSlider.value = currentTime;
    //[self sliderMoved:_transportSlider];
    CMTime time = CMTimeMakeWithSeconds(currentTime, 600);
    [_player seekToTime:time];
}

- (void)removePeriodicTimeObserver {
    [_player removeTimeObserver:_periodicTimeToken];
    _periodicTimeToken = nil;
}

- (void)addPeriodicTimeObserver {
    @weakify(self);
    _periodicTimeToken = [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [self_weak_ updateProgress:time];
    }];
}

- (void)createSliderIfNecessary {
    if (!_transportSlider) {
        _transportSlider = [[KBSlider alloc] initWithFrame:CGRectMake(100, 850, 1700, 105)];
        [_transportSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    }
}

- (void)sliderMoved:(KBSlider *)slider {
    //TLog(@"sliderMoved: %.0f", slider.value);
    CMTime newTime = CMTimeMakeWithSeconds(slider.value, 600);
    [_player seekToTime:newTime];
    _transportSlider.currentTime = slider.value;
}

- (void)stepVideoBackwards {
    self.transportSlider.scrubMode = KBScrubModeSkippingBackwards;
    [self.transportSlider fadeInIfNecessary];
    NSTimeInterval newValue = self.transportSlider.value - 10;
    CMTime time = CMTimeMakeWithSeconds(newValue, 600);
    [_player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    @weakify(self);
    [self.transportSlider setValue:newValue animated:false completion:^{
        self_weak_.transportSlider.currentTime = newValue;
        [self_weak_.transportSlider delayedResetScrubMode];
    }];
    
}

- (void)stepVideoForwards {
    self.transportSlider.scrubMode = KBScrubModeSkippingForwards;
    [self.transportSlider fadeInIfNecessary];
    NSTimeInterval newValue = self.transportSlider.value + 10;
    CMTime time = CMTimeMakeWithSeconds(newValue, 600);
    [_player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    @weakify(self);
    [self.transportSlider setValue:newValue animated:false completion:^{
        self_weak_.transportSlider.currentTime = newValue;
        [self_weak_.transportSlider delayedResetScrubMode];
    }];
    
}

- (void)startFastForwarding {
    _ffActive = true;
    self.transportSlider.scrubMode = KBScrubModeFastForward;
    self.transportSlider.currentSeekSpeed = KBSeekSpeed1x;
    [self.transportSlider fadeInIfNecessary];
    [_player pause];
    @weakify(self);
    _ffTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:true block:^(NSTimer * _Nonnull timer) {
        NSTimeInterval newValue = self_weak_.transportSlider.value + self_weak_.transportSlider.stepValue;
        self_weak_.transportSlider.value = newValue;
        self_weak_.transportSlider.currentTime = newValue;
    }];
}

- (void)stopFastForwarding {
    _ffActive = false;
    [_ffTimer invalidate];
    CMTime time = CMTimeMakeWithSeconds(self.transportSlider.value, 600);
    [_player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_player play];
}

- (void)startRewinding {
    _rwActive = true;
    self.transportSlider.scrubMode = KBScrubModeRewind;
    self.transportSlider.currentSeekSpeed = KBSeekSpeed1x;
    [self.transportSlider fadeInIfNecessary];
    [_player pause];
    @weakify(self);
    _rewindTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:true block:^(NSTimer * _Nonnull timer) {
        NSTimeInterval newValue = self.transportSlider.value - self.transportSlider.stepValue;
        self_weak_.transportSlider.value = newValue;
        self_weak_.transportSlider.currentTime = newValue;
    }];
}

- (void)stopRewinding {
    _rwActive = false;
    [_rewindTimer invalidate];
    CMTime time = CMTimeMakeWithSeconds(self.transportSlider.value, 600);
    [_player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_player play];
}

- (NSURL *)mediaURL {
    return _mediaURL;
}

- (BOOL)setMediaURL:(NSURL *)mediaURL {
    _mediaURL = mediaURL;
    AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:mediaURL];
    if (![[singleItem asset] isPlayable]){
        TLog(@"this is not playable!!");
        singleItem = nil;
        return false;
    }
    self.player = [KBYTQueuePlayer playerWithPlayerItem:singleItem];
    _avInfoViewController.playerItem = singleItem;
    _transportSlider.avPlayer = _player;
    _playerLayer.player = _player;
    [self.player play];
    [self createAndSetMeta:nil];
    return true;
}

/*
 
 most of the code in this class are the stupid hurdles to jump through to not roll your own AVPlayerView &
 & controller but to maintain playback in the background & then regain video in the foreground.
 
 adapted and fixed from http://stackoverflow.com/questions/31621618/remove-and-restore-avplayer-to-enable-background-video-playback/33240738#33240738
 
 
 */

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    MPRemoteCommandCenter *shared = [MPRemoteCommandCenter sharedCommandCenter];
    [shared.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [[self player] pause];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    [shared.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [[self player] play];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
    
    
    self.titleTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(setNowPlayingInfo) userInfo:nil repeats:true];
    
    }

- (void)queuePlayerHasMultipleItems:(KBYTQueuePlayer *)player {
    LOG_SELF;
    
    MPRemoteCommandCenter *shared = [MPRemoteCommandCenter sharedCommandCenter];
    
    if ([[shared nextTrackCommand]isEnabled]) {
        // NSLog(@"already enabled, dont add new targets!");
        //   return;
        //remove them just in case before re-adding, kinda a kill shot double tap
        [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget:self];
        [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand removeTarget:self];
    }
    
    [shared.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        
        [(KBYTQueuePlayer *)[self player] advanceToNextItem];
        
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [shared.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        
        [(KBYTQueuePlayer *)[self player] playPreviousItem];
        return MPRemoteCommandHandlerStatusSuccess;
        
    }];
}

- (id)initWithFrame:(CGRect)frame usingStreamingMediaArray:(NSArray *)streamingMedia {
    self = [super init];
    mediaIsLocal = false;
    
    __block NSMutableArray *avPlayerItemArray = [NSMutableArray new];
    [streamingMedia enumerateObjectsUsingBlock:^(KBYTSearchResult  *_Nonnull result, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([result media] != nil) {
            YTPlayerItem *playerItem = [[result media] playerItemRepresentation];
            playerItem.associatedMedia = [result media];
            if (playerItem != nil) {
                [avPlayerItemArray addObject:playerItem];
                if (idx == 0){
                    self.avInfoViewController.playerItem = playerItem;
                    [self createAndSetMeta:[result media]];
                }
            }
        }
    }];
    self.player = [KBYTQueuePlayer queuePlayerWithItems:avPlayerItemArray];
    [(KBYTQueuePlayer *)self.player setDelegate:self];
    self.view.frame = frame;
    return self;
}

- (void)addObjectsToPlayerQueue:(NSArray *)objects {
    for (KBYTMedia *result in objects) {
        if ([(KBYTQueuePlayer *)self.player mediaObjectExists:result]) {
            NSLog(@"media already exists, dont add it again!");
            return;
        }
        //KBYTStream *stream = [[result streams] lastObject];
        //TLog(@"playing stream: %@", stream);
        if (objects.count == 1) { //first item, setup stuff based on this
            _tempDuration = [[result duration] integerValue];
            //TLog(@"td: %lu", _tempDuration);
            _transportSlider.totalDuration = _tempDuration;
        } else {
            self.audioButton.menu = [self createPlaylistMenu];
        }
        YTPlayerItem *playerItem = [result playerItemRepresentation];
        if (playerItem != nil) {
            [(KBYTQueuePlayer *)self.player addItemToQueue:playerItem];
        }
        
    }
}

- (id)initWithFrame:(CGRect)frame usingLocalMediaArray:(NSArray *)localMediaArray {
    self = [super init];
    mediaIsLocal = true;
    NSMutableArray *avPlayerItemArray = [NSMutableArray new];
    
    for (KBYTLocalMedia *file in localMediaArray) {
        NSString *filePath = file.filePath;
        NSURL *playURL = [NSURL fileURLWithPath:filePath];
        YTPlayerItem *playerItem = [[YTPlayerItem alloc] initWithURL:playURL];
        playerItem.associatedMedia = file;
        //NSLog(@"associatedMedia: %@", file.title);
        [avPlayerItemArray addObject:playerItem];
    }
    
    KBYTLocalMedia *file = [localMediaArray firstObject];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{ MPMediaItemPropertyTitle : file.title, MPMediaItemPropertyPlaybackDuration: file.duration };
    self.player = [KBYTQueuePlayer queuePlayerWithItems:avPlayerItemArray];
    if ([localMediaArray count] > 1) {
        [self queuePlayerHasMultipleItems:(KBYTQueuePlayer*)self.player];
    }
    [(KBYTQueuePlayer *)self.player setDelegate:self];
    [(KBYTQueuePlayer *)self.player setMultipleItemsDelegateCalled:TRUE ];
    self.view.frame = frame;
    return self;
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    //ELog(@"pressesEnded: %@", presses);
    //AVPlayerState currentState = _avplayController.playerState;
    for (UIPress *press in presses) {
        if ([press kb_isSynthetic]) {
            return;
        }
        //ELog(@"presstype: %lu", press.type);
        switch (press.type){
                
            case UIPressTypeMenu:
                break;
                
            case UIPressTypeSelect:
                if ([_transportSlider isFocused]){
                    //TLog(@"togglePlayPause");
                    [self togglePlayPause];
                }
                break;
                
            case UIPressTypePlayPause:
                
                //ELog(@"play pause");
                [self togglePlayPause];
                break;
                
            default:
                TLog(@"unhandled type: %lu", press.type);
                [super pressesEnded:presses withEvent:event];
                break;
                
        }
        
    }
}

- (void)setNowPlayingInfo {
    NSArray *playerItems = [(AVQueuePlayer *)[self player] items];
    YTPlayerItem *currentPlayerItem = [playerItems firstObject];
    double currentTime = currentPlayerItem.currentTime.value/currentPlayerItem.currentTime.timescale;
    NSObject <YTPlayerItemProtocol> *currentItem = [currentPlayerItem associatedMedia];
    //NSLog(@"currentItem: %@", currentItem);
    NSString *duration = [currentItem duration];
    NSNumber *usableDuration = nil;
    if ([duration containsString:@":"]) {
        usableDuration = [NSNumber numberWithInteger:[[currentItem duration]timeFromDuration]];
    } else {
        NSNumberFormatter *numFormatter = [NSNumberFormatter new];
        usableDuration = [numFormatter numberFromString:duration];
    }
    if (currentItem == nil) { return; }
    if (currentTime + 5 >= currentPlayerItem.durationDouble && currentPlayerItem.durationDouble > 0){
        //TLog(@"near the end: %.0f for %@", currentTime, currentItem.videoId);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:currentItem.videoId];
    } else {
        if (self.avInfoViewController.playerItem != currentPlayerItem) {
            self.avInfoViewController.playerItem = currentPlayerItem;
        }
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:currentTime] forKey:currentItem.videoId];
    }
    
}

- (void)queuePlayer:(KBYTQueuePlayer *)player didStartPlayingItem:(AVPlayerItem *)item {
    LOG_CMD;
    YTPlayerItem *playerItem = (YTPlayerItem *)item;
    KBYTMedia *theMedia = (KBYTMedia*)[playerItem associatedMedia];
    self.audioButton.menu = [self createPlaylistMenu];
    if (theMedia){
        if ([_lastStarted isEqualToString:theMedia.videoId]) {
            return;
        } else {
            _lastStarted = theMedia.videoId;
            [self.transportSlider setTotalDuration:theMedia.duration.integerValue];
            self.transportSlider.title = theMedia.author;
            self.transportSlider.subtitle = theMedia.title;
            [self createAndSetMeta:theMedia];
        }
        [[TYTVHistoryManager sharedInstance] addVideoToHistory:[theMedia dictionaryRepresentation]];
        CGFloat duration = [[[NSUserDefaults standardUserDefaults] valueForKey:theMedia.videoId] floatValue];
        TLog(@"current time offset for %@: %.0f", theMedia.videoId, duration);
        CMTime newtime = CMTimeMakeWithSeconds(duration, 600);
        [player seekToTime:newtime];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand removeTarget:self];
    [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand removeTarget:self];
    [(AVQueuePlayer *)[self player] removeAllItems];
    self.player = nil;
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
    if ([self titleTimer] != nil) {
        if ([self.titleTimer isValid]) {
            [self.titleTimer invalidate];
            self.titleTimer = nil;
        }
    }
    [self removePeriodicTimeObserver];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (BOOL)isPlaying {
    if ([self player] != nil) {
        if (self.player.rate != 0) {
            return true;
        }
    }
    return false;
    
}

- (BOOL)hasVideo {
    AVPlayerItem *playerItem = [[self player] currentItem];
    NSArray *tracks = [playerItem tracks];
    for (AVPlayerItemTrack *playerItemTrack in tracks) {
        // find video tracks
        if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual]) {
            //playerItemTrack.enabled = NO; // disable the track
            return true;
        }
    }
    return false;
}


@end
