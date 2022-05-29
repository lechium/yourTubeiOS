//
//  TYHomeViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//

#import "TYHomeViewController.h"

@interface TYHomeViewController () {
    BOOL firstLoad;
}
@end

@implementation TYHomeViewController

- (id)initWithSections:(NSArray *)sections andChannelIDs:(NSArray *)channelIds
{
    
    self = [super initWithSections:sections];
    self.channelIDs = channelIds;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self refreshDataWithProgress:false];
    firstLoad = true;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (firstLoad){
        [self refreshDataWithProgress:true];
        firstLoad = false;
    } else {
        [self refreshDataWithProgress:false];
    }
}

- (void)getNextPage:(KBYTChannel *)currentChannel inCollectionView:(UICollectionView *)cv {
    NSLog(@"[tuyu] currentChannel.continuationToken: %@", currentChannel.continuationToken);
    [[KBYourTube sharedInstance] getChannelVideosAlt:currentChannel.channelID continuation:currentChannel.continuationToken completionBlock:^(KBYTChannel *channel) {
        if (channel.videos.count > 0){
            NSLog(@"[tuyu] got more channels!");
            [currentChannel mergeChannelVideos:channel];
            dispatch_async(dispatch_get_main_queue(), ^{
                [cv reloadData];//[self reloadCollectionViews];
            });
        }
    } failureBlock:^(NSString *error) {
        
    }];
}
/*
- (void)focusedCell:(YTTVStandardCollectionViewCell *)focusedCell {
    [super focusedCell:focusedCell];
    UICollectionView *cv = (UICollectionView*)[focusedCell superview];
    //if it isnt a collectionView or it IS the top collection view we dont do any adjustments
    if (![cv isKindOfClass:[UICollectionView class]] || cv == self.featuredVideosCollectionView )
    {
        return;
    }
    KBYTChannel *currentChannel = [self channelForCollectionView:cv];
    NSIndexPath *indexPath = [cv indexPathForCell:focusedCell];
    if (indexPath.row+1 == currentChannel.videos.count){
        NSLog(@"[tuyu] get a new page maybe?");
        [self getNextPage:currentChannel inCollectionView:cv];
    }
}
 */

- (void)refreshDataWithProgress:(BOOL)progress
{
    if (progress == true)
    {
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    }
    //get the user details to populate these views with
    [self fetchChannelDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress == true)
            {      [SVProgressHUD dismiss]; }
            self.playlistDictionary = finishedDetails;
            [super reloadCollectionViews];
        });
        
    }];
}

//@"UCByOQJjav0CUDwxCk-jVNRQ"
- (void)fetchChannelDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock
{
    NSMutableDictionary *channels = [NSMutableDictionary new];
    [[KBYourTube sharedInstance] getChannelVideos:@"UCByOQJjav0CUDwxCk-jVNRQ" completionBlock:^(KBYTChannel *channel) {
        self.featuredVideos = channel.videos;
        [[self featuredVideosCollectionView] reloadData];
    } failureBlock:^(NSString *error) {
        
    }];
    /*
    [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
        
        self.featuredVideos = searchDetails[@"results"];
        [[self featuredVideosCollectionView] reloadData];
        
        
    } failureBlock:^(NSString *error) {
        
    }];*/
    //return;
    //NSArray *results = userDetails[@"results"];
    NSInteger channelCount = [self.sectionLabels count];
    
    //since blocks are being used to fetch the data need to keep track of indices so we know
    //when to call completionBlock
    
    __block NSInteger currentIndex = 0;
    for (NSString *result in self.channelIDs)
    {
        [[KBYourTube sharedInstance] getChannelVideosAlt:result completionBlock:^(KBYTChannel *searchDetails) {
            
            NSString *title = searchDetails.title ? searchDetails.title : self.sectionLabels[currentIndex];
            NSLog(@"[tuyu] searchDetails title: %@ details:%@", title, searchDetails.continuationToken);
            if (searchDetails.videos){
                channels[title] = searchDetails;
            }
            currentIndex++;
            if (currentIndex >= channelCount)
            {
               completionBlock(channels);
            }
            //
        } failureBlock:^(NSString *error) {
            
            //
        }];
        
        
    }
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
