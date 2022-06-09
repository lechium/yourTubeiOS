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

- (id)initWithSections:(NSArray *)sections andChannelIDs:(NSArray *)channelIds {
    
    self = [super initWithSections:sections];
    self.channelIDs = channelIds;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self refreshDataWithProgress:false];
    firstLoad = true;
    self.title = @"tuyu";
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
    TLog(@"currentChannel.continuationToken: %@", currentChannel.continuationToken);
    [[KBYourTube sharedInstance] getChannelVideosAlt:currentChannel.channelID continuation:currentChannel.continuationToken completionBlock:^(KBYTChannel *channel) {
        if (channel.videos.count > 0){
            TLog(@"got more channels!");
            [currentChannel mergeChannelVideos:channel];
            dispatch_async(dispatch_get_main_queue(), ^{
                [cv reloadData];//[self reloadCollectionViews];
            });
        }
    } failureBlock:^(NSString *error) {
        
    }];
}

- (void)focusedCell:(YTTVStandardCollectionViewCell *)focusedCell {
    [super focusedCell:focusedCell];
    UICollectionView *cv = (UICollectionView*)[focusedCell superview];
    //if it isnt a collectionView or it IS the top collection view we dont do any adjustments
    if (![cv isKindOfClass:[UICollectionView class]] || cv == self.featuredVideosCollectionView ) {
        return;
    }
    KBYTChannel *currentChannel = [self channelForCollectionView:cv];
    if (!currentChannel.continuationToken) {
        return;
    }
    NSIndexPath *indexPath = [cv indexPathForCell:focusedCell];
    if (indexPath.row+1 == currentChannel.allSectionItems.count){
        TLog(@"get a new page maybe?");
        [self getNextPage:currentChannel inCollectionView:cv];
    }
}
 

- (void)refreshDataWithProgress:(BOOL)progress {
    LOG_CMD;
    if ([self loadFromSnapshot]) {
        progress = false;
    }
    if (progress == true) {
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
            [self snapshotResults];
        });
        
    }];
}

//@"UCByOQJjav0CUDwxCk-jVNRQ"
- (void)fetchChannelDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock {
    //
    NSMutableDictionary *channels = [NSMutableDictionary new];
    [[KBYourTube sharedInstance] getChannelVideosAlt:@"UCByOQJjav0CUDwxCk-jVNRQ" completionBlock:^(KBYTChannel *channel) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.featuredChannel = channel;
            self.featuredVideos = channel.allSectionItems;
            [[self featuredVideosCollectionView] reloadData];
        });
    } failureBlock:^(NSString *error) {
        
    }];

    NSInteger channelCount = [self.sectionLabels count];
    
    //since blocks are being used to fetch the data need to keep track of indices so we know
    //when to call completionBlock
    
    __block NSInteger currentIndex = 0;
    for (NSString *result in self.channelIDs) {
        [[KBYourTube sharedInstance] getChannelVideosAlt:result completionBlock:^(KBYTChannel *searchDetails) {
            
            NSString *title = searchDetails.title ? searchDetails.title : self.sectionLabels[currentIndex];
            //TLog(@"searchDetails title: %@ sections:%@", title, searchDetails.sections);
            if (searchDetails.sections){
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

- (NSString *)homeCacheFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"home.plist"];
}

- (void)snapshotResults {
    NSMutableDictionary *_newDict = [self.playlistDictionary convertObjectsToDictionaryRepresentations];
    //NSURL *url = [NSURL fileURLWithPath:[[self appSupportFolder] stringByAppendingPathComponent:@"home.plist"]];
    //NSError *error = nil;
    //[_newDict writeToURL:url error:&error];
    NSArray *featured = [self.featuredVideos convertArrayToDictionaries];
    if (featured){
        _newDict[@"featured"] = featured;
    }
    [_newDict writeToFile:[self homeCacheFile] atomically:true];
}

- (BOOL)loadFromSnapshot {
    if (![FM fileExistsAtPath:[self homeCacheFile]]){
        return false;
    }
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[self homeCacheFile]];
    __block NSMutableDictionary *newPlDict = [NSMutableDictionary new];
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"featured"]){
            NSArray *featured = (NSArray *)obj;
            NSMutableArray *newFeatured = [NSMutableArray new];
            [featured enumerateObjectsUsingBlock:^(id  _Nonnull fObj, NSUInteger fIdx, BOOL * _Nonnull fStop) {
                id featuredObj = [NSObject objectFromDictionary:fObj];
                [newFeatured addObject:featuredObj];
            }];
            self.featuredVideos = newFeatured;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.featuredVideosCollectionView reloadData];
                [self reloadCollectionViews];
            });
        } else {
            id newObject = [NSObject objectFromDictionary:obj];
            newPlDict[key] = newObject;
        }
        
    }];
    self.playlistDictionary = newPlDict;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadCollectionViews];
    });
    return (self.playlistDictionary.allKeys.count > 0);
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
