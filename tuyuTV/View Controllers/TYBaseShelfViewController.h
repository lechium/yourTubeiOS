//
//  TYBaseShelfViewController.h
//  tuyuTV
//
//  Created by js on 9/28/24.
//

#import "KBShelfViewController.h"
#import "KBSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface TYBaseShelfViewController : KBShelfViewController

@property (nonatomic, strong) void (^alertHandler)(UIAlertAction *action);
@property (nonatomic, strong) void (^channelAlertHandler)(UIAlertAction *action);

- (id)initWithSections:(NSArray <KBSectionProtocol>*)sections;
- (void)handleChannelSection:(KBSection *)section completion:(void(^)(BOOL loaded, NSString *error))completionBlock;
- (void)showChannelAlertForSearchResult:(KBYTSearchResult *)result;
- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result;
- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist;
- (void)promptForNewPlaylistForVideo:(KBYTSearchResult *)searchResult;
- (void)showFailureAlert:(NSString *)error;
- (void)showChannel:(KBYTSearchResult *)searchResult;
- (void)showPlaylist:(NSString *)videoID named:(NSString *)name;
- (void)goToChannelOfResult:(KBYTSearchResult *)searchResult;
- (void)getNextPage:(KBYTChannel *)currentChannel inCollectionView:(UICollectionView *)cv;
- (void)handleSelectVideo:(KBYTSearchResult *)video inSection:(NSInteger)section atIndex:(NSInteger)row;
- (void)playAllSearchResults:(NSArray *)searchResults;
- (NSString *)cacheFile;
- (void)snapshotResults;
- (BOOL)loadFromSnapshot;
- (void)setupBlocks;
- (void)loadDataWithProgress:(BOOL)progress loadingSnapshot:(BOOL)loadingSnapshot completion:(void(^)(BOOL loaded))completionBloc;
@end

NS_ASSUME_NONNULL_END
