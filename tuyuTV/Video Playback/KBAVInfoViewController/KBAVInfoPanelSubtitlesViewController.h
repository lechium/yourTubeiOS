#import "KBAVInfoPanelContentViewController.h"
#import "KBAVInfoPanelSubtitleCollectionViewController.h"

@interface KBAVInfoPanelSubtitlesViewController : KBAVInfoPanelContentViewController <UICollectionViewDelegate> {
    
    KBAVInfoPanelSubtitleCollectionViewController* _subtitleCollectionViewController;
    NSArray* _subtitleOptions;
    NSLayoutConstraint* _subtitleCollectionViewWidthConstraint; //currently unused, will be helpful to implement if we ever need to do manage audio or multiple subtitle tracks
    unsigned long long _selectedSubtitleOptionIndex;

}

@property (assign,nonatomic) id<KBAVInfoPanelSubtitlesDelegate> delegate;
@property (nonatomic, strong) NSArray *subtitleItems;
@property (assign,nonatomic) unsigned long long selectedSubtitleOptionIndex;
-(id)initWithItems:(NSArray *)subtitleItems;
@end
