#import "KBAVInfoPanelSubtitlesViewController.h"

@implementation KBAVInfoPanelSubtitlesViewController

- (id)initWithItems:(NSArray *)subtitleItems {
    self = [super init];
    if (self){
        _subtitleCollectionViewController = [KBAVInfoPanelSubtitleCollectionViewController new];
        _subtitleCollectionViewController.mediaOptions = subtitleItems;
        _subtitleItems = subtitleItems;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view layoutIfNeeded];
    [self addChildViewController:_subtitleCollectionViewController];
    [self.view addSubview:_subtitleCollectionViewController.view];
    [self didMoveToParentViewController:_subtitleCollectionViewController];
    _contentView = self.view;
    _subtitleCollectionViewController.collectionView.delegate = self;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _selectedSubtitleOptionIndex = indexPath.row;
    _subtitleCollectionViewController.selectedMediaOptionIndex = indexPath.row;
    if (_delegate){
        KBAVInfoPanelMediaOption *subtitleItem = self.subtitleItems[indexPath.row];
        [subtitleItem setIsSelected:true];
        [_delegate viewController:self didSelectSubtitleOption:subtitleItem];
        [_subtitleCollectionViewController.collectionView reloadData];
    }
}

@end
