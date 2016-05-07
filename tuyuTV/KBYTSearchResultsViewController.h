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

@end
