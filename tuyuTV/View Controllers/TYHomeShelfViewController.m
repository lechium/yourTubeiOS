//
//  TYHomeShelfViewController.m
//  tuyuTV
//
//  Created by js on 9/22/24.
//

#import "TYHomeShelfViewController.h"
#import "SVProgressHUD.h"
#import "KBYTGridChannelViewController.h"
#import "YTTVPlaylistViewController.h"
#import "KBYTQueuePlayer.h"
#import "YTTVPlayerViewController.h"

@interface TYHomeShelfViewController ()

@property (nonatomic, strong) YTTVPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;

@end

@implementation TYHomeShelfViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (id)initWithSections:(NSArray <KBSectionProtocol>*)sections {
    self = [super init];
    self.sections = sections;
    self.itemSelectedBlock = ^(id<KBCollectionItemProtocol>  _Nonnull item, BOOL longPress, NSInteger row, NSInteger section) {
        KBYTSearchResult *searchResult = (KBYTSearchResult *)item;
        DLog(@"item selected block: %@ long: %d", item, longPress);
        switch (searchResult.resultType) {
            case kYTSearchResultTypeChannel:
                [self showChannel:searchResult];
                break;
            case kYTSearchResultTypePlaylist:
                [self showPlaylist:searchResult.videoId named:item.title];
                break;
            case kYTSearchResultTypeVideo:
                [self handleSelectVideo:searchResult inSection:section atIndex:row];
                break;
        }
    };
    self.itemFocusedBlock = ^(NSInteger row, NSInteger section, UICollectionView * _Nonnull collectionView) {
        DLog(@"item focused: %lu in section: %lu", row,section);
    };
    return self;
}

- (void)handleSelectVideo:(KBYTSearchResult *)video inSection:(NSInteger)section atIndex:(NSInteger)row {
    KBSection *mySection = self.sections[section];
    DLog(@"section: %lu row: %lu content count: %lu",section, row,[mySection.content count]);
    NSArray *subarray = [mySection.content subarrayWithRange:NSMakeRange(row, [mySection.content count] - row)];
          [self playAllSearchResults:subarray];
}

- (void)playAllSearchResults:(NSArray *)searchResults {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:@[[searchResults firstObject]] completionBlock:^(NSArray *videoArray) {
        
        [SVProgressHUD dismiss];
        self.playerView = [[YTTVPlayerViewController alloc] initWithFrame:self.view.frame usingStreamingMediaArray:searchResults];
        [self.playerView addObjectsToPlayerQueue:videoArray];
        [self presentViewController:self.playerView animated:YES completion:nil];
        [[self.playerView player] play];
        NSArray *subarray = [searchResults subarrayWithRange:NSMakeRange(1, searchResults.count-1)];
        
        NSDate *myStart = [NSDate date];
        [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:subarray completionBlock:^(NSArray *videoArray) {
            
            //TLog(@"video details fetched in %@", [myStart timeStringFromCurrentDate]);
            //TLog(@"first object: %@", subarray.firstObject);
            [self.playerView addObjectsToPlayerQueue:videoArray];
            
        } failureBlock:^(NSString *error) {
            
            [SVProgressHUD dismiss];
            DLog(@"failed?");
            //[self showFailureAlert:error];
        }];
        
        
    } failureBlock:^(NSString *error) {
        [SVProgressHUD dismiss];
         DLog(@"failed?");
        //[self showFailureAlert:error];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self firstLoad]) {
        [self loadDataWithProgress:true loadingSnapshot:true completion:^(BOOL loaded) {
            DLog(@"loaded: %d", loaded);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self handleSectionsUpdated];
            });
        }];
    }
}

- (NSString *)homeCacheFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"newhome.plist"];
}

- (void)snapshotResults {
    NSArray *sections = [self.sections convertArrayToDictionaries];
    [sections writeToFile:[self homeCacheFile] atomically:true];
}

- (BOOL)loadFromSnapshot {
    if (![FM fileExistsAtPath:[self homeCacheFile]]){
        return false;
    }
    NSArray *sects = [NSArray arrayWithContentsOfFile:[self homeCacheFile]];
  
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sections = [sects convertArrayToObjects];
    });
    return (self.sections.count > 0);
}


- (void)showPlaylist:(NSString *)videoID named:(NSString *)name {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getPlaylistVideos:videoID completionBlock:^(KBYTPlaylist *playlist) {
        
        [SVProgressHUD dismiss];
        YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerForPlaylist:playlist backgroundColor:[UIColor blackColor]];

        [self presentViewController:playlistViewController animated:YES completion:nil];
        
    } failureBlock:^(NSString *error) {
    }];
}

- (void)showChannel:(KBYTSearchResult *)searchResult {
    
    KBYTGridChannelViewController *cv = [[KBYTGridChannelViewController alloc] initWithChannelID:searchResult.videoId];
    [self presentViewController:cv animated:true completion:nil];
}

- (void)loadDataWithProgress:(BOOL)progress loadingSnapshot:(BOOL)loadingSnapshot completion:(void(^)(BOOL loaded))completionBlock {
    
    if (loadingSnapshot) {
        [self loadFromSnapshot];
        progress = false;
    }
    
    __block NSInteger loadedSections = 0;
    if (progress) {
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    }
    [self.sections enumerateObjectsUsingBlock:^(KBSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DLog(@"section: %@", obj);
        DLog(@"section type: %u channel type: %lu", obj.sectionResultType, kYTSearchResultTypeChannel);
        if ([obj sectionResultType] == kYTSearchResultTypeChannel) {
            [[KBYourTube sharedInstance] getChannelVideosAlt:obj.uniqueId completionBlock:^(KBYTChannel *channel) {
                obj.channel = channel;
                obj.content = [channel allSectionItems];
                if (loadedSections == self.sections.count-1){
                    if (progress) {
                        [SVProgressHUD dismiss];
                    }
                    [self snapshotResults];
                    if (completionBlock){
                        completionBlock(true);
                    }
                }
                loadedSections++;
                DLog(@"loaded sections: %lu section count: %lu", loadedSections, self.sections.count);
                
            } failureBlock:^(NSString *error) {
                DLog(@"failed to load channel details: %@ error: %@", obj, error);
                loadedSections++;
                if (loadedSections == self.sections.count-1){
                    [SVProgressHUD dismiss];
                    if (completionBlock){
                        completionBlock(false);
                    }
                }
            }];
        }
    }];
}

@end
