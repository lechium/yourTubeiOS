//
//  FirstViewController.m
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import "FirstViewController.h"
#import "YTTVFeaturedCollectionViewCell.h"
#import "YTTVStandardCollectionViewCell.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

@synthesize reuseFeatureID, reuseStandardID;

- (void)viewDidLoad {
    
    self.reuseFeatureID = @"FeaturedCell";
    self.reuseStandardID = @"StandardCell";
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidLayoutSubviews
{
    self.scrollView.contentSize = CGSizeMake(1920, 2220);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 50;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.0, 50.0, 0.0, 50.0);
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (collectionView == self.collectionView1)
    {
        return 8;
    } else {
        return 10;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == self.collectionView1)
    {
        YTTVFeaturedCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseFeatureID forIndexPath:indexPath];
        NSString *imageFileName = [NSString stringWithFormat:@"feature-%li.jpg", indexPath.row];
        cell.featuredImage.image = [UIImage imageNamed:imageFileName];
        return cell;
    }
    
    if (collectionView == self.collectionView2)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        NSString *imageFileName = [NSString stringWithFormat:@"movie-%li.jpg", indexPath.row];
        cell.image.image = [UIImage imageNamed:imageFileName];
        cell.title.text = @"Movie Title";
        return cell;
    }
    
    if (collectionView == self.collectionView2)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        NSString *imageFileName = [NSString stringWithFormat:@"movie-%li.jpg", indexPath.row];
        cell.image.image = [UIImage imageNamed:imageFileName];
            cell.title.text = @"Movie Title";
        return cell;
    }
    
    if (collectionView == self.collectionView3)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        
        NSInteger fileNumber = indexPath.row + 10;
        NSString *imageFileName = [NSString stringWithFormat:@"movie-%li.jpg", fileNumber];
        cell.image.image = [UIImage imageNamed:imageFileName];
            cell.title.text = @"Movie Title";
        return cell;
    }
    
    if (collectionView == self.collectionView4)
    {
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseStandardID forIndexPath:indexPath];
        
        NSInteger fileNumber = 19 - indexPath.row;
        NSString *imageFileName = [NSString stringWithFormat:@"movie-%li.jpg", fileNumber];
        cell.image.image = [UIImage imageNamed:imageFileName];
            cell.title.text = @"Movie Title";
        return cell;
    }
    
    return [[UICollectionViewCell alloc] init];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
