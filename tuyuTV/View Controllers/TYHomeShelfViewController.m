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
#import "EXTScope.h"
#import "TYAuthUserManager.h"

@interface TYHomeShelfViewController () {
    BOOL _homeDataChanged;
}

@property (nonatomic, strong) YTTVPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;

@end

@implementation TYHomeShelfViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _homeDataChanged = false;
    [self listenForHomeNotification];
}

- (id)initWithSections:(NSArray <KBSectionProtocol>*)sections {
    self = [super init];
    self.sections = sections;
    @weakify(self);
    self.itemSelectedBlock = ^(id<KBCollectionItemProtocol>  _Nonnull item, BOOL longPress, NSInteger row, NSInteger section) {
        KBYTSearchResult *searchResult = (KBYTSearchResult *)item;
        BOOL isSignedIn = [[KBYourTube sharedInstance] isSignedIn];
        DLog(@"item selected block: %@ long: %d", item, longPress);
        switch (searchResult.resultType) {
            case kYTSearchResultTypeChannel:
                if (longPress) {
                    if (isSignedIn) {
                        [self showChannelAlertForSearchResult:searchResult];
                    }
                } else {
                    [self_weak_ showChannel:searchResult];
                }
                break;
            case kYTSearchResultTypePlaylist:
                if (longPress) {
                    if (isSignedIn) {
                        [self showChannelAlertForSearchResult:searchResult];
                    }
                } else {
                    [self_weak_ showPlaylist:searchResult.videoId named:item.title];
                }
                break;
            case kYTSearchResultTypeVideo:
                if (longPress) {
                    if (isSignedIn) {
                        [self showPlaylistAlertForSearchResult:searchResult];
                    }
                } else {
                    [self_weak_ handleSelectVideo:searchResult inSection:section atIndex:row];
                }
                break;
            
            default:
                TLog(@"unhandled result type: %lu", searchResult.resultType);
                break;
        }
    };
    
    self.itemFocusedBlock = ^(NSInteger row, NSInteger section, UICollectionView * _Nonnull collectionView) {
        //DLog(@"item focused: %lu in section: %lu", row,section);
        KBSection *currentSection = self_weak_.sections[section]; //TODO: crash proof with categories
        KBYTChannel *channel = currentSection.channel;
        //DLog(@"channel: %@", channel);
        if (channel.continuationToken) {
            //DLog(@"channel has continuation token: %@", channel.continuationToken);
            if (row+1 == channel.allSectionItems.count) {
                TLog(@"get a new page maybe?");
                [self_weak_ getNextPage:channel inCollectionView:collectionView];
            }
        }
    };
    return self;
}
/*
 
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
 
 */


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

- (void)listenForHomeNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeDataChanged:) name:KBYTHomeDataChangedNotification object:nil];
}

- (void)homeDataChanged:(NSNotification *)n {
    _homeDataChanged = true;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self topViewController] == self) {
            [self loadDataWithProgress:true loadingSnapshot:false completion:^(BOOL loaded) {
                [self handleSectionsUpdated];
            }];
            _homeDataChanged = false;
        }
    });
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
        self.sections = (NSArray<KBSectionProtocol> *)[sects convertArrayToObjects];
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

- (void)showFailureAlert:(NSString *)error {
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:@"An error occured" message:error preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"D'oh" style:UIAlertActionStyleCancel handler:nil];
    [alertCon addAction:okAction];
    [self presentViewController:alertCon animated:YES completion:nil];
    
}

- (void)promptForNewPlaylistForVideo:(KBYTSearchResult *)searchResult {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"New Playlist"
                                          message: @"Enter the name for your new playlist"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.placeholder = @"Playlist Name";
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    UIAlertAction *createPrivatePlaylist = [UIAlertAction
                                            actionWithTitle:@"Create private playlist"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                                            {
                                                NSString *playlistName = alertController.textFields[0].text;
                                                KBYTSearchResult *playlistItem =  [[TYAuthUserManager sharedInstance] createPlaylistWithTitle:playlistName andPrivacyStatus:@"private"];
                                                NSLog(@"playlist created?: %@", playlistItem);
                                                NSString *plID = playlistItem.videoId;
                                                [self addVideo:searchResult toPlaylist:plID];
                                            }];
    
    
    UIAlertAction *createPublicPlaylist = [UIAlertAction
                                           actionWithTitle:@"Create public playlist"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
                                               NSString *playlistName = alertController.textFields[0].text;
                                               KBYTSearchResult *playlistItem =  [[TYAuthUserManager sharedInstance] createPlaylistWithTitle:playlistName andPrivacyStatus:@"public"];
                                               if (playlistItem != nil)
                                               {
                                                   NSLog(@"playlist created?: %@", playlistItem);
                                                   NSString *plID = playlistItem.videoId;
                                                   
                                                   [self addVideo:searchResult toPlaylist:plID];
                                               }
                                           }];
    
    
    [alertController addAction:createPrivatePlaylist];
    [alertController addAction:createPublicPlaylist];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist {
    DLog(@"add video: %@ to playlistID: %@", video, playlist);
    [[TYAuthUserManager sharedInstance] addVideo:video.videoId toPlaylistWithID:playlist];
}

