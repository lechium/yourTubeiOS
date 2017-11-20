//
//  TYAuthUserManager.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
//

#import "AFNetworking.h"
#import <Foundation/Foundation.h>
#import "WebViewController.h"
#import "AFOAuthCredential.h"
#import "AFOAuth2Manager.h"

@interface TYAuthUserManager : AFHTTPSessionManager

+ (NSString *)suastring;
- (void)checkAndSetCredential;
+ (NSString *)ytAuthURL;
+ (WebViewController *)ytAuthWebViewController;
+ (WebViewController *)OAuthWebViewController;
+ (id)sharedInstance;
- (id)postOAuth2CodeToGoogle:(NSString *)code;
- (void)postOAuth2CodeToGoogle:(NSString *)code completion:(void(^)(NSString *value))block;
- (id)refreshAuthToken;
- (NSArray *)playlists;
- (id)unSubscribeFromChannel:(NSString *)subscriptionID;
- (id)subscribeToChannel:(NSString *)channelId;
- (id)removeVideo:(NSString *)videoID FromPlaylist:(NSString *)favoriteID;
- (id)deletePlaylist:(NSString *)playlistID;
- (id)createPlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus;
- (id)addVideo:(NSString *)videoID toPlaylistWithID:(NSString *)playlistID;
- (void)setCredential:(AFOAuthCredential *)credential;
@end
