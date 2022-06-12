#import <UIKit/UIKit.h>

@interface KBAVInfoPanelCollectionViewTextCell : UICollectionViewCell {

    UIImageView* _checkmarkImageView;
    UILabel* _titleLabel;

}

@property (nonatomic,retain) NSString * title;
-(void)traitCollectionDidChange:(id)arg1 ;
-(void)didUpdateFocusInContext:(id)arg1 withAnimationCoordinator:(id)arg2 ;
@end
