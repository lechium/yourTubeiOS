//
//  TYAuthUserManager.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
//

#import "AFNetworking.h"
#import <Foundation/Foundation.h>
/*
#if TARGET_OS_TV
#import "WebViewController.h"
#endif
*/
#if TARGET_OS_IOS
#import "KBYTWebViewController.h"
#endif

#import "AFOAuthCredential.h"
#import "AFOAuth2Manager.h"

@class KBYTSearchResult, KBYTPlaylist, KBYTChannel;

typedef void (^AuthStateUpdatedBlock) (NSString *authState);
typedef void (^PurchaseValidatedBlock)(BOOL success, NSString *message);
typedef void (^FinishedBlock)(NSDictionary *tokenDict, NSError *error);
typedef void (^DeviceCodeBlock)(NSDictionary *deviceCodeDict);

@interface TYAuthUserManager : AFHTTPSessionManager

@property (readwrite, assign) BOOL authorized;

+ (NSString *)suastring;
- (BOOL)checkAndSetCredential;
- (void)signOut;
+ (NSString *)ytAuthURL;
- (NSArray *)subbedChannelIDs;
- (BOOL)isSubscribedToChannel:(NSString *)channelID;
#if TARGET_OS_IOS
+ (KBYTWebViewController *)ytAuthWebViewController;
- (void)createAndStartWebserverWithCompletion:(void(^)(BOOL success))block;
+ (KBYTWebViewController *)OAuthWebViewController;
#endif
/*
#if TARGET_OS_TV
+ (WebViewController *)ytAuthWebViewController;
+ (WebViewController *)OAuthWebViewController;
#endif
 */

- (void)getProfileDetailsWithCompletion:(void(^)(NSDictionary *profileDetails, NSString *error))completionBlock;
- (void)getProfileThumbnail:(NSString *)profileID completion:(void(^)(NSString *thumbURL, NSString *error)) completionBlock;
- (void)getPlaylistsWithCompletion:(void(^)(NSArray <KBYTSearchResult *> *playlists, NSString *error))completionBlock;
- (void)getChannelListWithCompletion:(void(^)(NSArray <KBYTSearchResult *> *channels, NSString *error))completionBlock;
+ (id)sharedInstance;
- (void)postCodeToGoogle:(NSString *)code completion:(void(^)(NSDictionary *returnData))block;
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
- (void)copyPlaylist:(KBYTSearchResult *)result completion:(void(^)(NSString *response))completion;
- (void)getOAuthCodeWithCompletion:(void(^)(NSDictionary *codeDict))block;
- (void)startAuthAndGetUserCodeDetails:(DeviceCodeBlock)codeBlock completion:(FinishedBlock)finished;
- (id)setPosition:(NSInteger)position forSearchItem:(KBYTSearchResult *)searchItem inPlaylist:(NSString *)playlistID;
- (void)getPlaylistItems:(NSString *)playlistID completion:(void(^)(NSArray <KBYTSearchResult *> *channels, NSString *error))completionBlock;
@end
