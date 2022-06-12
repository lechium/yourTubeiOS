#import <UIKit/UIKit.h>
#import "KBAVInfoPanelMediaOption.h"
#import "KBAVInfoViewController.h"
@interface KBAVInfoPanelMediaOptionCollectionViewController: UICollectionViewController {
    NSArray *_mediaOptions;
    NSInteger _selectedMediaOptionIndex;
}
@property (nonatomic,retain) NSArray <KBAVInfoPanelMediaOption *>* mediaOptions;
@property (assign,nonatomic) long long selectedMediaOptionIndex;
@property (weak, nonatomic) id <KBAVInfoPanelMediaOptionSelectionDelegate>selectionDelegate;
@property (nonatomic, strong) NSLayoutConstraint *widthConstraint;
-(id)mediaOptionAtIndexPath:(NSIndexPath *)indexPath;

@end
