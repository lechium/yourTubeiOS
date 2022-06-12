#import "KBAVInfoPanelMediaOptionCollectionViewController.h"
#import "KBAVInfoPanelCollectionViewTextCell.h"
#import "UIView+AL.h"

@implementation KBAVInfoPanelMediaOptionCollectionViewController

- (void)setSelectedMediaOptionIndex:(long long)selectedMediaOptionIndex {
    _selectedMediaOptionIndex = selectedMediaOptionIndex;
    [self.mediaOptions enumerateObjectsUsingBlock:^(KBAVInfoPanelMediaOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == selectedMediaOptionIndex) {
            [obj setIsSelected:true];
        } else {
            [obj setIsSelected:false];
        }
    }];
}

- (long long)selectedMediaOptionIndex {
    return _selectedMediaOptionIndex;
}

- (void)loadView {
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal; //CGRectMake(0, 0, 659, 35)
    layout.itemSize = CGSizeMake(80,35);
    layout.minimumLineSpacing = 80;
    UICollectionView *cl = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    cl.translatesAutoresizingMaskIntoConstraints = false;
    self.widthConstraint = [cl.widthAnchor constraintEqualToConstant:470];
    self.widthConstraint.active = true;
    [cl.heightAnchor constraintEqualToConstant:35].active = true;
    self.collectionView = cl;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerClass:KBAVInfoPanelCollectionViewTextCell.class forCellWithReuseIdentifier:@"cell"];
    [self.collectionView autoCenterHorizontallyInSuperview];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    //self.widthConstraint.constant = (_mediaOptions.count + 1) * layout.itemSize.width;
}

-  (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    KBAVInfoPanelCollectionViewTextCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    KBAVInfoPanelMediaOption *opt = [self mediaOptions][indexPath.row];
    cell.title = opt.displayName;
    [cell setSelected:opt.selected];
    return cell;
}

-(NSInteger)collectionView:(id)arg1 numberOfItemsInSection:(NSInteger)arg2 {
    return _mediaOptions.count;
}

- (void)setMediaOptions:(NSArray <KBAVInfoPanelMediaOption *>*)mediaOptions {
    _mediaOptions = mediaOptions;
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    CGFloat newConst = (_mediaOptions.count + 2) * layout.itemSize.width + 70; //70 is just extra padding
    //DLog(@"newconst: %f count: %lu width: %f", newConst, (_mediaOptions.count + 2), layout.itemSize.width);
    self.widthConstraint.constant = newConst;
    [self.collectionView reloadData];
}

- (NSArray <KBAVInfoPanelMediaOption *>*)mediaOptions {
    return _mediaOptions;
}

- (id)mediaOptionAtIndexPath:(NSIndexPath *)indexPath { //this is likely more useful when there are multiple rows of items like for audio
    return _mediaOptions[indexPath.row];
}

@end
