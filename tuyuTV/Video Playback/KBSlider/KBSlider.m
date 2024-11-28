//
//  KBSlider.m
//  KBSlider
//
//  Created by Kevin Bradley on 12/25/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "KBSlider.h"
#import <GameController/GameController.h>
#import "KBSliderImages.h"
#import "UIView+AL.h"
#import "UIColor+Additions.h"
//#import "KBAVInfoViewController.h"

@interface UIPress (KBSynthetic)
// A press is synthetic if it is a tap on the Siri remote touchpad
// which is synthesized to an arrow press.
- (BOOL)kb_isSynthetic;
@end

@implementation UIPress (KBSynthetic)

- (BOOL)kb_isSynthetic
{
    /*
     * !!! Attention: We are using private API !!!
     * !!!  Might break in any future release  !!!
     *
     * For internal name changes the press might wrongly detected as non-synthetic.
     * Since we us it to filter for only non-synthetic presses arrow taps
     * on the Siri remote might be additionally be detected.
     */
    NSString *key = [@"isSyn" stringByAppendingString:@"thetic"];
    NSNumber *value = [self valueForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return NO;
}
@end

@interface UIGestureRecognizer (helper)

- (NSString *)stringForState;

@end

@implementation UIGestureRecognizer (helper)

- (NSString *)stringForState {
    switch(self.state){
        case UIGestureRecognizerStatePossible: return @"UIGestureRecognizerStatePossible";
        case UIGestureRecognizerStateBegan: return @"UIGestureRecognizerStateBegan";
        case UIGestureRecognizerStateChanged: return @"UIGestureRecognizerStateChanged";
        case UIGestureRecognizerStateEnded: return @"UIGestureRecognizerStateEnded";
        case UIGestureRecognizerStateCancelled: return @"UIGestureRecognizerStateCancelled";
        case UIGestureRecognizerStateFailed: return @"UIGestureRecognizerStateFailed";
    }
    
    return nil;
}

@end


@implementation NSThread (additions)
+ (NSArray *)stackFrameTruncatedTo:(NSInteger)offset {
    if ([[NSThread callStackSymbols] count] < offset){
        return [NSThread callStackSymbols];
    }
    return [[NSThread callStackSymbols] subarrayWithRange:NSMakeRange(0, offset)];
}
@end

@implementation KBGradientView
@dynamic layer;

+ (Class)layerClass {
    return CAGradientLayer.class;
}

+(instancetype)standardGradientView {
    KBGradientView *view = [[KBGradientView alloc] initWithFrame:CGRectMake(-100, -30, 1920+200, 620)];
    view.layer.startPoint = CGPointMake(0.5, 0);
    view.layer.endPoint = CGPointMake(0.5, 1);
    view.layer.type = kCAGradientLayerAxial;
    view.layer.colors = @[(id)[UIColor colorWithWhite:0 alpha:0].CGColor,
                          (id)[UIColor colorWithWhite:0 alpha:0.6].CGColor];
    return view;
}

@end

@interface KBSlider() {
    __weak AVPlayer *_avPlayer;
    CGFloat _minimumValue;
    CGFloat _maximumValue;
    UIColor *_maximumTrackTintColor;
    UIColor *_minimumTrackTintColor;
    UIColor *_thumbTintColor;
    CGFloat _focusScaleFactor;
    
    BOOL _isEnabled;
    BOOL _isSelected;
    BOOL _isPlaying;
    BOOL _isHighlighted;
    BOOL _defaultFadeOut;
    
    KBGradientView *gradient;
    KBSliderMode _sliderMode;
    UILabel *durationLabel;
    UILabel *currentTimeLabel;
    UILabel *scrubTimeLabel;
    NSTimeInterval _currentTime;
    NSTimeInterval _totalDuration;
    NSTimer *_fadeOutTimer;
    NSTimeInterval _touchBeganTime;
    UIImageView *_leftHintImageView;
    UIImageView *_rightHintImageView;
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    UILabel *_ffLabel;
    UILabel *_rwLabel;
    KBScrubMode _scrubMode;
    NSLayoutConstraint *_trackViewHeightConstraint;
    NSLayoutConstraint *_currentTimeLabelWidthConstraint;
    BOOL _displaysCurrentTime;
    BOOL _displaysRemainingTime;
    BOOL _hasPlayingObserver;
    NSString *_title;
    NSString *_subtitle;
    KBSeekSpeed _ffSpeed;
    KBSeekSpeed _rewindSpeed;
    KBSeekSpeed _currentSeekSpeed;
    NSArray <NSLayoutConstraint *> *leftHintConstraints;
    NSArray <NSLayoutConstraint *> *rightHintConstraints;
    NSTimeInterval _fadeOutTime;
    BOOL _isScrubbing;
    UIVisualEffectView *_blurView;
    UIVisualEffectView *_vibrancyEffectView;
    
}
@property UITapGestureRecognizer *tapGestureRecognizer;
@property UILongPressGestureRecognizer *leftLongPressGestureRecognizer;
@property CGFloat trackViewHeight;
@property CGFloat thumbSize;
@property NSTimeInterval animationDuration;
@property CGFloat defaultValue;
@property CGFloat defaultMinimumValue;
@property CGFloat defaultMaximumValue;
@property BOOL defaultIsContinuous;
@property UIColor *defaultThumbTintColor;
@property UIColor *defaultTrackColor;
@property UIColor *defaultMininumTrackTintColor;
@property CGFloat defaultFocusScaleFactor;
@property CGFloat defaultStepValue;
@property CGFloat decelerationRate;
@property CGFloat decelerationMaxVelocity;
@property CGFloat fineTunningVelocityThreshold;

@property NSMutableDictionary *thumbViewImages;
@property UIImageView *thumbView;

@property NSMutableDictionary *scrubViewImages;
@property UIImageView *scrubView;

@property NSMutableDictionary *trackViewImages;
@property UIImageView *trackView;

@property NSMutableDictionary *minimumTrackViewImages;
@property UIImageView *minimumTrackView;

@property NSMutableDictionary *maximumTrackViewImages;
@property UIImageView *maximumTrackView;

@property UIPanGestureRecognizer *panGestureRecognizer;
@property UITapGestureRecognizer *leftTapGestureRecognizer;
@property UITapGestureRecognizer *rightTapGestureRecognizer;
@property NSLayoutConstraint *thumbViewCenterXConstraint;
@property NSLayoutConstraint *scrubViewCenterXConstraint;
@property NSLayoutConstraint *currentTimeLabelCenterXConstraint;
@property DPadState dPadState; //.select

@property NSTimer *deceleratingTimer;
@property CGFloat deceleratingVelocity;
@property CGFloat thumbViewCenterXConstraintConstant;
@property CGFloat scrubViewCenterXConstraintConstant;

@end

@implementation KBSlider

- (BOOL)isScrubbing {
    return _isScrubbing;
}

- (void)setIsScrubbing:(BOOL)isScrubbing {
    _isScrubbing = isScrubbing;
    if (isScrubbing) {
        //scrubTimeLabel.alpha = 1;
        if (self.currentTimeLabelCenterXConstraint) {
            [NSLayoutConstraint deactivateConstraints:@[self.currentTimeLabelCenterXConstraint]];
            self.currentTimeLabelCenterXConstraint = nil;
        }
        self.currentTimeLabelCenterXConstraint = [currentTimeLabel.centerXAnchor constraintEqualToAnchor:self.scrubView.centerXAnchor];
        self.currentTimeLabelCenterXConstraint.active = true;
        self.scrubView.hidden = false;
        
    } else {
        //scrubTimeLabel.alpha = 0;
        if (self.currentTimeLabelCenterXConstraint) {
            [NSLayoutConstraint deactivateConstraints:@[self.currentTimeLabelCenterXConstraint]];
            self.currentTimeLabelCenterXConstraint = nil;
        }
        self.currentTimeLabelCenterXConstraint = [currentTimeLabel.centerXAnchor constraintEqualToAnchor:self.thumbView.centerXAnchor];
        self.currentTimeLabelCenterXConstraint.active = true;
        self.scrubView.hidden = true;
    }
}

- (KBSeekSpeed)currentSeekSpeed {
    return _currentSeekSpeed;
}

- (KBSeekSpeed)increaseSeekSpeed {
    switch(_currentSeekSpeed) {
        case KBSeekSpeed1x:
            [self setCurrentSeekSpeed:KBSeekSpeed2x];
            break;
        case KBSeekSpeed2x:
            [self setCurrentSeekSpeed:KBSeekSpeed3x];
            break;
        case KBSeekSpeed3x:
            [self setCurrentSeekSpeed:KBSeekSpeed4x];
            break;
        case KBSeekSpeed4x:
            [self setCurrentSeekSpeed:KBSeekSpeedNone];
            self.scrubMode = KBScrubModeNone;
            [self seekResume];
            break;
        default:
            break;
    }
    return _currentSeekSpeed;
}

- (void)setCurrentSeekSpeed:(KBSeekSpeed)seekSpeed {
    _currentSeekSpeed = seekSpeed;
    switch(self.scrubMode){
        case KBScrubModeFastForward:
            [self setFfSpeed:seekSpeed];
            _rwLabel.text = @"";
            [self setDisplaysRemainingTime:true];
            break;
            
        case KBScrubModeRewind:
            [self setRewindSpeed:seekSpeed];
            _ffLabel.text = @"";
            [self setDisplaysRemainingTime:true];
            break;
            
        default:
            break;
    }
}

- (void)delayedResetScrubMode {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setScrubMode:KBScrubModeNone];
    });
}

