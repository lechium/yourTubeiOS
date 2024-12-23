//
//  KBFeaturedViewController.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 2/28/17.
//  Copyright © 2017 nito, LLC. All rights reserved.
//

#import "tvOSShelfController.h"
#import "KBShelfViewController.h"
#import "KBTableViewCell.h"
#import "KBDataItemCollectionViewCell.h"
#import "UIImageView+WebCache.h"
#import "UIColor+Additions.h"
#import <objc/runtime.h>
#import "KBModelItem.h"
#import "UIImage+Scale.h"
#import "UIImage+Transform.h"
#import "KBYourTube.h"

#define HEADER_SIZE 260.0
#define TABLE_TOP 100.0
#define TAB_TOP 50.0

@interface KBShelfViewController () {
    UILongPressGestureRecognizer *longPress;
    BOOL _firstAppearance;
    NSArray <KBSectionProtocol> *sections_;
    NSMutableArray *_cells;
    NSArray <KBYTTab *>*_tabDetails;
    UIView *_viewToFocus;
}
@property (nonatomic, assign) CGFloat lastScrollViewOffsetX;
@property (nonatomic, assign) CGFloat lastScrollViewOffsetY;
@property (nonatomic, strong) NSMutableDictionary *contentOffsetDictionary;
@property (nonatomic, strong) NSTimer *bannerTimer;
@property (nonatomic, strong) NSCache *cellCache;
@property (nonatomic, strong) NSArray *cellArray;
@property ScrollDirection scrollDirection;
@property NSDate *randomDate;
@property (nonatomic, strong) NSLayoutConstraint *headerHeightConstraint;
@end

@implementation KBShelfViewController


- (NSArray *) preferredFocusEnvironments {
    NSArray *sup = [super preferredFocusEnvironments];
    if (_viewToFocus) {
        return @[_viewToFocus];
    }
    return sup;
}

- (void)setViewToFocus:(UIView *)view {
    _viewToFocus = view;
    [self setNeedsFocusUpdate];
    [self updateFocusIfNeeded];
}

- (UIView *)viewToFocus {
    return _viewToFocus;
}

- (void)setTabDetails:(NSArray <KBYTTab*> *)tabDetails {
    _tabDetails = tabDetails;
    [self setupTabBar];
}

- (void)setupTabBar {
    if (!self.tabBar) {
        self.tabBar = [[UITabBar alloc] initForAutoLayout];
        [self.view addSubview:self.tabBar];
        [self.tabBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.tabBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.tabBar autoCenterVerticallyInSuperview];
        /*
        UIFocusGuide *focusGuideTop = [[UIFocusGuide alloc] init];
        [self.tabBar addLayoutGuide:focusGuideTop];
        [focusGuideTop.widthAnchor constraintEqualToAnchor:self.tabBar.widthAnchor].active = true;
        [focusGuideTop.heightAnchor constraintEqualToConstant:1].active = true;
        [focusGuideTop.topAnchor constraintEqualToAnchor:self.tabBar.topAnchor].active = true;
        [focusGuideTop.leadingAnchor constraintEqualToAnchor:self.tabBar.leadingAnchor].active = true;
        [focusGuideTop.trailingAnchor constraintEqualToAnchor:self.tabBar.trailingAnchor].active = true; */
        [NSLayoutConstraint deactivateConstraints:@[self.tableTopConstraint]];
        if (self.headerview) {
            //focusGuideTop.preferredFocusEnvironments = @[self.headerview.subButton, self.tabBar];
            self.tabBarTopConstraint = [self.tabBar autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerview withOffset:TAB_TOP];
        } else {
            //[self.tabBar autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:100];
            self.tabBarTopConstraint = [self.tabBar autoPinEdgeToSuperviewMargin:ALEdgeTop];
        }
        self.tableTopConstraint = [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tabBar withOffset:100];
        NSMutableArray *tabBarItems = [NSMutableArray new];
        /*
        [self.tabDetails enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:obj image:nil tag:idx];
            [tabBarItems addObject:item];
        }];*/
        [self.tabDetails enumerateObjectsUsingBlock:^(KBYTTab * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:obj.title image:nil tag:idx];
            [tabBarItems addObject:item];
        }];
        [self.tabBar setItems:tabBarItems animated:true];
        self.tabBar.delegate = self;
        [self afterSetupTabBar];
    }
}

