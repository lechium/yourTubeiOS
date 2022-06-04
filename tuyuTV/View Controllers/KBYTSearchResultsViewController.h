//
//  KBYTSearchResultsViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/7/16.
//
//

#import <UIKit/UIKit.h>

@interface KBYTSearchResultsViewController : UICollectionViewController <UISearchResultsUpdating>
{
    BOOL _gettingPage;
    NSString *_lastSearchResult;
}

@property (nonatomic, strong) NSIndexPath *selectedItem;
@property (nonatomic, strong) void (^alertHandler)(UIAlertAction *action);
@property (nonatomic, weak) UICollectionViewCell *focusedCollectionCell;
@end