- (void)seekResume {
    //LOG_CMD;
    _currentSeekSpeed = KBSeekSpeedNone;
    CMTime newtime = CMTimeMakeWithSeconds(self.value, 600);
    [_avPlayer seekToTime:newtime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self setCurrentTime:self.value];
    [_avPlayer play];
}

- (KBSeekSpeed)decreaseSeekSpeed {
    switch(_currentSeekSpeed) {
        case KBSeekSpeed1x:
            [self setCurrentSeekSpeed:KBSeekSpeedNone];
            self.scrubMode = KBScrubModeNone;
            [self seekResume];
            //[self.avPlayer play];
            break;
        case KBSeekSpeed2x:
            [self setCurrentSeekSpeed:KBSeekSpeed1x];
            break;
        case KBSeekSpeed3x:
            [self setCurrentSeekSpeed:KBSeekSpeed2x];
            break;
        case KBSeekSpeed4x:
            [self setCurrentSeekSpeed:KBSeekSpeed3x];
            break;
        default:
            break;
    }
    return _currentSeekSpeed;
}

//the speeds are divided by 10 because when seeking a timer runs ever .1 seconds to update the slider value/current time.

- (CGFloat)realSpeed:(KBSeekSpeed)inputSpeed {
    switch (inputSpeed) {
        case KBSeekSpeed1x: return 8.0/10;
        case KBSeekSpeed2x: return 24.0/10;
        case KBSeekSpeed3x: return 48.0/10;
        case KBSeekSpeed4x: return 96.0/10;
        default: return 8.0/10;
    }
    return 8.0/10;
}

- (void)setRewindSpeed:(KBSeekSpeed)rewindSpeed {
    _rewindSpeed = rewindSpeed;
    _stepValue = [self realSpeed:rewindSpeed];
    if (rewindSpeed < KBSeekSpeed2x){
        _rwLabel.text = @"";
    } else {
        _rwLabel.text = [NSString stringWithFormat:@"%lu", rewindSpeed];
    }
}

- (KBSeekSpeed)rewindSpeed {
    return _rewindSpeed;
}

- (void)setFfSpeed:(KBSeekSpeed)ffSpeed {
    _ffSpeed = ffSpeed;
    _stepValue = [self realSpeed:ffSpeed];
    if (_ffSpeed < KBSeekSpeed2x){
        _ffLabel.text = @"";
    } else {
        _ffLabel.text = [NSString stringWithFormat:@"%lu", ffSpeed];
    }
}

- (KBSeekSpeed)ffSpeed {
    return _ffSpeed;
}

- (void)setSubtitle:(NSString *)subtitle {
    _subtitle = subtitle;
    _subtitleLabel.text = subtitle;
}

- (NSString *)subtitle {
    return _subtitle;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = title;
}

- (NSString *)title {
    return _title;
}

- (void)setAvPlayer:(AVPlayer *)avPlayer {
    _avPlayer = avPlayer;
    [self addPlayingObserver];
}

- (AVPlayer *)avPlayer {
    return _avPlayer;
}

- (void)setScrubMode:(KBScrubMode)scrubMode {
    _scrubMode = scrubMode;
    [self updateHintImages];
}

- (KBScrubMode)scrubMode {
    return _scrubMode;
}

- (BOOL)isPlaying {
    if (self.avPlayer) return self.avPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    return _isPlaying;
}

- (void)addPlayingObserver {
    [self.avPlayer addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"timeControlStatus"]) {
        AVPlayerTimeControlStatus changed = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        //DLog(@"timeControlStatusChanged: %lu", changed);
        if (changed == AVPlayerTimeControlStatusPlaying) {
            [self setScrubMode:KBScrubModeNone];
        }
    }
}

- (void)setIsPlaying:(BOOL)isPlaying {
    
    _isPlaying = isPlaying;
    if (self.sliderMode == KBSliderModeTransport) {
        self.scrubView.hidden = isPlaying;
        scrubTimeLabel.hidden = isPlaying && !self.isScrubbing;
        if (isPlaying){
            [self setScrubMode:KBScrubModeNone];
        }
    }
}

- (void)initializeDefaults {
    _hasPlayingObserver = false;
    _defaultFadeOut = false;
    _fadeOutTransport = _defaultFadeOut;
    _scrubMode = KBScrubModeNone;
    _trackViewHeight = 5;
    _thumbSize = 30;
    _animationDuration = 0.3;
    _defaultValue = 0;
    _defaultMinimumValue = 0;
    _defaultMaximumValue = 1;
    _defaultIsContinuous = true;
    _defaultThumbTintColor = [UIColor whiteColor];
    _defaultTrackColor = [UIColor grayColor];
    //_defaultMininumTrackTintColor = [UIColor colorFromHex:@"0000FF" alpha:0.5];
    _defaultMininumTrackTintColor = [[UIColor blueColor] copyWithAlpha:0.5];
    _defaultFocusScaleFactor = 1.05;
    _defaultStepValue = 0.1;
    _decelerationRate = 0.92;
    _decelerationMaxVelocity = 1000;
    _fineTunningVelocityThreshold = 600;
    _storedScrubberValue = _defaultValue;
    _storedValue = _defaultValue;
    _dPadState = DPadStateSelect;
    _isContinuous = _defaultIsContinuous;
    _displaysRemainingTime = true;
    _minimumTrackViewImages = [NSMutableDictionary new];
    _maximumTrackViewImages = [NSMutableDictionary new];
    _trackViewImages = [NSMutableDictionary new];
    _thumbViewImages = [NSMutableDictionary new];
    
    _thumbTintColor = _defaultThumbTintColor;
    _minimumTrackTintColor = _defaultMininumTrackTintColor;
    _focusScaleFactor = _defaultFocusScaleFactor;
    _minimumValue = _defaultMinimumValue;
    _maximumValue = _defaultMaximumValue;
    _stepValue = _defaultStepValue;
    _currentSeekSpeed = KBSeekSpeedNone;
    _fadeOutTime = 3.0;
    [self setEnabled:true];
    
}