- (void)afterSetupTabBar {
    
}

- (NSArray <KBYTTab *>*)tabDetails {
    return _tabDetails;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    LOG_SELF;
    
}

- (KBYTChannelHeaderView *)headerview {
    return nil; //override in subclass
}

- (BOOL)firstLoad {
    return _firstAppearance;
}

+ (void)initialize {
    [[KBYourTube sharedUserDefaults] registerDefaults:@{kShelfControllerRoundedEdges: @(true)}];
}

- (void)setUseRoundedEdges:(BOOL)useRoundedEdges {
    [[KBYourTube sharedUserDefaults] setBool:useRoundedEdges forKey:kShelfControllerRoundedEdges];
    [self.tableView reloadData];
}

+ (BOOL)useRoundedEdges {
    return [[KBYourTube sharedUserDefaults] boolForKey:kShelfControllerRoundedEdges];
}

- (BOOL)useRoundedEdges {
    return [[KBYourTube sharedUserDefaults] boolForKey:kShelfControllerRoundedEdges];
}


-(void)loadView {
    [super loadView];
    self.randomDate = [NSDate date];
    self.contentOffsetDictionary = [NSMutableDictionary dictionary];
    self.cellCache = [NSCache new];
    _cells = [NSMutableArray new];
}


- (void)expandHeaderAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.headerTopConstraint.constant = 0;
            self.headerview.alpha = 1.0;
            [NSLayoutConstraint deactivateConstraints:@[self.tableTopConstraint]];
            if (self.headerview) {
                self.tableTopConstraint = [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tabBar ? self.tabBar : self.headerview withOffset:self.tabBar ? TAB_TOP : TABLE_TOP];
            } else {
                self.tableTopConstraint = [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tabBar ? self.tabBar : self.view withOffset:self.tabBar ? TAB_TOP : 0];
                self.tabBarTopConstraint.constant = 0;
            }
            self.tabBar.alpha = 1.0;
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        self.headerTopConstraint.constant = 0;
        self.headerview.alpha = 1.0;
        self.tabBar.alpha = 1.0;
        [NSLayoutConstraint deactivateConstraints:@[self.tableTopConstraint]];
        if (self.headerview) {
            self.tableTopConstraint = [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tabBar ? self.tabBar : self.headerview withOffset:self.tabBar ? TAB_TOP : TABLE_TOP];
        } else {
            self.tabBarTopConstraint.constant = 0;
            self.tableTopConstraint = [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.tabBar ? self.tabBar : self.view withOffset:self.tabBar ? TAB_TOP : 0];
        }
        [self.view layoutIfNeeded];
    }
}

