#import "KBAVInfoPanelDescriptionViewController.h"
#import "UIView+AL.h"
#import "UIImageView+WebCache.h"
#import "EXTScope.h"
#import "KBSliderImages.h"
#import "UIStackView+Helper.h"
#import "KBTextPresentationViewController.h"

@implementation KBAVInfoPanelDescriptionViewController

- (UIImageView *)posterView {
    return _posterView;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    [_posterView.heightAnchor constraintEqualToConstant:_mainStackView.frame.size.height *.08].active = true;
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
}

- (BOOL)hasContent {
    return (_metadata);
}

- (void)loadView {
    [super loadView];
    _mainStackView = [[UIStackView alloc] initForAutoLayout];
    _mainStackView.axis = UILayoutConstraintAxisHorizontal;
    _mainStackView.distribution = UIStackViewDistributionEqualSpacing; //3
    _mainStackView.alignment = UIStackViewAlignmentCenter;
    _mainStackView.spacing = 35;
    [self.view addSubview:_mainStackView];
    [_mainStackView autoCenterInSuperview];
    _posterView = [[UIImageView alloc] initForAutoLayout];
    _posterView.contentMode = UIViewContentModeScaleAspectFit;
    //[_posterView autoConstrainToSize:CGSizeMake(235, 132)];
    //used to be 235x235
    _posterViewHeightConstraint = [_posterView.heightAnchor constraintLessThanOrEqualToConstant:230];
    _posterViewHeightConstraint.active = true;
    _posterViewWidthConstraint = [_posterView.widthAnchor constraintLessThanOrEqualToConstant:409];
    _posterViewWidthConstraint.active = true;
    //_posterView.backgroundColor = [UIColor redColor];
    [self setupLabels];
    _detailsStackView = [[UIStackView alloc] initForAutoLayout];
    _detailsStackView.axis = UILayoutConstraintAxisVertical;
    _detailsStackView.distribution = UIStackViewDistributionEqualSpacing;
    _detailsStackView.spacing = 8;
    _detailsStackView.alignment = UIStackViewAlignmentTop; //1
    UIStackView *middleStack = [[UIStackView alloc] initForAutoLayout];
    middleStack.axis = UILayoutConstraintAxisHorizontal;
    middleStack.distribution = UIStackViewDistributionFillProportionally;
    middleStack.spacing = 10;
    //duration | genre | year | CC | HD
    [middleStack setArrangedViews:@[_durationLabel, _genreLabel, _yearLabel, _ccBadge, _videoResolutionBadge]];
    [_detailsStackView setArrangedViews:@[_titleLabel,_subtitleLabel,_summaryView, middleStack]];
    [_mainStackView setArrangedViews:@[_posterView,_detailsStackView]];
    [self populateTitles];
    //[_mainStackView.widthAnchor constraintEqualToConstant:835].active = true;
    _contentView = _mainStackView;
    
}

- (NSString *)durationFormatted {
    return [[KBAVInfoViewController sharedTimeFormatter] stringFromTimeInterval:_metadata.duration];
}

- (void)populateTitles {
    _titleLabel.text = _metadata.title;
    _subtitleLabel.text = _metadata.subtitle;
    _summaryView.text = _metadata.summary;
    _videoResolutionBadge.alpha = _metadata.isHD;
    _ccBadge.alpha = _metadata.hasCC;
    _genreLabel.text = _metadata.genre;
    _yearLabel.text = _metadata.year;
    _durationLabel.text = [self durationFormatted];
    if (_metadata.image) {
        _posterView.image = _metadata.image;
    } else {
        //DLog(@"imageURL %@:", _metadata.imageURL);
        [_posterView sd_setImageWithURL:_metadata.imageURL
                     placeholderImage:[UIImage imageNamed:@"video-icon"]];
    }
}

- (void)setMetadata:(KBAVMetaData *)metadata {
    _metadata = metadata;
    [self populateTitles];
}

- (void)setupLabels {
    _titleLabel = [[UILabel alloc] initForAutoLayout];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _subtitleLabel = [[UILabel alloc] initForAutoLayout];
    _subtitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _subtitleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _durationLabel = [[UILabel alloc] initForAutoLayout];
    _durationLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _durationLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _yearLabel = [[UILabel alloc] initForAutoLayout];
    _yearLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _yearLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _genreLabel = [[UILabel alloc] initForAutoLayout];
    _genreLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _genreLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _videoResolutionBadge = [[UIImageView alloc] initForAutoLayout];
    _videoResolutionBadge.contentMode = UIViewContentModeScaleAspectFit;
    [_videoResolutionBadge autoConstrainToSize:CGSizeMake(38, 22)];
    _videoResolutionBadge.alpha = 0;
    _videoResolutionBadge.image = [KBSliderImages HDImage];
    _ccBadge = [[UIImageView alloc] initForAutoLayout];
    _ccBadge.contentMode = UIViewContentModeScaleAspectFit;
    [_ccBadge autoConstrainToSize:CGSizeMake(38, 22)];
    _ccBadge.alpha = 0;
    _ccBadge.image = [KBSliderImages CCImage];
    _summaryView = [[KBMoreButton alloc] initForAutoLayout];
    _summaryView.labelMargin = 0.0;
    _summaryView.trailingTextFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _summaryView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _summaryView.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    _summaryView.trailingTextColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    [_summaryView autoConstrainToSize:CGSizeMake(1113, 100)]; //used to be 154
    _summaryView.focusedScaleFactor = 1.0;
    _summaryView.cornerRadius = 0.0;
    @weakify(self);
    _summaryView.buttonWasPressed = ^(NSString *text) {
        //DLog(@"pressed button with text: %@", text);
        [self_weak_ showViewWithText:text];
    };
    _summaryView.focusableUpdated = ^(BOOL canFocus) {
        //DLog(@"focusable updated");
        [[self_weak_ parentViewController] setNeedsFocusUpdate];
        [[self_weak_ parentViewController] updateFocusIfNeeded];
    };
    if (self.infoStyle == KBAVInfoStyleNew) {
        _titleLabel.textColor = [UIColor whiteColor];
        _genreLabel.textColor = [UIColor whiteColor];
        _yearLabel.textColor = [UIColor whiteColor];
        _durationLabel.textColor = [UIColor whiteColor];
        UIFont *cap2 = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        [_subtitleLabel setFont:cap2];
        [_summaryView setFont:cap2];
        [_summaryView setTrailingTextFont:cap2];
        [_summaryView setTrailingTextColor:[UIColor whiteColor]];
        [_genreLabel setFont:cap2];
        [_yearLabel setFont:cap2];
        [_durationLabel setFont:cap2];
        _posterView.layer.cornerRadius = 20;
        _posterView.layer.masksToBounds = true;
        _posterView.clipsToBounds = true;
    }
    //[_summaryLabel.widthAnchor constraintLessThanOrEqualToConstant:1113].active = true;
    //[_summaryLabel.heightAnchor constraintLessThanOrEqualToConstant:154].active = true;
    //_summaryLabel.numberOfLines = 0;
    //_summaryLabel.lineBreakMode = NSLineBreakByWordWrapping;
}

- (void)showViewWithText:(NSString *)text {
    KBTextPresentationViewController *textPres = [KBTextPresentationViewController new];
    textPres.textValue = text;
    textPres.packageLogo = _posterView.image;
    textPres.textView.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    textPres.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textPres.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:textPres animated:YES completion:nil];
}

@end