#pragma mark KBSliderModeTransport exclusives

- (void)createHintImageViews {
    if (_leftHintImageView && _rightHintImageView) {
        return;
    }
    _leftHintImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _leftHintImageView.contentMode = UIViewContentModeScaleAspectFit;
    _leftHintImageView.translatesAutoresizingMaskIntoConstraints = false;
    [self addSubview:_leftHintImageView];
    _rightHintImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _rightHintImageView.contentMode = UIViewContentModeScaleAspectFit;
    _rightHintImageView.translatesAutoresizingMaskIntoConstraints = false;
    [self addSubview:_rightHintImageView];
    [_leftHintImageView.rightAnchor constraintEqualToAnchor:currentTimeLabel.leftAnchor constant:-10].active = true;
    [_leftHintImageView.centerYAnchor constraintEqualToAnchor:currentTimeLabel.centerYAnchor].active = true;
    [_rightHintImageView.leftAnchor constraintEqualToAnchor:currentTimeLabel.rightAnchor constant:10].active = true;
    [_rightHintImageView.centerYAnchor constraintEqualToAnchor:currentTimeLabel.centerYAnchor].active = true;
    leftHintConstraints = [_leftHintImageView autoConstrainToSize:CGSizeMake(36, 40)];
    rightHintConstraints = [_rightHintImageView autoConstrainToSize:CGSizeMake(36, 40)];
    _rightHintImageView.alpha = 0;
    _leftHintImageView.alpha = 0;
    //[_leftHintImageView setImage:[KBSliderImages backwardsImage]];
    //[_rightHintImageView setImage:[KBSliderImages forwardsImage]];
}

- (void)toggleVisibleTimerLabels {
    if (self.currentSeekSpeed != KBSeekSpeedNone) return;
    if (self.trackView.alpha == 0){
        //TLog(@"fade in");
        [self fadeIn];
        self.displaysRemainingTime = true;
        return;
    }
    if (self.displaysRemainingTime) {
        [self setDisplaysCurrentTime:true];
    } else if (self.displaysCurrentTime) {
        //TLog(@"display current time");
        [self setDisplaysCurrentTime:false];
        currentTimeLabel.alpha = 0;
        durationLabel.alpha = 0;
        [self fadeOut];
        
    } else {
        self.displaysRemainingTime = true;
        //[self setDisplaysRemainingTime:true];
    }
}

- (void)updateHintImages {
    switch (self.scrubMode) {
        case KBScrubModeNone:
        case KBScrubModeJumping:
            _rightHintImageView.image = nil;
            _leftHintImageView.image = nil;
            _leftHintImageView.alpha = 0;
            _ffLabel.text = @"";
            _rightHintImageView.alpha = 0;
            _rwLabel.text = @"";
            break;
            
        case KBScrubModeRewind:
            _leftHintImageView.alpha = 1;
            _rightHintImageView.alpha = 0;
            leftHintConstraints[0].constant = 32;
            leftHintConstraints[1].constant = 32;
            _leftHintImageView.image = [KBSliderImages backwardsImage];
            [self setDisplaysRemainingTime:true];
            break;
            
        case KBScrubModeFastForward:
            _leftHintImageView.alpha = 0;
            _rightHintImageView.alpha = 1;
            rightHintConstraints[0].constant = 32;
            rightHintConstraints[1].constant = 32;
            _rightHintImageView.image = [KBSliderImages forwardsImage];
            [self setDisplaysRemainingTime:true];
            break;
            
        case KBScrubModeSkippingForwards:
            _leftHintImageView.alpha = 0;
            _rightHintImageView.alpha = 1;
            rightHintConstraints[0].constant = 36;
            rightHintConstraints[1].constant = 40;
            _rightHintImageView.image = [KBSliderImages skipForwardsImage];
            break;
            
        case KBScrubModeSkippingBackwards:
            _leftHintImageView.alpha = 1;
            _rightHintImageView.alpha = 0;
            leftHintConstraints[0].constant = 36;
            leftHintConstraints[1].constant = 40;
            _leftHintImageView.image = [KBSliderImages skipBackwardsImage];
            break;
            
    }
}

- (void)resetHideTimer {
    //LOG_CMD;
    [self _startFadeOutTimer];
}

- (void)setFadeOutTime:(NSTimeInterval)fadeOutTime {
    _fadeOutTime = fadeOutTime;
    if ([_fadeOutTimer isValid]){
        [self _startFadeOutTimer]; //restart the timer with its new interval
    }
}

- (NSTimeInterval)fadeOutTime {
    return _fadeOutTime;
}

- (void)_startFadeOutTimer {
    [self stopFadeOutTimer];
    _fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:_fadeOutTime repeats:false block:^(NSTimer * _Nonnull timer) {
        [self fadeOut];
    }];
}

- (void)stopFadeOutTimer {
    if (_fadeOutTimer){
        [_fadeOutTimer invalidate];
        _fadeOutTimer = nil;
    }
}

- (void)hideSliderOnly {
    if (self.sliderMode == KBSliderModeTransport) {
        if (self.sliderFading) {
            self.sliderFading(0, true);
        }
        NSArray *viewArray = @[self.thumbView, self.trackView, self.minimumTrackView, self.maximumTrackView, durationLabel, currentTimeLabel, gradient, _scrubView, _leftHintImageView, _rightHintImageView, _subtitleLabel, _titleLabel, _blurView, _vibrancyEffectView];
        [UIView animateWithDuration:0.3 animations:^{
            [viewArray enumerateObjectsUsingBlock:^(UIView  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.alpha = 0;
            }];
        }];
        
    }
}

//the views we need to show or hide as necessary
- (NSArray *)_viewsToAdjust {
    if (!self.thumbView){
        return nil;
    }
    if (self.sliderMode == KBSliderModeTransport){
        if (_attachedView){
            return @[self.thumbView, self.trackView, self.minimumTrackView, self.maximumTrackView, durationLabel, currentTimeLabel, gradient, _scrubView, _leftHintImageView, _rightHintImageView, _titleLabel, _subtitleLabel, _attachedView, _blurView, _vibrancyEffectView];
        }
        if (_titleLabel){
            return @[self.thumbView, self.trackView, self.minimumTrackView, self.maximumTrackView, durationLabel, currentTimeLabel, gradient, _scrubView, _leftHintImageView, _rightHintImageView, _subtitleLabel, _titleLabel, _blurView, _vibrancyEffectView];
        }
        return @[self.thumbView, self.trackView, self.minimumTrackView, self.maximumTrackView, durationLabel, currentTimeLabel, gradient, _scrubView, _leftHintImageView, _rightHintImageView, _blurView, _vibrancyEffectView];
    } else {
        return @[self.thumbView, self.trackView, self.minimumTrackView, self.maximumTrackView];
    }
}

- (BOOL)_isVisible {
    NSArray *_views = [self _viewsToAdjust];
    if (_views.count >0){
        UIView *first = [_views lastObject];
        return first.alpha == 1.0;
    }
    return false;
}

- (void)_toggleVisibleViews:(BOOL)hide {
    [[self _viewsToAdjust] enumerateObjectsUsingBlock:^(UIView  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (hide){
            obj.alpha = 0;
            if (scrubTimeLabel){
                scrubTimeLabel.alpha = 0;
            }
        } else {
            obj.alpha = 1;
        }
    }];
}

- (void)hideSliderAnimated:(BOOL)animated {
    if (!_fadeOutTransport) return;
    if (!animated){
        if (self.sliderFading) {
            self.sliderFading(0, false);
        }
        [self _toggleVisibleViews:true];
    } else {
        if (self.sliderFading) {
            self.sliderFading(0, true);
        }
        [UIView animateWithDuration:0.3 animations:^{
            [self _toggleVisibleViews:true];
        }];
    }
}