- (NSInteger)selectedTabIndex {
    if (!self.tabBar) {
        return NSNotFound;
    }
    return [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
}

- (void)collapseHeaderAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.headerTopConstraint.constant = -HEADER_SIZE;
            self.headerview.alpha = 0;
            self.tabBar.alpha = 0;
            [NSLayoutConstraint deactivateConstraints:@[self.tableTopConstraint]];
            if (self.headerview) {
                self.tableTopConstraint =  [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerview withOffset:TABLE_TOP];
            } else {
                self.tabBarTopConstraint.constant = -TABLE_TOP;
                self.tableTopConstraint =  [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
            }
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        self.headerview.alpha = 0;
        self.headerTopConstraint.constant = -HEADER_SIZE;
        self.tabBar.alpha = 0;
        [NSLayoutConstraint deactivateConstraints:@[self.tableTopConstraint]];
        if (self.headerview) {
            self.tableTopConstraint =  [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.headerview withOffset:TABLE_TOP];
        } else {
            self.tabBarTopConstraint.constant = -TABLE_TOP;
            self.tableTopConstraint =  [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        }
        [self.view layoutIfNeeded];
    }
}

- (void)viewDidLoad {
    _firstAppearance =  true;
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = FALSE;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    KBYTChannelHeaderView *headerView = [self headerview];
    if (headerView) {
        [self.view addSubview:headerView];
        //self.headerTopConstraint = [headerView autoPinEdgeToSuperviewMargin:ALEdgeTop];
        self.headerTopConstraint = [headerView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [headerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [headerView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [headerView setupView];
        self.headerHeightConstraint = [headerView autoSetDimension:ALDimensionHeight toSize:HEADER_SIZE];
        self.tableTopConstraint =  [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:headerView withOffset:TABLE_TOP];
    } else {
        self.tableTopConstraint =  [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        //[self.tableView autoPinEdgesToSuperviewEdges];
    }
    UIEdgeInsets edgeInsets = self.tableView.contentInset;
    edgeInsets.top = -10;
    self.tableView.insetsContentViewsToSafeArea = false;
    self.tableView.insetsLayoutMarginsFromSafeArea = false;
    self.tableView.contentInset = edgeInsets;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [self.view addGestureRecognizer:longPress];
    self.tabBarObservedScrollView = self.tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
    self.tableView.maskView = nil;
    self.navigationController.view.backgroundColor = nil;
    self.tabBarController.view.backgroundColor = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_firstAppearance) {
        _firstAppearance = false;
    }
}

- (void)updateAutoScroll {
    if (self.sections.count > 0){
        if ([self autoScrollSections].count > 0){
            [self startAutoscrollBanners];
        }
    }
}

- (void)startAutoscrollBanners {
    self.bannerTimer = [NSTimer scheduledTimerWithTimeInterval:12 target:self selector:@selector(showNextBanner) userInfo:nil repeats:YES];
}

- (void)stopAutoscrollBanners {
    [self.bannerTimer invalidate];
    self.bannerTimer = nil;
}

- (NSArray <KBSection *> *)sections {
    return sections_;
}

- (void)setSections:(NSArray<KBSection *> *)sections {
    sections_ = sections;
    [self handleSectionsUpdated];
}

- (void)handleSectionsUpdated {
    [self createTableViewCells];
    [self updateAutoScroll];
}

- (void)showNextBanner {
    if (self.selectedSection == 0) return;
    if (self.sections.count == 0) { return; }
    [[self autoScrollSections] enumerateObjectsUsingBlock:^(KBSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [self.sections indexOfObject:obj];
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:index];
        KBSection *featuredSection = self.sections[index];
        KBTableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
        UICollectionView *cv = cell.collectionView;
        
        NSIndexPath *indexPathForCell = [self centeredIndexPathForCollectionView:cv];
        //DLog(@"featuredSection.packages.count: %lu indexPathForCell.row: %lu ", featuredSection.items.count, indexPathForCell.row);
        if (featuredSection.content.count == indexPathForCell.row+1){
            //DLog(@"nope");
            [cell goToOne];
            return;
        }
        
        if (self.selectedSection != index) {
            ip = [NSIndexPath indexPathForRow:indexPathForCell.row+1 inSection:0];
            
            [CATransaction begin];
            [CATransaction setAnimationDuration:8];
            [cv scrollToItemAtIndexPath:ip
                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                               animated:YES];
            [CATransaction commit];
        }
    }];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        KBDataItemCollectionViewCell *cell = (KBDataItemCollectionViewCell*)[[UIFocusSystem focusSystemForEnvironment:self.tableView] focusedItem];
        if ([cell isKindOfClass:KBDataItemCollectionViewCell.class]) {
            NSInteger sectionIndex = self.selectedSection;
            KBSection *section = self.sections[@(sectionIndex)];
            if (section) {
                //DLog(@"section: %@", section);
                KBTableViewCell *selectedTableCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sectionIndex]];
                NSIndexPath *ip = [selectedTableCell.collectionView indexPathForCell:cell];
                DLog(@"found index: %lu", ip.row);
                KBModelItem *item = section.content[@(ip.row)];
                DLog(@"found item: %@",item);
                if (self.itemSelectedBlock) {
                    self.itemSelectedBlock(item, true, ip.row, sectionIndex);
                }
            }
            
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSArray *)arrayForSection:(NSInteger)section {
    KBSection *currentSection = self.sections[section];
    return currentSection.content;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSArray <KBSection *> *)infiniteSections {
    return [self.sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"infinite == true"]];
}

- (NSArray <KBSection *> *)autoScrollSections {
    return [self.sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"autoScroll == true"]];
}

