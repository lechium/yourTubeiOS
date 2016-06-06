//
//  TYAuthUserManager.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
//

#import <Foundation/Foundation.h>
#import "WebViewController.h"

@interface TYAuthUserManager : NSObject

+ (WebViewController *)OAuthWebViewController;
+ (id)sharedInstance;
- (id)postOAuth2CodeToGoogle:(NSString *)code;
- (id)refreshAuthToken;
- (NSArray *)playlists;
- (id)unSubscribeFromChannel:(NSString *)subscriptionID;
- (id)subscribeToChannel:(NSString *)channelId;
- (id)removeVideo:(NSString *)videoID FromPlaylist:(NSString *)favoriteID;
- (id)deletePlaylist:(NSString *)playlistID;
- (id)createPlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus;
- (id)addVideo:(NSString *)videoID toPlaylistWithID:(NSString *)playlistID;
@end