- (void)fadeOut {
    if (!_fadeOutTransport) return;
    
    if ([self isScrubbing] || self.scrubMode == KBScrubModeRewind || self.scrubMode == KBScrubModeFastForward){
        [self _startFadeOutTimer];
        return;
    }
    
    [self hideSliderAnimated:true];
}

- (void)fadeIn {
    if (!self.userInteractionEnabled) {
        return;
    }
    if (self.sliderFading){
        self.sliderFading(1, false);
    }
    [UIView animateWithDuration:0.3 animations:^{
        [self _toggleVisibleViews:false];
        [self _startFadeOutTimer];
    }];
}

- (void)_updateFormatters {
    if (self.sliderMode == KBSliderModeDefault) return;
    if (self.currentTime >= 3600){
        [KBSlider elapsedTimeFormatter].allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    } else {
        [KBSlider elapsedTimeFormatter].allowedUnits =  NSCalendarUnitMinute | NSCalendarUnitSecond;
    }
    if (fabs(self.remainingTime) >= 3600){
        [KBSlider sharedTimeFormatter].allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    } else {
        [KBSlider sharedTimeFormatter].allowedUnits =  NSCalendarUnitMinute | NSCalendarUnitSecond;
    }
}
//@"h:mm:ss a"
+ (NSDateFormatter *)currentDateFormatter {
    static dispatch_once_t minOnceToken;
    static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil) {
        dispatch_once(&minOnceToken, ^{
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.dateFormat = @"h:mm a";
        });
    }
    return dateFormatter;
}

+ (NSDateComponentsFormatter *)elapsedTimeFormatter {
    static dispatch_once_t minOnceToken;
    static NSDateComponentsFormatter *elapsedTimer = nil;
    if(elapsedTimer == nil) {
        dispatch_once(&minOnceToken, ^{
            elapsedTimer = [[NSDateComponentsFormatter alloc] init];
            elapsedTimer.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
            elapsedTimer.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
            elapsedTimer.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        });
    }
    return elapsedTimer;
}

+ (NSDateComponentsFormatter *)sharedTimeFormatter {
    static dispatch_once_t minOnceToken;
    static NSDateComponentsFormatter *sharedTime = nil;
    if(sharedTime == nil) {
        dispatch_once(&minOnceToken, ^{
            sharedTime = [[NSDateComponentsFormatter alloc] init];
            sharedTime.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
            sharedTime.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
            sharedTime.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        });
    }
    return sharedTime;
}

- (BOOL)displaysRemainingTime {
    return _displaysRemainingTime;
}

- (void)setDisplaysRemainingTime:(BOOL)displaysRemainingTime {
    _displaysRemainingTime = displaysRemainingTime;
    if (displaysRemainingTime && _displaysCurrentTime) {
        [self setDisplaysCurrentTime:false];
    }
    if (displaysRemainingTime){
        _currentTimeLabelWidthConstraint.constant = 76;
        currentTimeLabel.alpha = 1.0;
        durationLabel.alpha = 1.0;
        currentTimeLabel.text = [self elapsedTimeFormatted];
        durationLabel.text = [self remainingTimeFormatted];
    }
}

- (BOOL)displaysCurrentTime {
    return _displaysCurrentTime;
}

- (void)setDisplaysCurrentTime:(BOOL)displaysCurrentTime {
    _displaysCurrentTime = displaysCurrentTime;
    if (displaysCurrentTime && _displaysRemainingTime) {
        [self setDisplaysRemainingTime:false];
    }
    if (displaysCurrentTime){
        _currentTimeLabelWidthConstraint.constant = 120;
        currentTimeLabel.alpha = 1.0;
        durationLabel.alpha = 1.0;
        currentTimeLabel.text = [self currentDateFormatted];
        durationLabel.text = [self finishDateFormatted];
    }
}


- (NSTimeInterval)remainingTime {
    return -(self.totalDuration - self.currentTime);
}

- (NSString *)finishDateFormatted {
    return [[KBSlider currentDateFormatter] stringFromDate:[[NSDate date] dateByAddingTimeInterval:fabs(self.remainingTime)]];
}

- (NSString *)currentDateFormatted {
    return [[KBSlider currentDateFormatter] stringFromDate:[NSDate date]];
}

- (NSString *)remainingTimeFormatted {
    return [[KBSlider sharedTimeFormatter] stringFromTimeInterval:self.remainingTime];
}


- (NSString *)elapsedTimeFormatted {
    return [[KBSlider elapsedTimeFormatter] stringFromTimeInterval:self.currentTime];
}

- (NSString *)scrubTimeFormatted {
    return [[KBSlider elapsedTimeFormatter] stringFromTimeInterval:self.scrubValue];
}

- (NSTimeInterval)totalDuration {
    return _totalDuration;
}

- (void)setTotalDuration:(NSTimeInterval)totalDuration {
    _totalDuration = totalDuration;
    [self setMaximumValue:totalDuration];
    [self _updateFormatters];
    if (durationLabel){
        durationLabel.text = [self remainingTimeFormatted];
    }
}

- (NSTimeInterval)currentTime {
    return _currentTime;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime {
    _currentTime = currentTime;
    [self setValue:currentTime];
    [self _updateFormatters];
    if (currentTimeLabel){
        if (self.displaysCurrentTime){
            currentTimeLabel.text = [self currentDateFormatted];
        } else {
            currentTimeLabel.text = [self elapsedTimeFormatted];
        }
    }
    if (durationLabel){
        if (self.displaysCurrentTime){
            durationLabel.text = [self finishDateFormatted];
        } else {
            durationLabel.text = [self remainingTimeFormatted];
        }
    }
    if (!self.isScrubbing) {
        self.scrubValue = currentTime;
    }
    if (CGRectIntersectsRect(durationLabel.frame, currentTimeLabel.frame)){
        durationLabel.alpha = 0.0;
    } else {
        if (_trackView.alpha == 1 && (self.displaysRemainingTime || self.displaysCurrentTime)){
            durationLabel.alpha = 1.0;
        }
    }
}

#pragma mark End KBSliderModeTransport exclusive

- (KBSliderMode)sliderMode {
    return _sliderMode;
}

- (void)setSliderMode:(KBSliderMode)sliderMode {
    _sliderMode = sliderMode;
    if (sliderMode == KBSliderModeTransport) {
        _trackViewHeight = 10;
        _focusScaleFactor = 1.00;
        [self setupTitleLabels];
    } else {
        _focusScaleFactor = 1.05;
        _trackViewHeight = 5;
    }
    [self setUpTrackView];
    [self setUpTrackViewConstraints];
    [self setUpMinimumTrackView];
    [self setUpMinimumTrackViewConstraints];
    [self setUpMaximumTrackView];
    [self setUpMaximumTrackViewConstraints];
    [self setUpThumbView];
    [self setUpThumbViewConstraints];
    [self updateStateDependantViews];
    [self setUpMinimumTrackViewConstraints];
    if (sliderMode == KBSliderModeDefault){
        [self fadeInIfNecessary];
        [self stopFadeOutTimer];
        self.stepValue = _defaultStepValue;
    } else {
        [self hideSliderAnimated:false];
        self.stepValue = [self realSpeed:KBSeekSpeed1x];
    }
}

- (void)setSelected:(BOOL)selected {
    _isSelected = selected;
    [self updateStateDependantViews];
}

- (BOOL)isSelected {
    return _isSelected;
}

- (void)setHighlighted:(BOOL)highlighted {
    _isHighlighted = highlighted;
    [self updateStateDependantViews];
}

- (BOOL)isHighlighted {
    return _isHighlighted;
}

- (void)setEnabled:(BOOL)enabled {
    _isEnabled = enabled;
    _panGestureRecognizer.enabled = enabled;
    [self updateStateDependantViews];
}

- (BOOL)isEnabled {
    return _isEnabled;
}

- (CGFloat)scrubValue {
    return _storedScrubberValue;
}

- (void)setScrubValue:(CGFloat)newValue {
    _storedScrubberValue = MIN(_maximumValue, newValue);
    _storedScrubberValue = MAX(_minimumValue, _storedScrubberValue);
    CGFloat offset = _trackView.bounds.size.width * (_storedScrubberValue - _minimumValue) / (_maximumValue - _minimumValue);
    offset = MIN(_trackView.bounds.size.width, offset);
    if(isnan(offset)){
        return;
    }
    _scrubViewCenterXConstraint.constant = offset;
    //scrubTimeLabel.text = [self scrubTimeFormatted];
    if ([self isScrubbing]){
        currentTimeLabel.text = [self scrubTimeFormatted];
    }
}

- (CGFloat)value {
    return _storedValue;
}

- (void)connectSiriGCControllerIfNecessary {
    GCController *first = [[GCController controllers] firstObject];
    if (first) {
        GCMicroGamepad *micro = [first microGamepad];
        if (micro) {
            [[NSNotificationCenter defaultCenter] postNotificationName:GCControllerDidConnectNotification object:first];
        }
    }
}

- (void)setValue:(CGFloat)newValue {
    _storedValue = MIN(_maximumValue, newValue);
    _storedValue = MAX(_minimumValue, _storedValue);
    CGFloat offset = _trackView.bounds.size.width * (_storedValue - _minimumValue) / (_maximumValue - _minimumValue);
    offset = MIN(_trackView.bounds.size.width, offset);
    if(isnan(offset)){
        return;
    }
    //NSLog(@"[KBSlider] attempting to set offset value: %f", offset);
    _thumbViewCenterXConstraint.constant = offset;
    if (self.sliderMode == KBSliderModeTransport) {
        _storedScrubberValue = _storedValue;
        _scrubViewCenterXConstraint.constant = offset;
    }
}

- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    [super pressesEnded:presses withEvent:event];
    for (UIPress *item in presses) {
        //KBSLog(@"pressedEnded type: %ld", item.type);
        if (item.type == UIPressTypeSelect){
        }
        
    }
}