- (void)createTableViewCells {
    [self showHUD];
    [_cellCache removeAllObjects];
    [_cells removeAllObjects];
    [self.sections enumerateObjectsUsingBlock:^(KBSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:idx];
        KBTableViewCell *cell = [self createCellAtIndexPath:ip];
        [_cells addObject:cell];
        //[_cellCache setObject:cell forKey:@(idx)];
    }];
    _cellArray = _cells;
    [self dismissHUD];
    [self.tableView reloadData];
    //[self handleInfiniteSections];
}

- (void)handleInfiniteSections {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[self infiniteSections] enumerateObjectsUsingBlock:^(KBSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger index = [self.sections indexOfObject:obj];
            //KBTableViewCell *cell = [self.cellCache objectForKey:@(index)];
            KBTableViewCell *cell = self.cellArray[index];
            [cell goToOne];
        }];
    });
}

- (void)handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {

    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
}

- (KBTableViewCell *)createCellAtIndexPath:(NSIndexPath *)indexPath {
    KBSection *section = self.sections[indexPath.section];
    static NSString *CellIdentifier = @"CellIdentifier";
    KBTableViewCell *cell = (KBTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[KBTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        UILongPressGestureRecognizer *longpress
        = [[UILongPressGestureRecognizer alloc]
           initWithTarget:self action:@selector(handleLongpressMethod:)];
        longpress.minimumPressDuration = .5; //seconds
        longpress.delegate = self;
        longpress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
        [cell addGestureRecognizer:longpress];
    }
    cell.section = section;
    cell.channelDisplayType = section.channelDisplayType;
    [cell setCollectionViewDataSourceDelegate:self section:indexPath.section];
    return cell;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //KBTableViewCell *cell = [self.cellCache objectForKey:@(indexPath.section)];
    KBTableViewCell *cell = self.cellArray[@(indexPath.section)];
    if (!cell) {
        cell = [self createCellAtIndexPath:indexPath];
        //[_cells insertObject:cell atIndex:indexPath.row];
        //self.cellArray = _cells;
        //[_cellCache setObject:cell forKey:@(indexPath.section)];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(KBTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //CGFloat horizontalOffset = [self.contentOffsetDictionary[[@(index) stringValue]] floatValue];
    //[cell.collectionView setContentOffset:CGPointMake(horizontalOffset, 0)];
}

#pragma mark - UITableViewDelegate Methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KBSection *section = self.sections[indexPath.section];
    if (section.content.count == 0) { return 0; }
    if (section.sectionType == KBSectionTypeBanner){
        return section.imageHeight + 100;
    } else {
        if (section.channelDisplayType == ChannelDisplayTypeGrid) {
            CGFloat imageHeight = section.imageHeight * 4;
            //TLog(@"imageHeight: %.0f returned: %.0f", imageHeight, MIN(imageHeight, 1000));
            return MIN(imageHeight, 1000);
        }
        return section.imageHeight + 170; //need extra space for the labels and whatnot
    }
}

#pragma mark - UICollectionViewDataSource Methods

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger realSection = [collectionView section];
    //get our detail array based on collectionView
    KBSection *currentSection = self.sections[realSection];
    if (currentSection.infinite) return INFINITE_CELL_COUNT;
    NSArray *detailsArray = [self arrayForSection:realSection];
    //DLog(@"details for section titled: %@ count: %lu index: %lu section2: %lu", self.sections[realSection].sectionName, detailsArray.count, realSection, section);
    return detailsArray.count;
}

- (KBModelItem *)collectionView:(UICollectionView *)collectionView itemAtRow:(NSInteger)row {
    NSInteger realSection = [collectionView section];
    NSArray *detailsArray = [self arrayForSection:realSection];
    NSInteger index = row;
    KBSection *featuredSection = self.sections[realSection];
    if (featuredSection.infinite) {
        index = index % detailsArray.count;
    }
    return detailsArray[@(index)];
}

