//
//  KBYTChannelHeaderView.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/26/17.
//
//

#import <UIKit/UIKit.h>

@interface KBYTChannelHeaderView : UIView

@property (nonatomic, strong) NSString *channelName;
@property (readwrite, assign) NSInteger subscriberCount;
@property (nonatomic, strong) NSString *bannerURL;
@property (nonatomic, strong) UIImageView *bannerImageView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *subscriberLabel;

- (void)setupView;
- (void)updateRounding;
@end