- (CGFloat)maximumValue {
    return _maximumValue;
}

- (void)setMaximumValue:(CGFloat)maximumValue {
    _maximumValue = maximumValue;
    [self setValue:MIN(self.value, maximumValue)];
}

- (CGFloat)minimumValue {
    return _minimumValue;
}

- (void)setMinimumValue:(CGFloat)minimumValue {
    _minimumValue = minimumValue;
    [self setValue:MAX(self.value, minimumValue)];
}

- (UIColor *)maximumTrackTintColor {
    return _maximumTrackTintColor;
}

- (void)setMaximumTrackTintColor:(UIColor *)maximumTrackTintColor {
    _maximumTrackTintColor = maximumTrackTintColor;
    _maximumTrackView.backgroundColor = maximumTrackTintColor;
}

- (void)setMinimumTrackTintColor:(UIColor *)minimumTrackTintColor {
    _minimumTrackTintColor = minimumTrackTintColor;
    _minimumTrackView.backgroundColor = minimumTrackTintColor;
}

- (UIColor *)thumbTintColor {
    return _thumbTintColor;
}

- (void)setThumbTintColor:(UIColor *)thumbTintColor {
    _thumbTintColor = thumbTintColor;
    _thumbView.backgroundColor = thumbTintColor;
}

- (UIColor *)minimumTrackTintColor {
    return _minimumTrackTintColor;
}

- (CGFloat)focusScaleFactor {
    return _focusScaleFactor;
}

- (void)setFocusScaleFactor:(CGFloat)focusScaleFactor {
    _focusScaleFactor = focusScaleFactor;
    [self updateStateDependantViews];
}

- (void)setupView {
    
    [self initializeDefaults];
    [self setUpTrackView];
    [self setUpMinimumTrackView];
    [self setUpMaximumTrackView];
    [self setUpThumbView];
    
    [self setUpTrackViewConstraints];
    [self setUpMinimumTrackViewConstraints];
    [self setUpMaximumTrackViewConstraints];
    [self setUpThumbViewConstraints];
    
    [self setUpGestures];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controllerConnected:) name:GCControllerDidConnectNotification object:nil];
    [self updateStateDependantViews];
    [self connectSiriGCControllerIfNecessary];
}

- (void)setValue:(CGFloat)value animated:(BOOL)animated completion:(void(^)(void))completion {
    [self setValue:value];
    [self stopDeceleratingTimer];
    if (animated){
        [UIView animateWithDuration:self.animationDuration animations:^{
            [self setNeedsLayout];
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (completion){
                completion();
            }
        }];
    } else {
        if (completion){
            completion();
        }
    }
}

- (void)setMinimumTrackImage:(UIImage *)image forState:(UIControlState)state {
    _minimumTrackViewImages[[NSNumber numberWithUnsignedInteger:state]] = image;
    [self updateStateDependantViews];
}

- (void)setMaximumTrackImage:(UIImage *)image forState:(UIControlState)state {
    _maximumTrackViewImages[[NSNumber numberWithUnsignedInteger:state]] = image;
    [self updateStateDependantViews];
}

- (void)setThumbImage:(UIImage *)image forState:(UIControlState)state {
    _thumbViewImages[[NSNumber numberWithUnsignedInteger:state]] = image;
    [self updateStateDependantViews];
}


- (UIImage *)currentThumbImage {
    return _thumbView.image;
}

- (UIImage *)minimumTrackImageForState:(UIControlState)state {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:state];
    return _minimumTrackViewImages[key];
    
}

- (UIImage *)maximumTrackImageForState:(UIControlState)state {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:state];
    return _maximumTrackViewImages[key];
}

- (UIImage *)thumbImageForState:(UIControlState)state {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:state];
    return _thumbViewImages[key];
}

- (void)setUpThumbView {
    if (_thumbView){
        [_thumbView removeFromSuperview];
        _thumbView = nil;
    }
    _thumbView = [UIImageView new];
    _thumbView.backgroundColor = _thumbTintColor;
    [self addSubview:_thumbView];
    if (self.sliderMode != KBSliderModeTransport){ //don't want to make transport
        _thumbView.layer.cornerRadius = _thumbSize/2;
        [self removeTransportViewsIfNecessary];
    } else {
        [self setUpTransportViews];
    }
}

- (void)setUpScrubView {
    if (_scrubView){
        [_scrubView removeFromSuperview];
        _scrubView = nil;
    }
    _scrubView = [UIImageView new];
    _scrubView.backgroundColor = _thumbTintColor;
    [self addSubview:_scrubView];
    _scrubView.hidden = true; //its only visible if were currently scrubbing
}


- (void)removeTransportViewsIfNecessary {
    
    if (currentTimeLabel){
        [currentTimeLabel removeFromSuperview];
        currentTimeLabel = nil;
    }
    if (durationLabel){
        [durationLabel removeFromSuperview];
        durationLabel = nil;
    }
    if (scrubTimeLabel){
        [scrubTimeLabel removeFromSuperview];
        scrubTimeLabel = nil;
    }
    if (gradient) {
        [gradient removeFromSuperview];
        gradient = nil;
    }
}

- (void)setupTitleLabels {
    if (_titleLabel){
        [_titleLabel removeFromSuperview];
        _titleLabel = nil;
    }
    if (_subtitleLabel){
        [_subtitleLabel removeFromSuperview];
        _subtitleLabel = nil;
    }
    _titleLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:_titleLabel];
    [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
    [_titleLabel.topAnchor constraintEqualToAnchor:self.topAnchor].active = true;
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    _titleLabel.text = _title;
    
    _subtitleLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:_subtitleLabel];
    [_subtitleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
    [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.topAnchor constant:-30].active = true;
    _subtitleLabel.textColor = [UIColor whiteColor];
    _subtitleLabel.font = [UIFont systemFontOfSize:23];
    _subtitleLabel.text = _subtitle;
    
}

