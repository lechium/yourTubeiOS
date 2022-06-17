//
//  KBContextMenuView.m
//  Ethereal
//
//  Created by kevinbradley on 2/23/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "KBContextMenuView.h"
#import "UIView+AL.h"
#import "KBContextMenuViewCell.h"
#import "KBContextMenuRepresentation.h"
#import "KBContextMenuSection.h"
#import "KBContextCollectionHeaderView.h"
#import "KBButton.h"

#define ANIMATION_DURATION 0.3

@implementation KBContextMenuView {
    UIView *_backgroundView;
}

- (instancetype)initWithMenu:(KBMenu *)menu sourceView:(UIView *)sourceView delegate:(id<KBContextMenuViewDelegate>)delegate {
    self = [super initForAutoLayout];
    if (self) {
        _sourceView = sourceView;
        _delegate = delegate;
        _menu = menu;
        _representation = [KBContextMenuRepresentation representationForMenu:_menu];
    }
    return self;
}

- (void)refresh {
    _representation = [KBContextMenuRepresentation representationForMenu:_menu];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

- (void)destroyContextView {
    if (self.delegate){
        [self.delegate destroyContextView];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _backgroundView = [[UIView alloc] initForAutoLayout];
        self.backgroundColor = nil;
        [self addSubview:_backgroundView];
        [_backgroundView autoPinEdgesToSuperviewEdges];
        _backgroundView.layer.masksToBounds = true;
        _backgroundView.layer.cornerRadius = 27;
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.translatesAutoresizingMaskIntoConstraints = false;
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
        vibrancyEffectView.translatesAutoresizingMaskIntoConstraints = false;
        [_backgroundView addSubview:blurView];
        [blurView autoPinEdgesToSuperviewEdges];
        [_backgroundView addSubview:vibrancyEffectView];
        [vibrancyEffectView autoPinEdgesToSuperviewEdges];
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical; //CGRectMake(0, 0, 659, 35)
        layout.itemSize = CGSizeMake(400,70);
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.sectionHeadersPinToVisibleBounds = true;
        //layout.minimumLineSpacing = 80;
        _collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        _collectionView.translatesAutoresizingMaskIntoConstraints = false;
        [self addSubview:_collectionView];
        [self.collectionView registerClass:KBContextMenuViewCell.class forCellWithReuseIdentifier:@"cell"];
        [_collectionView autoPinEdgesToSuperviewEdges];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:KBContextCollectionHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"Header"];
        [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer"];
        //[self setAnchorPoint:CGPointMake(0, 1) forView:self];
        //self.layer.anchorPoint = CGPointMake(0, 0);
    }
    return self;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]){
        KBContextCollectionHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
        KBContextMenuSection *section = _representation.sections[indexPath.section];
        header.label.text = [section.title uppercaseString];
        return header;
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Footer" forIndexPath:indexPath];
        footer.backgroundColor = [UIColor blackColor];
        return footer;
    }
    return nil;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGRect frameRect =  [UIScreen mainScreen].bounds;
    return CGSizeMake(frameRect.size.width, 59);
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section > 0 || [collectionView numberOfSections] == 1){
        return CGSizeZero;
    }
    CGRect frameRect =  [UIScreen mainScreen].bounds;
    return CGSizeMake(frameRect.size.width, 10);
}

- (NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView {
    return [NSIndexPath indexPathForItem:0 inSection:0];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _representation.sections.count;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canFocusItemAtIndexPath:(NSIndexPath *)indexPath {
    KBContextMenuSection *section = _representation.sections[indexPath.section];
    KBAction *opt = section.items[indexPath.row];
    if (opt.attributes & KBMenuElementAttributesDisabled) {
        TLog(@"canFocusItemAtIndexPath disabled!");
        return false;
    }
    return true;
}

-  (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KBContextMenuViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    KBContextMenuSection *section = _representation.sections[indexPath.section];
    KBAction *opt = section.items[indexPath.row];
    /*
    cell.leadingImageView.image = opt.image;
    cell.label.text = opt.title;
    [cell setSelected:(opt.state == KBMenuElementStateOn) animated:false];
    [cell setAttributes:opt.attributes];
     */
    [cell configureWithAction:opt section:section];
    return cell;
}

-(NSInteger)collectionView:(id)collectionView numberOfItemsInSection:(NSInteger)section {
    KBContextMenuSection *currentSection = _representation.sections[section];
    return currentSection.items.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedMediaOptionIndex = indexPath.row;
    KBContextMenuSection *currentSection = _representation.sections[indexPath.section];
    KBAction *opt = currentSection.items[indexPath.row];
    if (opt.attributes & KBMenuElementAttributesDisabled) {
        TLog(@"disabled!");
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(selectedItem:)]){
        [self.delegate selectedItem:opt];
    }
   // opt.state = KBMenuElementStateOn;
    if (currentSection.singleSelection){
        opt.state = KBMenuElementStateOn;
        [currentSection.items enumerateObjectsUsingBlock:^(KBMenuElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx != indexPath.row){
                [(KBAction*)obj setState:KBMenuElementStateOff];
            }
        }];
    } else {
        if (opt.attributes & KBMenuElementAttributesToggle){
            if (opt.state == KBMenuElementStateOn) {
                opt.state = KBMenuElementStateOff;
            } else if (opt.state == KBMenuElementStateOff) {
                opt.state = KBMenuElementStateOn;
            }
        }
    }
    opt.handler(opt);
    [self.collectionView reloadData];
    if (currentSection.singleSelection) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[self sourceView] respondsToSelector:@selector(dismissMenuWithCompletion:)]) {
                [(id<KBContextMenuSourceDelegate>)self.sourceView dismissMenuWithCompletion:^{
                    [self destroyContextView];
                }];
            }
            /*
            [self showContextView:false completion:^{
                [self destroyContextView];
                if ([self.sourceView respondsToSelector:@selector(opened)]){
                    [(id<KBContextMenuSourceDelegate>)self.sourceView setOpened:false];
                }
            }];*/
        });
    }
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view {
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x,
                                   view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x,
                                   view.bounds.size.height * view.layer.anchorPoint.y);

    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);

    CGPoint position = view.layer.position;

    position.x -= oldPoint.x;
    position.x += newPoint.x;

    position.y -= oldPoint.y;
    position.y += newPoint.y;

    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}

