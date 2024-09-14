//
//  KBTableViewCell.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

//#import "Defines.h"
#import "KBTableViewCell.h"
#import "KBDataItemCollectionViewCell.h"
#import "FPScrollingBannerCollectionFlowLayout.h"
#import "UIColor+Additions.h"

@interface KBTableViewCell() {
    KBSection *section_;
}
@property KBDataItemCollectionViewCell *focusedView;
@end

@implementation KBTableViewCell

- (BOOL)canBecomeFocused {
    return NO;
}

- (CGFloat)systemFocusScaleFactor {
    return 1.07;
}

- (KBSection *)section {
    return section_;
}

- (void)setSection:(KBSection *)section {
    section_ = section;
    if(section.sectionType == KBSectionTypeStandard) {
        [self setupLabelIfNecessary];
        [self.trayTitleLabel sizeToFit];
        self.trayTitleLabel.text = section.sectionName;
    } else {
        self.trayTitleLabel.text = @"";
    }
}

- (void)setupLabelIfNecessary {
    if (!self.trayTitleLabel) {
        self.trayTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 10, 100, 100)];
        self.trayTitleLabel.font = [UIFont systemFontOfSize:38 weight:UIFontWeightSemibold];
        self.trayTitleLabel.textColor = [UIColor colorFromHex:@"887C74"];
        [self addSubview:self.trayTitleLabel];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (!(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) return nil;

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 9, 10);
    layout.itemSize = CGSizeMake(320, 240);
    layout.minimumLineSpacing = 50;
    layout.minimumInteritemSpacing = 100;
    
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.collectionView registerClass:[KBDataItemCollectionViewCell class] forCellWithReuseIdentifier:CollectionViewCellIdentifier];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundView = nil;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.collectionView];
    return self;
}

- (void)goToOne {
    NSInteger one = 1;
    if ([self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0] == INFINITE_CELL_COUNT){
        one = 24000;
    }
    NSIndexPath *ip = [NSIndexPath indexPathForItem:one inSection:0];
    [self.collectionView scrollToItemAtIndexPath:ip atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:FALSE];
    [self.collectionView setNeedsFocusUpdate];
    [self.collectionView updateFocusIfNeeded];
}

- (NSIndexPath *)focusedIndexPath {
    KBDataItemCollectionViewCell *cell = (KBDataItemCollectionViewCell*)[[UIFocusSystem focusSystemForEnvironment:self] focusedItem];
    if ([cell isKindOfClass:KBDataItemCollectionViewCell.class]) {
        NSIndexPath *ip = [self.collectionView indexPathForCell:cell];
        //DLog(@"found index path: %@", ip);
        return ip;
    }
    return nil;
}

- (void)takeTo1 {
    [self performSelector:@selector(goToOne) withObject:nil afterDelay:.1];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    //DLog(@"indexPath: %@", self.collectionView.indexPath);
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGSize defaultSize = CGSizeMake(308, 250);
    if (self.section) {
        defaultSize = CGSizeMake(self.section.imageWidth, self.section.imageHeight);
    }
    if (self.section.sectionType == KBSectionTypeBanner) {
        layout = [[FPScrollingBannerCollectionFlowLayout alloc] init];
        layout.itemSize = defaultSize;//CGSizeMake(640,480);//CGSizeMake(1700,400);
        layout.minimumInteritemSpacing = 1;
        layout.minimumLineSpacing = 50;//30;
        //layout.sectionInset = UIEdgeInsetsMake(20, 0, 0, 20);
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    } else {
        [self.trayTitleLabel sizeToFit];
        layout.itemSize = defaultSize;//CGSizeMake(308, 250);
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 40, 0, 20);
        layout.minimumLineSpacing = 50;
        layout.sectionHeadersPinToVisibleBounds = YES;
        
    }
    [self.collectionView setCollectionViewLayout:layout animated:NO];
    self.collectionView.frame = self.contentView.bounds;
}

- (void)updateLayoutWithCoordinator:(UIFocusAnimationCoordinator*)coordinator {
    if (self.focusedView) {
        CGFloat overlap = [self titleOverLapFor:self.focusedView];
        BOOL hasOverlap = overlap > 0;
        if (hasOverlap){
            //DLog(@"has overlap: %.0f", overlap);
        }
        //BOOL isTitleShifted = !CGAffineTransformIsIdentity(self.trayTitleLabel.transform);
        CGAffineTransform transform = hasOverlap ? CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -overlap) : CGAffineTransformIdentity;
        if (coordinator) {
            if (hasOverlap) {
                [coordinator addCoordinatedAnimations:^{
                    self.trayTitleLabel.transform = transform;
                } completion:nil];
            } else {
                [coordinator addCoordinatedUnfocusingAnimations:^(id<UIFocusAnimationContext>  _Nonnull animationContext) {
                    self.trayTitleLabel.transform = transform;
                } completion:nil];
            }
        } else {
            self.trayTitleLabel.transform = transform;
        }
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    //DLog(@"my section: %lu", self.collectionView.indexPath.section);
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    if (self.section.sectionName.length == 0) return;
    KBDataItemCollectionViewCell *cell = (KBDataItemCollectionViewCell*)context.nextFocusedView;
    if ([cell isKindOfClass:KBDataItemCollectionViewCell.class]) {
        self.focusedView = cell;
        [self updateLayoutWithCoordinator:coordinator];
    }
}

- (void)setCollectionViewDataSourceDelegate:(id<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDataSourcePrefetching>)dataSourceDelegate section:(NSInteger)section {
    self.collectionView.dataSource = dataSourceDelegate;
    self.collectionView.prefetchingEnabled = true;
    self.collectionView.prefetchDataSource = dataSourceDelegate;
    self.collectionView.delegate = dataSourceDelegate;
    self.collectionView.section = section;
    [self.collectionView setContentOffset:self.collectionView.contentOffset animated:NO];
    
    [self.collectionView reloadData];
}

- (CGFloat)titleOverLapFor:(UIView *)focusedView {
    if (![focusedView isDescendantOfView:self]) { return 0; }
    //DLog(@"focusedViewSize: %@", NSStringFromCGSize(focusedView.frame.size));
    //focusedViewSize: {320, 240}
    CGSize scaledDelta = CGSizeMake(focusedView.frame.size.width * (self.systemFocusScaleFactor-1), focusedView.frame.size.height * (self.systemFocusScaleFactor-1));
    //DLog(@"scaled delta: %@", NSStringFromCGSize(scaledDelta));
    //scaled delta: {22.40000000000002, 16.800000000000015}
    CGRect testFrame = [self convertRect:focusedView.bounds fromView:focusedView];
    CGFloat headerContentRight = CGRectGetMinX(self.trayTitleLabel.frame) + CGRectGetMaxX(self.trayTitleLabel.frame);
    //DLog(@"headerContentRight: %.0f", headerContentRight);
    //headerContentRight: 356
    CGFloat tFrameMinX = CGRectGetMinX(testFrame);
    //DLog(@"tFrameMinX: %.0f", tFrameMinX);
    //tFrameMinX: 80
    if (tFrameMinX > headerContentRight) {
        return 0;
    }
    return scaledDelta.height/2;
}

@end