- (void)setupSpeedLabels {
    if (_ffLabel) {
        [_ffLabel removeFromSuperview];
        _ffLabel = nil;
    }
    if (_rwLabel) {
        [_rwLabel removeFromSuperview];
        _rwLabel = nil;
    }
    _ffLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:_ffLabel];
    [_ffLabel.leftAnchor constraintEqualToAnchor:_rightHintImageView.rightAnchor constant:5].active = true;
    [_ffLabel.centerYAnchor constraintEqualToAnchor:currentTimeLabel.centerYAnchor].active = true;
    _ffLabel.textColor = [UIColor whiteColor];
    _ffLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    _rwLabel = [[UILabel alloc] initForAutoLayout];
    [self addSubview:_rwLabel];
    [_rwLabel.rightAnchor constraintEqualToAnchor:_leftHintImageView.leftAnchor constant:-5].active = true;
    [_rwLabel.centerYAnchor constraintEqualToAnchor:currentTimeLabel.centerYAnchor].active = true;
    _rwLabel.textColor = [UIColor whiteColor];
    _rwLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    
}

- (void)setUpTransportViews {
    
    CGFloat timePadding = 10;
    
    [self removeTransportViewsIfNecessary];
    currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false;
    currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:currentTimeLabel];
    currentTimeLabel.layer.cornerRadius = 6;
    currentTimeLabel.layer.masksToBounds = true;
    currentTimeLabel.backgroundColor = [UIColor whiteColor];
    currentTimeLabel.textColor = [UIColor blackColor];
    _currentTimeLabelWidthConstraint = [currentTimeLabel.widthAnchor constraintGreaterThanOrEqualToConstant:76];
    _currentTimeLabelWidthConstraint.active = true;
    [currentTimeLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]];
    durationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    durationLabel.translatesAutoresizingMaskIntoConstraints = false;
    [durationLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]];
    [self addSubview:durationLabel];
    durationLabel.textAlignment = NSTextAlignmentCenter;
    self.currentTimeLabelCenterXConstraint = [currentTimeLabel.centerXAnchor constraintEqualToAnchor:self.thumbView.centerXAnchor];
    self.currentTimeLabelCenterXConstraint.active = true;
    [currentTimeLabel.topAnchor constraintEqualToAnchor:self.thumbView.bottomAnchor constant:timePadding].active = true;
    currentTimeLabel.text = [self elapsedTimeFormatted];
    [durationLabel.topAnchor constraintEqualToAnchor:self.thumbView.bottomAnchor constant:timePadding].active = true;
    [durationLabel.trailingAnchor constraintEqualToAnchor:self.trackView.trailingAnchor].active = true;
    durationLabel.text = [NSString stringWithFormat:@"%.0f", _totalDuration];
    scrubTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    scrubTimeLabel.translatesAutoresizingMaskIntoConstraints = false;
    scrubTimeLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:scrubTimeLabel];
    [scrubTimeLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2]];
    [self setUpScrubView];
    [self setUpScrubViewConstraints];
    [scrubTimeLabel.centerXAnchor constraintEqualToAnchor:self.scrubView.centerXAnchor].active = true;
    [scrubTimeLabel.bottomAnchor constraintEqualToAnchor:self.scrubView.topAnchor constant:timePadding].active = true;
    gradient = [KBGradientView standardGradientView];
    [self insertSubview:gradient atIndex:0];
    [self createHintImageViews];
    [self setupSpeedLabels];
}