- (NSInteger)itemCount {
    __block NSInteger count = 0;
    NSArray <KBContextMenuSection *> * sections = self.representation.sections;
    [sections enumerateObjectsUsingBlock:^(KBContextMenuSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        count = count + obj.items.count;
    }];
    return count + sections.count;
}

- (void)showContextViewFromButton:(KBButton *)button completion:(void (^)(void))block {
    //_visibleContextView = [[KBContextMenuView alloc] initForAutoLayout];
    self.alpha = 0;
    //self.layer.anchorPoint = CGPointMake(0, 1);
    self.transform = CGAffineTransformScale(self.transform, 0.01, 0.01);
    NSInteger itemCount = [self itemCount];
    CGFloat height = (itemCount * 70);
    //TLog(@"item count: %lu height: %f", itemCount, height);
    [self autoConstrainToSize:CGSizeMake(400, height)];
    [button.superview addSubview:self];
    [self.collectionView reloadData];
    [self.trailingAnchor constraintEqualToAnchor:self.sourceView.trailingAnchor constant:0].active = true;
    [self.bottomAnchor constraintEqualToAnchor:self.sourceView.topAnchor constant:-36].active = true;
    [UIView animateWithDuration:ANIMATION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1.0;
        //self.layer.anchorPoint = CGPointMake(0.5, 0.5);
        [self layoutIfNeeded];
        [self setNeedsFocusUpdate];
        [self updateFocusIfNeeded];
        self.collectionView.clipsToBounds = false;
        
    } completion:^(BOOL finished) {
        [self sendShowMessageIfNecessary];
        if (block) {
            block();
        }
    }];
   
}

- (void)sendShowMessageIfNecessary {
    if (self.delegate && [self.delegate respondsToSelector:@selector(menuShown:from:)]){
        [(id<KBButtonMenuDelegate>)self.delegate menuShown:self from:_sourceView];
    }
}

- (void)sendHiddenMessageIfNecessary {
    if (self.delegate && [self.delegate respondsToSelector:@selector(menuHidden:from:)]){
        [(id<KBButtonMenuDelegate>)self.delegate menuHidden:self from:_sourceView];
    }
    
}

- (void)showContextView:(BOOL)show fromView:(UIViewController *_Nullable)viewController completion:(void(^_Nullable)(void))block {
    if (!show) {
        //self.layer.anchorPoint = CGPointMake(1, 0);
        [UIView animateWithDuration:ANIMATION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.transform = CGAffineTransformScale(self.transform, 0.01, 0.01);;
            self.alpha = 0.0;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self sendHiddenMessageIfNecessary];
            [self removeFromSuperview];
            if (block) {
                block();
            }
            //[self_weak_ destroyContextView];
        }];
    } else {
        //_visibleContextView = [[KBContextMenuView alloc] initForAutoLayout];
        self.alpha = 0;
        //self.layer.anchorPoint = CGPointMake(0, 1);
        self.transform = CGAffineTransformScale(self.transform, 0.01, 0.01);
        NSInteger itemCount = [self itemCount];
        CGFloat height = (itemCount * 70);
        [self autoConstrainToSize:CGSizeMake(400, height)];
        [viewController.view addSubview:self];
        [self.collectionView reloadData];
        [self.trailingAnchor constraintEqualToAnchor:self.sourceView.trailingAnchor constant:0].active = true;
        [self.bottomAnchor constraintEqualToAnchor:self.sourceView.topAnchor constant:-36].active = true;
        [UIView animateWithDuration:ANIMATION_DURATION delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.transform = CGAffineTransformIdentity;
            self.alpha = 1.0;
            //self.layer.anchorPoint = CGPointMake(0.5, 0.5);
            [self layoutIfNeeded];
            [self setNeedsFocusUpdate];
            [self updateFocusIfNeeded];
            self.collectionView.clipsToBounds = false;
            
        } completion:^(BOOL finished) {
            [self sendShowMessageIfNecessary];
            if (block) {
                block();
            }
        }];
       
    }
}

- (void)showContextView:(BOOL)show fromView:(UIViewController *_Nullable)viewController {
    [self showContextView:show fromView:viewController completion:nil];
}

- (void)showContextView:(BOOL)show completion:(void (^)(void))block {
    [self showContextView:show fromView:nil completion:block];
}

@end
