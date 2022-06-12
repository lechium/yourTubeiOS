//
//  KBSlider.h
//  KBSlider
//
//  Created by Kevin Bradley on 12/25/20.
//  Copyright © 2020 nito. All rights reserved.
//

//https://developer.apple.com/news/?id=33cpm46r
//UI Labels to tvOS Playback Rates 1x = 8.0 2x = 24.0 3x = 48.0 4x = 96.0

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "KBVideoPlaybackProtocol.h"

NS_ASSUME_NONNULL_BEGIN


@interface UIPress (KBSynthetic)
// A press is synthetic if it is a tap on the Siri remote touchpad
// which is synthesized to an arrow press.
- (BOOL)kb_isSynthetic;
@end


@interface NSThread (additions)
+ (NSArray *)stackFrameTruncatedTo:(NSInteger)offset;
@end

@interface KBGradientView: UIView
@property(nonatomic, readonly, strong) CAGradientLayer *layer;
+(instancetype)standardGradientView;
@end

typedef NS_ENUM(NSInteger, KBStepDirection) {
    KBStepDirectionForwards,
    KBStepDirectionBackwards,
};

typedef NS_ENUM(NSInteger, KBSeekDirection) {
    KBSeekDirectionRewind,
    KBSeekDirectionFastForward,
};

typedef NS_ENUM(NSInteger, KBSeekSpeed) {
    KBSeekSpeedNone, //go back to normal playback speed
    KBSeekSpeed1x,
    KBSeekSpeed2x,
    KBSeekSpeed3x,
    KBSeekSpeed4x,
};

typedef NS_ENUM(NSInteger, KBScrubMode) {
    KBScrubModeNone,
    KBScrubModeSkippingBackwards,
    KBScrubModeSkippingForwards,
    KBScrubModeJumping, //jumping back and forth at full intervals
    KBScrubModeRewind,
    KBScrubModeFastForward,
};

typedef NS_ENUM(NSInteger, DPadState) {
    DPadStateSelect,
    DPadStateRight,
    DPadStateLeft,
    DPadStateUp,
    DPadStateDown,
};

//KBSlider exclusives!

typedef NS_ENUM(NSInteger, KBSliderMode) {
    KBSliderModeDefault, //normal slider
    KBSliderModeTransport, //tranport mode like for movie playback control
};


@interface KBSlider : UIControl <UIGestureRecognizerDelegate>

@property CGFloat value;
@property CGFloat scrubValue;
@property CGFloat minimumValue;
@property CGFloat maximumValue;
@property BOOL isContinuous;
@property UIColor *maximumTrackTintColor;
@property UIColor *minimumTrackTintColor;
@property UIColor *thumbTintColor;
@property CGFloat focusScaleFactor;
@property CGFloat stepValue;

@property UIImage *currentMinimumTrackImage;
@property UIImage *currentMaximumTrackImage;

@property CGFloat storedValue;
@property CGFloat storedScrubberValue; //may not be necessary
@property NSTimeInterval currentTime; //only applicable in the transport mode
@property NSTimeInterval totalDuration; //only applicable in the transport mode
@property BOOL isPlaying; //transport mode only
@property BOOL isScrubbing; //transport mode only
@property NSString *title; //transport mode only
@property NSString *subtitle; //transport mode onl

@property NSTimeInterval fadeOutTime;

@property (nonatomic, copy, nullable) void (^timeSelectedBlock)(CGFloat currentTime); //transport mode only, is called when a slider value is selected when scrubbing.
@property (nonatomic, copy, nullable) void (^scanStartedBlock)(CGFloat currentTime, KBSeekDirection direction); //0 = rewind, 1 = ff
@property (nonatomic, copy, nullable) void (^scanEndedBlock)(KBSeekDirection direction);
@property (nonatomic, copy, nullable) void (^sliderFading)(CGFloat direction, BOOL animated); //0 = out, 1 = in
@property (nonatomic, copy, nullable) void (^stepVideoBlock)(KBStepDirection direction);
@property BOOL fadeOutTransport;
@property KBSliderMode sliderMode;
@property KBScrubMode scrubMode;
@property (nonatomic, weak) NSObject<KBVideoPlayerProtocol> *avPlayer; //optional
@property BOOL displaysCurrentTime;
@property BOOL displaysRemainingTime;
@property (nullable) UIView *attachedView;

@property (readwrite, assign) KBSeekSpeed currentSeekSpeed;

- (void)seekResume;
- (KBSeekSpeed)handleSeekingPressType:(UIPressType)pressType; //only matters if FF or RW
+ (NSDateComponentsFormatter *)sharedTimeFormatter;
- (NSTimeInterval)remainingTime;
- (NSString *)remainingTimeFormatted;
- (NSString *)elapsedTimeFormatted;
- (UIImage *)currentThumbImage;
- (void)setValue:(CGFloat)value animated:(BOOL)animated completion:(void(^)(void))completion;
- (void)setMinimumTrackImage:(UIImage *)minTrackImage forState:(UIControlState)state;
- (void)setMaximumTrackImage:(UIImage *)maxTrackImage forState:(UIControlState)state;
- (void)setThumbImage:(UIImage *)thumbImage forState:(UIControlState)state;
- (UIImage *)minimumTrackImageForState:(UIControlState)state;
- (UIImage *)maximumTrackImageForState:(UIControlState)state;
- (UIImage *)thumbImageForState:(UIControlState)state;
- (void)hideSliderAnimated:(BOOL)animated;
- (void)fadeIn;
- (void)hideSliderOnly;
- (void)fadeInIfNecessary;
- (void)delayedResetScrubMode;
- (void)resetHideTimer;
@end


#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
//#define LOG_SELF        DLog(@"[KBSlider] %@ %@", self, NSStringFromSelector(_cmd))
#define KBSLog(format, ...) DLog(@"[KBSlider] %@",[NSString stringWithFormat:format, ## __VA_ARGS__]);
NS_ASSUME_NONNULL_END