- (void)setUpTrackView {
    if (_trackView) {
        [_trackView removeFromSuperview];
        _trackView = nil;
    }
    _trackView = [UIImageView new];
    _trackView.layer.cornerRadius = _trackViewHeight/2;
    _trackView.backgroundColor = _defaultTrackColor;
    
    if (self.sliderMode == KBSliderModeTransport){
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        _vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        [self addSubview:_blurView];
        _vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false;
        _blurView.translatesAutoresizingMaskIntoConstraints = false;
        _blurView.layer.cornerRadius = _trackViewHeight/2;
        _blurView.layer.masksToBounds = true;
        [_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = true;
        [_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
        [self addSubview:_vibrancyEffectView];
        //[vibrancyEffectView autoPinEdgesToSuperviewEdges];
        _vibrancyEffectView.layer.cornerRadius = _trackViewHeight/2;
        _vibrancyEffectView.layer.masksToBounds = true;
        [_vibrancyEffectView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = true;
        [_vibrancyEffectView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
        [_vibrancyEffectView.contentView addSubview:_trackView];
        //_trackView.backgroundColor = [UIColor colorFromHex:@"98979e" alpha:0.3];//[UIColor colorWithWhite:0.3 alpha:0.3];
        _defaultTrackColor = [[UIColor grayColor] copyWithAlpha:0.3];
        _trackView.backgroundColor = _defaultTrackColor;
    } else {
        [self addSubview:_trackView];
    }
    
}

- (void)setUpMinimumTrackView {
    if (_minimumTrackView) {
        [_minimumTrackView removeFromSuperview];
        _minimumTrackView = nil;
    }
    _minimumTrackView = [UIImageView new];
    _minimumTrackView.layer.cornerRadius = _trackViewHeight/2;
    _minimumTrackView.backgroundColor = _minimumTrackTintColor;
    [self addSubview:_minimumTrackView];
}

- (void)setUpMaximumTrackView {
    if (_maximumTrackView) {
        [_maximumTrackView removeFromSuperview];
        _maximumTrackView = nil;
    }
    _maximumTrackView = [UIImageView new];
    _maximumTrackView.layer.cornerRadius = _trackViewHeight/2;
    _maximumTrackView.backgroundColor = _maximumTrackTintColor;
    [self addSubview:_maximumTrackView];
}


- (void)setUpTrackViewConstraints {
    _trackView.translatesAutoresizingMaskIntoConstraints = false;
    [_trackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = true;
    [_trackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = true;
    if (self.sliderMode == KBSliderModeTransport){
        [_trackView.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:10].active = true;
        [_blurView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
        [_blurView.topAnchor constraintEqualToAnchor:_trackView.topAnchor].active = true;
        [_vibrancyEffectView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
        [_vibrancyEffectView.topAnchor constraintEqualToAnchor:_trackView.topAnchor].active = true;
        
    } else {
        [_trackView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor].active = true;
    }
    if (_trackViewHeightConstraint) {
        [NSLayoutConstraint deactivateConstraints:@[_trackViewHeightConstraint]];
        _trackViewHeightConstraint = nil;
    }
    _trackViewHeightConstraint = [_trackView.heightAnchor constraintEqualToConstant:_trackViewHeight];
    _trackViewHeightConstraint.active = true;
    
}

- (void)setUpMinimumTrackViewConstraints {
    _minimumTrackView.translatesAutoresizingMaskIntoConstraints = false;
    [_minimumTrackView.leadingAnchor constraintEqualToAnchor:_trackView.leadingAnchor].active = true;
    [_minimumTrackView.trailingAnchor constraintEqualToAnchor:_thumbView.centerXAnchor].active = true;
    [_minimumTrackView.centerYAnchor constraintEqualToAnchor:_trackView.centerYAnchor].active = true;
    [_minimumTrackView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
    
}

- (void)setUpMaximumTrackViewConstraints {
    _maximumTrackView.translatesAutoresizingMaskIntoConstraints = false;
    [_maximumTrackView.leadingAnchor constraintEqualToAnchor:_thumbView.centerXAnchor].active = true;
    [_maximumTrackView.trailingAnchor constraintEqualToAnchor:_trackView.trailingAnchor].active = true;
    [_maximumTrackView.centerYAnchor constraintEqualToAnchor:_trackView.centerYAnchor].active = true;
    [_maximumTrackView.heightAnchor constraintEqualToConstant:_trackViewHeight].active = true;
    
}

- (void)setUpThumbViewConstraints {
    _thumbView.translatesAutoresizingMaskIntoConstraints = false;
    [_thumbView.centerYAnchor constraintEqualToAnchor:_trackView.centerYAnchor].active = true;
    if (_sliderMode == KBSliderModeTransport){
        [_thumbView.heightAnchor constraintEqualToConstant:10].active = true;
        [_thumbView.widthAnchor constraintEqualToConstant:1].active = true;
    } else {
        [_thumbView.heightAnchor constraintEqualToConstant:_thumbSize].active = true;
        [_thumbView.widthAnchor constraintEqualToConstant:_thumbSize].active = true;
    }
    _thumbViewCenterXConstraint = [_thumbView.centerXAnchor constraintEqualToAnchor:_trackView.leadingAnchor constant:self.value];
    _thumbViewCenterXConstraint.active = true;
}

- (void)setUpScrubViewConstraints {
    _scrubView.translatesAutoresizingMaskIntoConstraints = false;
    [_scrubView.centerYAnchor constraintEqualToAnchor:_trackView.centerYAnchor].active = true;
    [_scrubView.heightAnchor constraintEqualToConstant:30].active = true;
    [_scrubView.widthAnchor constraintEqualToConstant:1].active = true;
    
    _scrubViewCenterXConstraint = [_scrubView.centerXAnchor constraintEqualToAnchor:_trackView.leadingAnchor constant:self.scrubValue];
    _scrubViewCenterXConstraint.active = true;
}

/*
 
 Dedicated fast forward and rewind buttons For remotes with dedicated fast forward and rewind buttons, a short press will initiate a continuous
 seek forward or backward. Each subsequent press of that button will increase the seek rate. Once someone passes the last seek rate, the player
 returns to its normal playback rate. If the opposite button is pressed while seeking, it decreases the seek rate; each subsequent press will do
 the same until the player returns to its normal playback rate.
 
 */

- (KBSeekSpeed)handleSeekingPressType:(UIPressType)pressType {
    TLog(@"handle Seeking Press type: %lu", pressType);
    switch (pressType) {
        case UIPressTypeLeftArrow:
            if (_currentSeekSpeed != KBSeekSpeedNone){
                if (self.scrubMode == KBScrubModeRewind) { //rewinding and left pressed, increase rewind speed
                    [self increaseSeekSpeed];
                } else if (self.scrubMode == KBScrubModeFastForward) { //ff and left pressed, decrease rewind speed
                    [self decreaseSeekSpeed];
                }
            }
            break;
        case UIPressTypeRightArrow:
            if (self.scrubMode == KBScrubModeRewind) { //rewinding and right pressed, decrase rewind speed
                [self decreaseSeekSpeed];
            } else if (self.scrubMode == KBScrubModeFastForward) { //ff and right pressed, increase seek speed
                [self increaseSeekSpeed];
            }
            break;
            
        default:
            break;
    }
    return _currentSeekSpeed;
}

- (void)setUpGestures {
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureWasTriggered:)];
    [self addGestureRecognizer:_panGestureRecognizer];
    _panGestureRecognizer.delegate = self;
    
    /*
     _leftTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(leftTapWasTriggered)];
     _leftTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeLeftArrow)];
     _leftTapGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
     [self addGestureRecognizer:_leftTapGestureRecognizer];
     
     _rightTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightTapWasTriggered)];
     _rightTapGestureRecognizer.allowedPressTypes = @[@(UIPressTypeRightArrow)];
     _rightTapGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
     [self addGestureRecognizer:_rightTapGestureRecognizer];
     */
    
    _leftLongPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longLeftPressTriggered:)];
    [self addGestureRecognizer:_leftLongPressGestureRecognizer];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureTriggered:)];
    _tapGestureRecognizer.allowedTouchTypes = @[@(UITouchTypeIndirect)];
    _tapGestureRecognizer.allowedPressTypes = @[];
    [self addGestureRecognizer:_tapGestureRecognizer];
}

- (void)longLeftPressTriggered:(UILongPressGestureRecognizer *)gestureRecognizer {
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            //DLog(@"long press began");
            if (_dPadState == DPadStateLeft){
                //DLog(@"long press left");
                if (self.scanStartedBlock){
                    self.scanStartedBlock(self.currentTime, KBSeekDirectionRewind);
                }
            } else if (_dPadState == DPadStateRight) {
                //DLog(@"long press right");
                if (self.scanStartedBlock){
                    self.scanStartedBlock(self.currentTime, KBSeekDirectionFastForward);
                }
            }
            break;
            
        case UIGestureRecognizerStateEnded:
            //DLog(@"long press ended");
            if (_dPadState == DPadStateLeft){
                //DLog(@"long press left ended");
                if (self.scanEndedBlock){
                    self.scanEndedBlock(KBSeekDirectionRewind);
                }
            } else if (_dPadState == DPadStateRight) {
                //DLog(@"long press right ended");
                if (self.scanEndedBlock){
                    self.scanEndedBlock(KBSeekDirectionFastForward);
                }
            }
            break;
            
        default:
            break;
            
    }
}

- (void)updateStateDependantViews {
    
    UIImage *currentMinImage = _minimumTrackViewImages[[NSNumber numberWithUnsignedInteger:self.state]];
    _minimumTrackView.image = currentMinImage ? currentMinImage : _minimumTrackViewImages[[NSNumber numberWithUnsignedInteger:UIControlStateNormal]];
    UIImage *currentMaxImage = _maximumTrackViewImages[[NSNumber numberWithUnsignedInteger:self.state]];
    _maximumTrackView.image = currentMaxImage ? currentMaxImage : _maximumTrackViewImages[[NSNumber numberWithUnsignedInteger:UIControlStateNormal]];
    UIImage *currentThumbImage = _thumbViewImages[[NSNumber numberWithUnsignedInteger:self.state]];
    _thumbView.image = currentThumbImage ? currentThumbImage : _thumbViewImages[[NSNumber numberWithUnsignedInteger:UIControlStateNormal]];
    
    if ([self isFocused]){
        self.transform = CGAffineTransformMakeScale(_focusScaleFactor, _focusScaleFactor);
        currentTimeLabel.textColor = [UIColor colorWithWhite:0 alpha:1.0];
        currentTimeLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        durationLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        _minimumTrackView.backgroundColor = _minimumTrackTintColor;
    } else {
        currentTimeLabel.textColor = [UIColor colorWithWhite:0 alpha:0.5];
        currentTimeLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        durationLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _minimumTrackView.backgroundColor = _defaultTrackColor;
        self.transform = CGAffineTransformIdentity;
    }
    if (self.sliderMode == KBSliderModeTransport){
        if ([self _isVisible]){
            [self _startFadeOutTimer];
        }
    }
    
}

/*
 - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer  {
 NSLog(@"%@ shouldBeRequiredToFailByGestureRecognizer: %@", gestureRecognizer, otherGestureRecognizer);
 if ([otherGestureRecognizer isKindOfClass:UISwipeGestureRecognizer.class]) {
 return TRUE;
 }
 return FALSE;
 }
 */
- (void)controllerConnected:(NSNotification *)n {
    GCController *controller = [n object];
    //NSLog(@"controller: %@ micro: %@", controller, [controller microGamepad]);
    GCMicroGamepad *micro = [controller microGamepad];
    if (!micro)return;
    
    CGFloat threshold = 0.6f;
    micro.reportsAbsoluteDpadValues = true;
    micro.dpad.valueChangedHandler = ^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        //NSLog(@"xValue: %f", xValue);
        if (xValue < -threshold){
            if (self.dPadState != DPadStateLeft) {
                NSLog(@"DPadStateLeft");
            }
            self.dPadState = DPadStateLeft;
        } else if (xValue > threshold){
            if (self.dPadState != DPadStateRight) {
                NSLog(@"DPadStateRight");
            }
            self.dPadState = DPadStateRight;
        } else {
            if (self.dPadState != DPadStateSelect) {
                NSLog(@"DPadStateSelect");
            }
            self.dPadState = DPadStateSelect;
        }
    };
}

- (void)handleDeceleratingTimer:(NSTimer *)timer {
    
    if ([self shouldMoveScrubView]) {
        CGFloat centerX = _scrubViewCenterXConstraintConstant + _deceleratingVelocity * 0.01;
        CGFloat percent = centerX / (_trackView.frame.size.width);
        CGFloat newValue = _minimumValue + ((_maximumValue - _minimumValue) * percent);
        [self setScrubValue:newValue];
        _scrubViewCenterXConstraintConstant = _scrubViewCenterXConstraint.constant;
        _deceleratingVelocity *= _decelerationRate;
        if (![self isFocused] || fabs(_deceleratingVelocity) < 1){
            [self stopDeceleratingTimer];
        }
        return;
    }
    CGFloat centerX = _thumbViewCenterXConstraintConstant + _deceleratingVelocity * 0.01;
    CGFloat percent = centerX / (_trackView.frame.size.width);
    CGFloat newValue = _minimumValue + ((_maximumValue - _minimumValue) * percent);
    [self setValue:newValue];
    if ([self isContinuous]){
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    _thumbViewCenterXConstraintConstant = _thumbViewCenterXConstraint.constant;
    
    _deceleratingVelocity *= _decelerationRate;
    if (![self isFocused] || fabs(_deceleratingVelocity) < 1){
        [self stopDeceleratingTimer];
    }
}

- (void)stopDeceleratingTimer {
    [_deceleratingTimer invalidate];
    _deceleratingTimer = nil;
    _deceleratingVelocity = 0;
    if ([self shouldMoveScrubView] || !_deceleratingTimer) {
        return;
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)isVerticalGesture:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self];
    if (fabs(translation.y) > fabs(translation.x)) {
        return true;
    }
    return false;
}

- (BOOL)shouldMoveScrubView {
    return (self.sliderMode == KBSliderModeTransport && self.isPlaying == false);
}

#pragma mark - Actions

- (void)panGestureWasTriggered:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (![self isFocused]) {
        return;
    }
    if (self.sliderMode == KBSliderModeTransport){
        if (![self _isVisible] && self.userInteractionEnabled){
            [self fadeIn];
        }
        if (self.isPlaying){
            return;
        }
        if (self.currentSeekSpeed != KBSeekSpeedNone) {
            return;
        }
    }
    if ([self isVerticalGesture:panGestureRecognizer]){
        return;
    }
    CGFloat translation = [panGestureRecognizer translationInView:self].x;
    CGFloat velocity = [panGestureRecognizer velocityInView:self].x;
    switch(panGestureRecognizer.state){
        case UIGestureRecognizerStateBegan:
            scrubTimeLabel.alpha = 1;
            [self stopDeceleratingTimer];
            self.isScrubbing = true;
            self.scrubView.hidden = false;
            if ([self shouldMoveScrubView]) {
                _scrubViewCenterXConstraintConstant = _scrubViewCenterXConstraint.constant;
            } else {
                _thumbViewCenterXConstraintConstant = _thumbViewCenterXConstraint.constant;
            }
            break;
            
        case UIGestureRecognizerStateChanged:{
            if ([self shouldMoveScrubView]) { //TODO: refactor to make this less repeat code, smarter and cleaner
                CGFloat centerX = _scrubViewCenterXConstraintConstant + translation / 5;
                CGFloat percent = centerX / _trackView.frame.size.width;
                CGFloat newValue = _minimumValue + ((_maximumValue - _minimumValue) * percent);
                [self setScrubValue:newValue];
            } else {
                CGFloat centerX = _thumbViewCenterXConstraintConstant + translation / 5;
                CGFloat percent = centerX / _trackView.frame.size.width;
                CGFloat newValue = _minimumValue + ((_maximumValue - _minimumValue) * percent);
                [self setValue:newValue];
                if ([self isContinuous]){
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }
            }
        }
            break;
            
        case UIGestureRecognizerStateEnded:
            if ([self shouldMoveScrubView]) {
                _scrubViewCenterXConstraintConstant = _scrubViewCenterXConstraint.constant;
            } else {
                _thumbViewCenterXConstraintConstant = _thumbViewCenterXConstraint.constant;
            }
            if (fabs(velocity) > _fineTunningVelocityThreshold){
                CGFloat direction = velocity > 0 ? 1 : -1;
                _deceleratingVelocity = fabs(velocity) > _decelerationMaxVelocity ? _decelerationMaxVelocity * direction : velocity;
                _deceleratingTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(handleDeceleratingTimer:) userInfo:nil repeats:true];
            } else {
                [self stopDeceleratingTimer];
            }
            break;
            
        default:
            break;
            
    }
}

