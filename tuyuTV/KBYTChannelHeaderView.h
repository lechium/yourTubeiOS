//
//  KBYTChannelHeaderView.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/26/17.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBYTChannelHeaderView : UIView

@property (nonatomic, copy, nullable) void (^subToggledBlock)(void);

@property (nonatomic, strong) NSString *channelName;
@property (readwrite, assign) NSInteger subscriberCount;
@property (nonatomic, strong) NSString *bannerURL;
@property (nonatomic, strong) UIImageView *bannerImageView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *subscriberLabel;
@property (nonatomic, strong) UIButton *subButton;

- (void)setupView;
- (void)updateRounding;
@end

NS_ASSUME_NONNULL_END
