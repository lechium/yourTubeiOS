//
//  TYChannelShelfViewController.h
//  tuyuTV
//
//  Created by js on 10/2/24.
//

#import "TYBaseShelfViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TYChannelShelfViewController : TYBaseShelfViewController

@property (nonatomic, strong) UILabel *authorLabel;
@property (nonatomic, strong) UILabel *subscribersLabel;
@property (nonatomic, strong) UIImageView *bannerImage;
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *channelTitle;
@property (nonatomic, strong) NSString *subscribers;
@property (nonatomic, strong) NSString *bannerURL;
@property (nonatomic, strong) NSString *nextHREF;
@property (nonatomic, strong) NSString *channelID;
@property (nonatomic, strong) KBYTChannel *channel;

- (id)initWithChannelID:(NSString *)channelID;
- (id)initWithChannel:(KBYTChannel *)channel;
- (void)channelUpdated;
@end

NS_ASSUME_NONNULL_END