//an item was selected!

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.itemSelectedBlock) {
        KBModelItem *item = [self collectionView:collectionView itemAtRow:indexPath.row];
        if (self.itemSelectedBlock) {
            self.itemSelectedBlock(item, FALSE, indexPath.row, [collectionView section]);
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    KBDataItemCollectionViewCell *ourCell = (KBDataItemCollectionViewCell*)cell;
    NSInteger realSection = [collectionView section];
    KBSection *section = self.sections[@(realSection)];
    if (section.sectionType == KBSectionTypeBanner) {
        ourCell.label.text = @"";
        ourCell.imageHeightConstraint.constant = section.imageHeight;
    } else {
        ourCell.imageHeightConstraint.constant = section.imageHeight;
    }
    if (section.channelDisplayType == ChannelDisplayTypeGrid) {
        NSInteger rowCount = section.content.count / 5;
        NSInteger currentRow = indexPath.row / 5;
        //TLog(@"indexRow : %lu currentRow: %lu rowCount: %lu, searchCount: %lu", indexPath.row, currentRow, rowCount, self.searchResults.count);
        if (currentRow+1 >= rowCount) {
            //DLog(@"get next page as grid");
            //[self getNextPage];
        }
    }
   
}

- (void)focusedCellIndex:(NSInteger)cellIndex inSection:(NSInteger)section inCollectionView:(UICollectionView *)collectionView {
    //DLog(@"focusedCell: %lu inSection: %lu", cellIndex, section);
    if (self.itemFocusedBlock) {
        self.itemFocusedBlock(cellIndex, section, collectionView);
    }
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator{
    
    //DLog(@"nfv: %@", context.nextFocusedView);
    UICollectionViewCell *cell = (UICollectionViewCell*)context.nextFocusedView;
    UICollectionView *sv = (UICollectionView*)cell.superview;
    if ([sv respondsToSelector:@selector(section)]){
        //DLog(@"selected section: %lu", sv.indexPath.section);
        BOOL sectionChanged = (self.selectedSection != sv.section);
        if (sectionChanged) {
            //DLog(@"changed from section: %lu to %lu", self.selectedSection, sv.section);
        }
        self.selectedSection = sv.section;
        
        if ([self headerview] || self.tabBar) {
            KBSection *currentSection = self.sections[@(self.selectedSection)];
            if (currentSection.channelDisplayType == ChannelDisplayTypeGrid) {
                if ([cell isKindOfClass:UICollectionViewCell.class]) {
                    NSInteger row = [sv indexPathForCell:cell].row;
                    NSInteger rowCount = currentSection.content.count / 5;
                    NSInteger currentRow = row / 5;
                    if (currentRow == 0) {
                        [self expandHeaderAnimated:true];
                    } else if (currentRow > 0) {
                        [self collapseHeaderAnimated:true];
                    }
                    //self.focusedCollectionCell = cell;
                }
            } else { //shelf style
                if (sv.section == 0) {
                    [self expandHeaderAnimated:true];
                } else if (sv.section > 0){
                    [self collapseHeaderAnimated:true];
                }
            }
            
        }
        if ([cell isKindOfClass:UICollectionViewCell.class]) {
            NSInteger itemIndex = [sv indexPathForCell:cell].row;
            self.focusedCollectionCell = cell;
            [self focusedCellIndex:itemIndex inSection:sv.section inCollectionView:sv];
            
        }
    } else {
        self.selectedSection = 0;
    }
}

- (NSIndexPath *)indexPathForPreferredFocusedViewInCollectionView:(UICollectionView *)collectionView {
    KBSection *currentSection = self.sections[collectionView.section];
    if (currentSection.sectionType != SectionTypeBanner && !currentSection.infinite) { return nil; }
    NSIndexPath *visibleIndexPath = [self centeredIndexPathForCollectionView:collectionView];
    return visibleIndexPath;
}


- (NSIndexPath *)centeredIndexPathForCollectionView:(UICollectionView *)collectionView {
    
    CGRect visibleRect = (CGRect){.origin = collectionView.contentOffset, .size = collectionView.bounds.size};
    CGPoint visiblePoint = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
    NSIndexPath *visibleIndexPath = [collectionView indexPathForItemAtPoint:visiblePoint];
    return visibleIndexPath;
}

- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    /*
     NSInteger realSection = [(UICollectionView *)collectionView section];
     NSArray *detailsArray = [self arrayForSection:realSection];
     FeaturedSection *featuredSection = self.sections[realSection];
     */
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KBDataItemCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    
    NSInteger realSection = [collectionView section];
    KBSection *featuredSection = self.sections[realSection];
    KBModelItem *currentItem = [self collectionView:collectionView itemAtRow:indexPath.row];
    cell.label.text = currentItem.title;
    CGSize currentSize = featuredSection.imageSize;
    if (featuredSection.sectionType == SectionTypeBanner) {
        cell.bannerLabel.text = currentItem.title;
        [cell.bannerLabel shadowify];
        cell.bannerDescription.text = currentItem.details;
        [cell.bannerDescription shadowify];
        cell.bottomRightLabel.text = @"";
        NSString *banner = [currentItem.banner stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        if ([KBShelfViewController useRoundedEdges]) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:banner] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates | SDWebImageAvoidAutoSetImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (!CGSizeEqualToSize(currentSize, image.size)) {
                    image = [image scaledImagedToSize:currentSize];
                }
                //DLog(@"banner %@ section size: %@ vs: %@ ratio: %.5f", currentItem.title,NSStringFromCGSize(currentSize), NSStringFromCGSize(image.size), image.aspectRatio);
                UIImage *rounded = [image sd_roundedCornerImageWithRadius:20.0 corners:UIRectCornerAllCorners borderWidth:0 borderColor:nil];
                cell.imageView.image = rounded;
            }];
        } else {
            //[cell.imageView sd_setImageWithURL:[NSURL URLWithString:banner] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates];
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:banner] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error) {
                    //DLog(@"an error occured set og image path: %@", error);
                    if ([currentItem respondsToSelector:@selector(originalImagePath)]){
                        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[currentItem valueForKey:@"originalImagePath"]] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates];
                    }
                }
            }];
        }
        
    } else {
        cell.bottomRightLabel.text = currentItem.duration;
        cell.bannerLabel.text = @"";
        cell.bannerDescription.text = @"";
        NSString *icon = [currentItem.imagePath stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        if ([KBShelfViewController useRoundedEdges]) {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:icon] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates | SDWebImageAvoidAutoSetImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                
                if (!CGSizeEqualToSize(currentSize, image.size)) {
                    image = [image scaledImagedToSize:currentSize];
                }
                //DLog(@"standard %@ section size: %@ vs: %@ ratio: %.5f", currentItem.title, NSStringFromCGSize(currentSize), NSStringFromCGSize(image.size), image.aspectRatio);
                cell.imageView.image = [image sd_roundedCornerImageWithRadius:20.0 corners:UIRectCornerAllCorners borderWidth:0 borderColor:nil];
            }];
        } else {
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:icon] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                if (error) {
                    //DLog(@"an error occured with: %@ set og image path: %@", icon, [currentItem valueForKey:@"originalImagePath"]);
                    if ([currentItem respondsToSelector:@selector(originalImagePath)]){
                        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[currentItem valueForKey:@"originalImagePath"]] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates];
                    }
                }
            }];
            //[cell.imageView sd_setImageWithURL:[NSURL URLWithString:icon] placeholderImage:self.placeholderImage options:SDWebImageAllowInvalidSSLCertificates];
        }
    }
    
    return cell;
}

