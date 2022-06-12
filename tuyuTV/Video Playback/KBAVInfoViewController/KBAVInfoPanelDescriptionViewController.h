#import "KBAVInfoPanelContentViewController.h"
#import "KBAVMetaData.h"
#import "KBMoreButton.h"
#import "KBAVInfoViewController.h"
NS_ASSUME_NONNULL_BEGIN

@interface KBAVInfoPanelDescriptionViewController : KBAVInfoPanelContentViewController {
    UIStackView *_mainStackView;
    UIImageView *_posterView;
    UIStackView *_detailsStackView;
    UIFocusGuide* _posterFocusGuide;
    UILabel* _titleLabel;
    UILabel* _subtitleLabel;
    UILabel* _durationLabel;
    UILabel* _genreLabel;
    UILabel* _yearLabel;
    UIImageView* _videoResolutionBadge;
    UIImageView* _ccBadge;
    NSLayoutConstraint* _posterViewWidthConstraint;
    NSLayoutConstraint* _posterViewHeightConstraint;
    BOOL _closedCaptioned;
    KBAVMetaData* _metadata;
    NSDate* _creationDate;
    double _duration;
    
}

@property (nonatomic,copy) KBAVMetaData * metadata;
@property (nonatomic,copy) NSDate * creationDate;
@property (assign,nonatomic) double duration;
@property (assign,nonatomic) BOOL closedCaptioned;
@property (assign,nonatomic) long long videoResolution;
@property (assign,nonatomic) long long videoRange;
@property (assign,nonatomic) long long audioFormat;
@property (nonatomic,readonly) BOOL hasContent;
@property (nonatomic) KBMoreButton *summaryView;
@property (readwrite,assign) KBAVInfoStyle infoStyle;
- (UIImageView *)posterView;
@end

NS_ASSUME_NONNULL_END