- (void)goToChannelOfResult:(KBYTSearchResult *)searchResult {
    TLog(@"searchResult: %@", searchResult.channelId);
    if (!searchResult.channelId) {
        TLog(@"searchResult: %@", searchResult);
        return;
    }
    KBYTGridChannelViewController *cv = [[KBYTGridChannelViewController alloc] initWithChannelID:searchResult.channelId];
    [self presentViewController:cv animated:true completion:nil];
}


- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Video Options"
                                          message: @"Choose playlist to add video to"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    NSArray *playlistArray = [[TYAuthUserManager sharedInstance] playlists];
    
    
    __weak typeof(self) weakSelf = self;
    self.alertHandler = ^(UIAlertAction *action) {
        NSString *playlistID = nil;
        
        for (KBYTSearchResult *result in playlistArray)
        {
            if ([result.title isEqualToString:action.title])
            {
                playlistID = result.videoId;
            }
        }
        
        [weakSelf addVideo:result toPlaylist:playlistID];
    };
    
    for (KBYTSearchResult *result in playlistArray) {
        UIAlertAction *plAction = [UIAlertAction actionWithTitle:result.title style:UIAlertActionStyleDefault handler:self.alertHandler];
        [alertController addAction:plAction];
    }
    
    UIAlertAction *newPlAction = [UIAlertAction actionWithTitle:@"Create new playlist" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self promptForNewPlaylistForVideo:result];
        
    }];
    [alertController addAction:newPlAction];
    UIAlertAction *goToChannel = [UIAlertAction actionWithTitle:@"Go To Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self goToChannelOfResult:result];
    }];
    [alertController addAction:goToChannel];
    if ([[KBYourTube sharedInstance] isSignedIn]) {
        UIAlertAction *subToChannel = [UIAlertAction actionWithTitle:@"Subscribe To Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [[TYAuthUserManager sharedInstance] subscribeToChannel:result.channelId];
            });
        }];
        [alertController addAction:subToChannel];
    }
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    
    
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}

- (void)showChannelAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Channel Options"
                                          message: @"Subscribe to this channel?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[TYAuthUserManager sharedInstance] subscribeToChannel:result.videoId];
        });
        
    }];
    [alertController addAction:yesAction];
    UIAlertAction *homeScreenAction = [UIAlertAction actionWithTitle:@"Add to Home screen" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[KBYourTube sharedInstance] addHomeSection:result];
        });
        
    }];
    [alertController addAction:homeScreenAction];
    
    UIAlertAction *featuredAction = [UIAlertAction actionWithTitle:@"Set as Featured channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[KBYourTube sharedInstance] setFeaturedResult:result];
        });
        
    }];
    [alertController addAction:featuredAction];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
   
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
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

- (void)handleChannelSection:(KBSection *)section completion:(void(^)(BOOL loaded, NSString *error))completionBlock {
    [[KBYourTube sharedInstance] getChannelVideosAlt:section.uniqueId completionBlock:^(KBYTChannel *channel) {
        section.channel = channel;
        section.content = [channel allSectionItems];
        if (completionBlock){
            completionBlock(true, nil);
        }
    } failureBlock:^(NSString *error) {
        if (completionBlock){
            completionBlock(false, error);
        }
    }];
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
        switch ([obj sectionResultType]) {
            case kYTSearchResultTypeChannel:
                [self handleChannelSection:obj completion:^(BOOL loaded, NSString *error) {
                    BOOL finished = loadedSections == self.sections.count-1;
                    if (finished || loadedSections > 3){
                        if (progress && finished) {
                            [SVProgressHUD dismiss];
                        }
                        if (finished){
                            [self snapshotResults];
                        }
                        if (completionBlock){
                            completionBlock(true);
                        }
                    }
                    loadedSections++;
                }];
                break;
        }
    }];
}

@end
