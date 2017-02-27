//
//  KBYTGridChannelViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/26/17.
//
//

#import "TYBaseGridViewController.h"

@interface KBYTGridChannelViewController : TYBaseGridViewController

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


- (id)initWithChannelID:(NSString *)channelID;

@end
