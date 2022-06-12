#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface KBAVInfoPanelContentViewController: UIViewController {
    
    BOOL _hasContent;
    UIView* _contentView;
}

@property (nonatomic,readonly) UIView * contentView;
@property (nonatomic,readonly) BOOL hasContent;
-(BOOL)hasContent;
-(UIView *)contentView;
-(void)loadView;

@end

NS_ASSUME_NONNULL_END