//with how this recognizer is configured it ONLY gets tap events and not physical presses.
- (void)tapGestureTriggered:(UITapGestureRecognizer *)tapGestureRecognizer {
    switch (tapGestureRecognizer.state) {
        case UIGestureRecognizerStateEnded:
            [self toggleVisibleTimerLabels];
            break;
        default:
            break;
    }
}

- (void)leftTapWasTriggered {
    if ([self shouldMoveScrubView]) return;
    if (self.stepVideoBlock){
        self.stepVideoBlock(KBStepDirectionBackwards);
    }
}

- (BOOL)isVisible {
    return [self _isVisible];
}

- (void)fadeInIfNecessary {
    DLOG_CMD;
    if (![self _isVisible]){
        DLog(@"is not visible!");
        [self fadeIn];
    }
}

- (void)triggerTransportTapIfNecessary {
    [self stopDeceleratingTimer];
    if (_sliderMode == KBSliderModeTransport) {
        if (self.isScrubbing) {
            self.isScrubbing = false;
            if (self.timeSelectedBlock){
                self.timeSelectedBlock(self.scrubValue);
                self.isPlaying = true;
            }
        }
    }
}

- (void)rightTapWasTriggered {
    if ([self shouldMoveScrubView]) return;
    if (self.stepVideoBlock){
        self.stepVideoBlock(KBStepDirectionForwards);
    }
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    //DLOG_CMD;
    UIPress *firstPress = presses.allObjects.firstObject;
    if (firstPress.type == UIPressTypeMenu || firstPress.key.keyCode == UIKeyboardHIDUsageKeyboardEscape || !self.isFocused) {
        //DLog(@"discard menu events");
        [super pressesBegan:presses withEvent:event];
        return;
    }
    [self fadeInIfNecessary];
    for (UIPress *press in presses){
        switch (press.type) {
            case UIPressTypeSelect:
                if(_dPadState == DPadStateLeft){
                    _panGestureRecognizer.enabled = false;
                    [self leftTapWasTriggered];
                    return;
                } else if (_dPadState == DPadStateRight){
                    _panGestureRecognizer.enabled = false;
                    [self rightTapWasTriggered];
                    return;
                } else {
                    [self triggerTransportTapIfNecessary];
                    _panGestureRecognizer.enabled = false;
                }
                break;
            case UIPressTypePlayPause:
                [self triggerTransportTapIfNecessary];
                _panGestureRecognizer.enabled = false;
                break;
            default:
                break;
        }
    }
    _panGestureRecognizer.enabled = true;
    [super pressesBegan:presses withEvent:event];
}



- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        [self updateStateDependantViews];
    } completion:nil];
}

#pragma mark - Initializers

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    [self setupView];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setupView];
    return self;
}

- (id)init {
    self = [super init];
    [self setupView];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
