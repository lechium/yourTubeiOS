#import "KBAVInfoPanelCollectionViewTextCell.h"
#import "UIView+AL.h"
#import "KBSliderImages.h"
@implementation KBAVInfoPanelCollectionViewTextCell

- (void)setTitle:(NSString *)title {
    _title = title;
    _titleLabel.text = title;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] initForAutoLayout];
        _checkmarkImageView = [[UIImageView alloc] initForAutoLayout];
        [self addSubview:_titleLabel];
        [self addSubview:_checkmarkImageView];
        [_checkmarkImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:27].active = true;
        [_checkmarkImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:3].active = true;
        [_checkmarkImageView autoConstrainToSize:CGSizeMake(34, 29)];
        [_titleLabel.leftAnchor constraintEqualToAnchor:_checkmarkImageView.rightAnchor constant:8].active = true;
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    if (selected) {
        _checkmarkImageView.image = [KBSliderImages checkmarkImage];//[UIImage systemImageNamed:@"checkmark"];
    } else {
        _checkmarkImageView.image = nil;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    _checkmarkImageView.image = nil;
    _titleLabel.text = nil;
}

- (void)traitCollectionDidChange:(id)arg1 {
    [super traitCollectionDidChange:arg1];
}

- (void)didUpdateFocusInContext:(id)arg1 withAnimationCoordinator:(id)arg2 {
    if ([self isFocused]) {
        _titleLabel.textColor = [UIColor whiteColor];
    } else {
        _titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    [super didUpdateFocusInContext:arg1 withAnimationCoordinator:arg2];
}

@end