#pragma mark - UIScrollViewDelegate Methods

/*
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    DLOG_SELF;
    if ([scrollView isKindOfClass:UICollectionView.class]) {
        DLog(@"velocity: %@ targetContentOffset: %@", NSStringFromCGPoint(velocity), NSStringFromCGPoint(*targetContentOffset));
        CGPoint tco = *targetContentOffset;
        if (tco.x == -80) {
            //DLog(@"do things");
            //targetContentOffset->x = 0;
        }
    } else {
        DLog(@"diff scroll view: %@", scrollView);
        DLog(@"velocity: %@ targetContentOffset: %@", NSStringFromCGPoint(velocity), NSStringFromCGPoint(*targetContentOffset));
    }
}
*/
- (void)scrollViewWillSnapNavigationBar:(UIScrollView *)scrollView {
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (![scrollView isKindOfClass:[UICollectionView class]]) return;
    UICollectionView *collectionView = (UICollectionView *)scrollView;
    KBSection *section = self.sections[collectionView.section];
    if (section.sectionType == SectionTypeBanner){
        return;
    }
    CGFloat horizontalOffset = scrollView.contentOffset.x;
    NSInteger index = collectionView.section;
    //DLog(@"indexPath: %@", collectionView.indexPath);
    self.contentOffsetDictionary[[@(index) stringValue]] = @(horizontalOffset);
}

@end
