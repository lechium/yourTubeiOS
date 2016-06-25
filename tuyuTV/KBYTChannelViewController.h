//
//  KBYTChannelViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/9/16.
//
//

#import <UIKit/UIKit.h>

@interface KBYTChannelViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>
{
    BOOL _gettingPage;
}

@property (nonatomic, weak) IBOutlet UILabel *authorLabel;
@property (nonatomic, weak) IBOutlet UILabel *subscribersLabel;
@property (nonatomic, weak) IBOutlet UIImageView *bannerImage;
@property (nonatomic, strong) NSMutableArray *searchResults; // Filtered search results
@property (readwrite, assign) NSInteger totalResults; // Filtered search results
@property (readwrite, assign) NSInteger pageCount;
@property (readwrite, assign) NSInteger currentPage;
@property (nonatomic, strong) NSString *channelTitle;
@property (nonatomic, strong) NSString *subscribers;
@property (nonatomic, strong) NSString *bannerURL;
@property (nonatomic, strong) NSString *nextHREF;
@property (nonatomic, weak) UICollectionViewCell *focusedCollectionCell;
@property (nonatomic, strong) void (^alertHandler)(UIAlertAction *action);
@property (nonatomic, strong) void (^channelAlertHandler)(UIAlertAction *action);
@end
