#import "KBContextCollectionHeaderView.h"
#import "UIView+AL.h"

@implementation KBContextCollectionHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] initForAutoLayout];
        [self addSubview:_label];
        [_label autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(0, 25, 0, 0)];
        _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _label.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        self.translatesAutoresizingMaskIntoConstraints = false;
    }
    return self;
}

@end
