//
//  TYAuthUserManager.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
// https://developers.google.com/youtube/v3/guides/auth/installed-apps#ios <-- for 'macOS' / desktop. just dont want to use their crap.


#import "TYAuthUserManager.h"
#import "YTCreds.h"
#import "KBYourTube.h"
#if TARGET_OS_IOS
#import <GCDWebServers/GCDWebServers.h>
#endif

@interface TYAuthUserManager() {
#if TARGET_OS_IOS
    GCDWebServer* _webServer;
#endif
}
@property (nonatomic, strong) NSDictionary *authResponse;
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) NSDate *startPollingTime;
@property (nonatomic, strong) NSDictionary *tokenData;
@property (nonatomic, strong) FinishedBlock finishedBlock;
@property (nonatomic, strong) PurchaseValidatedBlock purchaseBlock;
@property (nonatomic, strong) AuthStateUpdatedBlock updateBlock;

@end

@implementation TYAuthUserManager

#if TARGET_OS_TV
+ (WebViewController *)ytAuthWebViewController {
    WebViewController *webView = [[WebViewController alloc] initWithURL:[self ytAuthURL]];
    webView.viewMode = WebViewControllerAuthMode;
    return webView;
}

+ (WebViewController *)OAuthWebViewController {
    
    WebViewController *webView = [[WebViewController alloc] initWithURL:[self suastring]];
    webView.viewMode = WebViewControllerPermissionMode;
    return webView;
}

#endif

#if TARGET_OS_IOS
+ (KBYTWebViewController *)ytAuthWebViewController {
    KBYTWebViewController *webView = [[KBYTWebViewController alloc] initWithURL:[self ytAuthURL] mode:TYWebViewControllerAuthMode ];
    return webView;
}

+ (KBYTWebViewController *)OAuthWebViewController {
    
    KBYTWebViewController *webView = [[KBYTWebViewController alloc] initWithURL:[self suastring] mode:TYWebViewControllerPermissionMode];
    // webView.viewMode = TYWebViewControllerPermissionMode;
    return webView;
}

- (void)stopWebServer {
    [_webServer stop];
    _webServer = nil;
}

- (void)createAndStartWebserverWithCompletion:(void(^)(BOOL success))block {
    // Create server
      _webServer = [[GCDWebServer alloc] init];
      
    __weak __typeof(self) weakSelf = self;
      // Add a handler to respond to GET requests on any URL
      [_webServer addDefaultHandlerForMethod:@"GET"
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
          NSLog(@"request: %@", request);
          NSString *code = [request query][@"code"];
          if (code){
              NSLog(@"we gots a code bruh: %@", code);
              [weakSelf postCodeToGoogle:code completion:^(NSDictionary *returnData) {
                  NSLog(@"got data from code postage: %@", returnData);
                  [weakSelf stopWebServer];
                  if (block) {
                      block([[returnData allKeys] containsObject:@"access_token"]);
                  }
              }];
          }
        return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
        
      }];
      
      // Start server on port 8080
      [_webServer startWithPort:9004 bonjourName:nil];
}


#endif

+ (NSString *)ytAuthURL {
    return @"https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Fnext%3D%252F%26hl%3Den%26feature%3Dsign_in_button%26app%3Ddesktop%26action_handle_signin%3Dtrue&hl=en&passive=true&service=youtube&uilel=3";
}

+ (NSString *)suastring {
    return [[NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/v2/auth?scope=https://www.googleapis.com/auth/youtube&response_type=code&redirect_uri=http://127.0.0.1:9004&client_id=%@", ytClientID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)suastringold {
    return [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?client_id=%@&redirect_uri=%@", ytClientID, @"urn:ietf:wg:oauth:2.0:oob:auto&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube.force-ssl+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutubepartner&response_type=code&access_type=offline&pageId=none"];
}

- (void)stopTime {
    
    [self.pollingTimer invalidate];
    self.pollingTimer = nil;
}

/*
 {
 "device_code": "AH-1Ng1eBIAIiU3wptG_h_yQ4XU-jbxP7uroivmC-NsEzNH5snOR3yqZHJhe8qvC3O5O4yv_frm85avNus3ombjenIISAu1-sw",
 "user_code": "DGRH-XKCG",
 "expires_in": 1800,
 "interval": 5,
 "verification_url": "https://www.google.com/device"
 }
 */

/*
 NSURL *baseURL = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2"];
 
 
 AFOAuth2Manager *OAuth2Manager =
 [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
 clientID:ytClientID
 secret:ytSecretKey];
 */

#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

- (void)pollForToken {
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self.startPollingTime];
    NSLog(@"interval since start: %f", interval);
    NSInteger expiresTime = 900; //15 minutes
    if (interval > expiresTime) {
        
        [self stopTime];
        NSError *theError = [NSError errorWithDomain:@"com.nito.nitoTV4" code:2001 userInfo:nil];
        self.finishedBlock(nil,theError);
        return;
    }
    
    /*
     client_id=670004260779-f193lea0mkihris4cr8gi4qaek46c0kl.apps.googleusercontent.com&client_secret=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&device_code=AH-1Ng2uKm7Q6rhcdQCWUCCxjDLH9NS5gSWW9jB8xwYbE_bcSr_Vodl7WtCXk6cD8DEP8y9slleFxHEOFghVylHlZ0skKZAK8A&grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code
     */
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString *deviceCode = self.authResponse[@"device_code"];
    NSString *pollURL = @"https://oauth2.googleapis.com/token";
    NSString* post = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&device_code=%@&grant_type=%@",ytClientID, ytSecretKey, deviceCode,  [@"urn:ietf:params:oauth:grant-type:device_code" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // Encode post string
    NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    [request setHTTPMethod:@"POST"];
    [request setURL:[NSURL URLWithString:pollURL]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSURLResponse *theResponse = nil;
        NSError *theError  = nil;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&theError];
        if (returnData){
            NSDictionary *tokenResponse = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
            
            BOOL authorized = [[tokenResponse allKeys] containsObject:@"access_token"];
            if (!authorized){
                self.authorized = false;
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    /*
                     
                     "error": "authorization_pending",
                     "error_description": "Precondition Required"
                     
                     "access_token": "ya29.a0ARrdaM-ImfR0lSglbpcSDum_F3Xc63rLKfL9UtZ-LP8MmWliM0g3vcLcvwISFBWXYtdGUvHpiV4g-Gu7RPmXyiiYMwDPl8VMMk50Uz_FTXghQmLmgaN2HjQLyZFD3BwN6-M4N6KVY52V4gLdCCv0oxyUJLlD",
                     "expires_in": 3599,
                     "refresh_token": "1//06-oXZLuoysIgCgYIARAAGAYSNwF-L9IrVnd7cTPZcxuDerJI_7uBFc-lW3sfanDNK8-a2sKx0SiE-4Veed2ZdligxVq5aJCGkgI",
                     "scope": "https://www.googleapis.com/auth/youtube.readonly",
                     "token_type": "Bearer"
                     */
                    
                    NSString *refreshToken = [tokenResponse valueForKey:@"refresh_token"];
                    AFOAuthCredential *credential = [AFOAuthCredential credentialWithOAuthToken:[tokenResponse valueForKey:@"access_token"] tokenType:[tokenResponse valueForKey:@"token_type"]];
                    credential.refreshToken = refreshToken;
                    [AFOAuthCredential storeCredential:credential withIdentifier:@"default"];
                    //NSLog(@"[tuyu] token response: %@", tokenResponse);
                    //NSLog(@"[tuyu] credential: %@", credential);
                    //NSString *userId = tokenResponse[@"UserId"];
                    //[UD setValue:userId forKey:kNTVPortalAuthUserName];
                    self.tokenData = tokenResponse;
                    self.authorized = true;
                    self.finishedBlock(self.tokenData, nil);
                    [self stopTime];
                    
                });
                
            }
        } else {
            
            self.finishedBlock(nil, theError);
            NSLog(@"NO RETURN DATA!!, PROBABLY THROW ERROR HERE?");
            
        }
        
    });
    
    //NSLog(@"token response %@", tokenResponse);
    
    
}

- (void)startAuthPolling {
    
    //https://api.amazon.com/auth/o2/token
    
    self.startPollingTime = [NSDate date];
    
    [self pollForToken];
    NSInteger interval = 10;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:TRUE block:^(NSTimer * _Nonnull timer) {
            [self pollForToken];
        }];
    });
    
}

- (AFOAuthCredential *)defaultCredential {
    return [AFOAuthCredential retrieveCredentialWithIdentifier:@"default" accessGroup:nil];
}

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static TYAuthUserManager *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            
            //shared = [TYAuthUserManager new];
            NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            
            AFOAuthCredential * credential =  [AFOAuthCredential retrieveCredentialWithIdentifier:@"default" accessGroup:nil];
            
            
            
            NSString *token = [NSString stringWithFormat:@"Bearer %@", credential.accessToken];
            sessionConfiguration.HTTPAdditionalHeaders = @{@"Accept": @"application/json",
                                                           @"Accept-Language": @"en",
                                                           @"Authorization": token};
            
            
            shared = [[TYAuthUserManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.googleapis.com/youtube/v3/"] sessionConfiguration:sessionConfiguration];
            shared.responseSerializer = [AFJSONResponseSerializer serializer];
            shared.requestSerializer = [AFJSONRequestSerializer serializer];
            [shared checkAndSetCredential];
        });
    }
    
    return shared;
    
}

- (void)setCredential:(AFOAuthCredential *)credential {
    [self.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
}

//DELETE https://www.googleapis.com/youtube/v3/subscriptions?id=Y3ufRxVp116IMX8y_Gy1238MBhIUUSvzIfjGlLit6F0&key={YOUR_API_KEY}

- (id)unSubscribeFromChannel:(NSString *)subscriptionID {
    
    NSLog(@"[tuyu] unsubscribe with ID: %@", subscriptionID);
    
    [self refreshAuthToken];
    NSError* error;
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/subscriptions?id=%@&key=%@", subscriptionID, ytClientID];
    
    // Create URL request and set url, method, content-length, content-type, and body
    //resourceId
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[[self defaultCredential] accessToken]];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    //[request setURL:[NSURL URLWithString:@"https://gdata.youtube.com/feeds/api/users/default/favorites"]];
    [request setHTTPMethod:@"DELETE"];
    
    // [request addValue:[[DeviceAuth sharedDeviceAuth] signatureForRequest:request] forHTTPHeaderField:@"X-GData-Device"];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    NSLog(@"[tuyu] datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"[tuyu] status string: %@", returnString);
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    // NSLog(@"jsonDict: %@", jsonDict);
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    } else {
        
        
    }
    return @"Success";
    
}

- (void)copyPlaylist:(KBYTSearchResult *)result completion:(void(^)(NSString *response))completion {
    __block  KBYTSearchResult *plResult = [self createPlaylistWithTitle:result.title andPrivacyStatus:@"public"];
    
    [[KBYourTube sharedInstance] getPlaylistVideos:result.videoId completionBlock:^(KBYTPlaylist *playlistDetails) {
        
        // NSNumber *pageCount = playlistDetails[@"pageCount"];
        
        //DLog(@"details: %@", playlistDetails);
        
        
        NSArray <KBYTSearchResult *>*results = playlistDetails.videos;
        for (KBYTSearchResult *video in results)
        {
            [self addVideo:video.videoId toPlaylistWithID:plResult.videoId];
        }
        
        completion(@"science");
        
        
    } failureBlock:^(NSString *error) {
        //
    }];
}

/*
 
 curl \
 'https://youtube.googleapis.com/youtube/v3/subscriptions?part=snippet%2CcontentDetails&mine=true&key=[YOUR_API_KEY]' \
 --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
 --header 'Accept: application/json' \
 --compressed
 
 
 'https://youtube.googleapis.com/youtube/v3/playlists?part=snippet%2CcontentDetails&maxResults=25&mine=true&key=[YOUR_API_KEY]' \
 --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
 --header 'Accept: application/json' \
 --compressed
 
 */

- (void)getPlaylistsWithCompletion:(void(^)(NSArray <KBYTSearchResult *> *playlists, NSString *error))completionBlock {
    __block NSMutableArray *playlists = [NSMutableArray new];
    NSString *initialString = @"https://youtube.googleapis.com/youtube/v3/playlists?part=snippet%2CcontentDetails&mine=true&maxResults=50";
    [self genericGetCommand:initialString completion:^(NSDictionary *jsonResponse, NSString *error) {
        NSArray *items = jsonResponse[@"items"];
        [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            /*
             KBYTSearchResult *playlist = [KBYTSearchResult new];
             playlist.videoId = obj[@"id"];
             playlist.author = obj[@"snippet"][@"channelTitle"];
             playlist.channelId = obj[@"snippet"][@"channelId"];
             playlist.duration = [NSString stringWithFormat:@"%@ tracks", obj[@"contentDetails"][@"itemCount"]];
             playlist.title = [obj recursiveObjectForKey:@"title"];
             playlist.details = [obj recursiveObjectForKey:@"description"];
             playlist.imagePath = [obj recursiveObjectForKey:@"thumbnails"][@"high"][@"url"];
             playlist.resultType = kYTSearchResultTypePlaylist;
             playlist.continuationToken = obj[@"nextPageToken"]; */
            KBYTSearchResult *playlist = [[KBYTSearchResult alloc] initWithYTPlaylistDictionary:obj];
            //NSLog(@"[tuyu] playlist: %@", playlist);
            [playlists addObject:playlist];
        }];
        //NSLog(@"[tuyu] count: %lu %@", playlists.count, playlists);
        if (completionBlock) {
            completionBlock(playlists, error);
        }
        
        [jsonResponse writeToFile:@"/var/mobile/Library/Preferences/getPlaylists.plist" atomically:TRUE];
    }];
}

- (void)genericGetCommand:(NSString *)command completion:(void(^)(NSDictionary *jsonResponse, NSString *error))completionBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        id token = [self refreshAuthToken];
        //NSLog(@"[tuyu] refreshed token: %@", token);
        NSString *urlString = [NSString stringWithFormat:@"%@&key=%@", command, ytClientID];
        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
        
        AFOAuthCredential *cred = [AFOAuthCredential retrieveCredentialWithIdentifier:@"default"];
        NSString *authorization = [NSString stringWithFormat:@"Bearer %@",cred.accessToken];
        [request setValue:authorization forHTTPHeaderField:@"Authorization"];
        
        [request setHTTPMethod:@"GET"];
        
        NSHTTPURLResponse *theResponse = nil;
        
        NSError* error = nil;
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
        
        NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
        //NSLog(@"[tuyu] status string: %@", returnString);
        
        //JSON data
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
        //NSLog(@"[tuyu] jsonDict: %@", jsonDict);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([jsonDict valueForKey:@"error"] != nil) {
                if (completionBlock) {
                    completionBlock(nil, datString);
                }
                return;
            }
            //NSLog(@"jsonDict: %@", jsonDict);
            [jsonDict writeToFile:@"/var/mobile/Library/Preferences/genericGetCommand.plist" atomically:TRUE];
            if (completionBlock){
                completionBlock(jsonDict, nil);
            }
        });
        
    });
}

- (void)getChannelListWithCompletion:(void(^)(NSArray <KBYTSearchResult *> *channels, NSString *error))completionBlock {
    __block NSMutableArray *channels = [NSMutableArray new];
    NSString *initialString = @"https://youtube.googleapis.com/youtube/v3/subscriptions?part=snippet%2CcontentDetails&mine=true&maxResults=50";
    [self genericGetCommand:initialString completion:^(NSDictionary *jsonResponse, NSString *error) {
        NSArray *items = jsonResponse[@"items"];
        [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            /*KBYTSearchResult *channel = [KBYTSearchResult new];
             channel.videoId = [obj recursiveObjectForKey:@"resourceId"][@"channelId"];
             channel.channelId = obj[@"snippet"][@"channelId"];
             channel.title = [obj recursiveObjectForKey:@"title"];
             channel.details = [obj recursiveObjectForKey:@"description"];
             channel.imagePath = [obj recursiveObjectForKey:@"thumbnails"][@"high"][@"url"];
             channel.resultType = kYTSearchResultTypeChannel;
             channel.continuationToken = obj[@"nextPageToken"];
             //NSLog(@"[tuyu] channel: %@", channel);
             */
            KBYTSearchResult *channel = [[KBYTSearchResult alloc] initWithYTChannelDictionary:obj];
            [channels addObject:channel];
        }];
        //NSLog(@"[tuyu] count: %lu %@", channels.count, channels);
        if (completionBlock) {
            completionBlock(channels, error);
        }
        
        [jsonResponse writeToFile:@"/var/mobile/Library/Preferences/getChannelListResponse.plist" atomically:TRUE];
    }];
}

- (id)subscribeToChannel:(NSString *)channelId {
    
    NSString *channel = [[channelId stringByDeletingLastPathComponent] lastPathComponent];
    if (channel.length == 0) {
        channel = channelId;
    }
    //NSLog(@"[tuyu] subscribe to channel: %@", channel);
    //[self refreshAuthToken];
    NSMutableDictionary *finalDict = [[NSMutableDictionary alloc] init];
    NSDictionary *resourceId = [NSDictionary dictionaryWithObjectsAndKeys:@"youtube#channel", @"kind", channel, @"channelId", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:resourceId , @"resourceId", nil];
    [finalDict setObject:dict forKey:@"snippet"];
    
    //NSLog(@"[tuyu] finalDict: %@", finalDict);
    
    NSError* error = nil;
    
    // Encode post string
    NSData* postData = [NSJSONSerialization dataWithJSONObject:finalDict options:NSJSONWritingPrettyPrinted error:nil];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    //https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&key={YOUR_API_KEY}
    
    // Create URL request and set url, method, content-length, content-type, and body
    //resourceId
    //https://www.googleapis.com/youtube/v3/subscriptions
    
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/subscriptions?part=snippet&key=%@", ytClientID ];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    AFOAuthCredential *cred = [AFOAuthCredential retrieveCredentialWithIdentifier:@"default"];
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",cred.accessToken];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    //NSLog(@"[tuyu] status string: %@", returnString);
    
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    //NSLog(@"[tuyu] jsonDict: %@", jsonDict);
    if ([jsonDict valueForKey:@"error"] != nil) {
        return datString;
    }
    //NSLog(@"jsonDict: %@", jsonDict);
    //[jsonDict writeToFile:@"/var/mobile/Library/Preferences/channelSubscribeResponse.plist" atomically:TRUE];
    KBYTSearchResult *newChannel = [[KBYTSearchResult alloc] initWithYTChannelDictionary:jsonDict];
    //NSLog(@"[tuyu] new channel: %@", newChannel);
    [[KBYourTube sharedInstance] addChannelToUserDetails:newChannel];
    return jsonDict;
    
}

/*
 {
   "id": "YOUR_PLAYLIST_ITEM_ID",
   "snippet": {
     "playlistId": "YOUR_PLAYLIST_ID",
     "position": 1,
     "resourceId": {
       "kind": "youtube#video",
       "videoId": "YOUR_VIDEO_ID"
     }
   }
 }
 */

- (id)setPosition:(NSInteger)position forVideoID:(NSString *)videoID inPlaylist:(NSString *)playlistID {
    
    [self refreshAuthToken];
    NSError* error;
    
    // Create URL request and set url, method, content-length, content-type, and body
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&key=%@", ytClientID];
    
    //NSLog(@"urlString: %@", urlString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    NSDictionary *postDictionary = @{@"id": playlistID,
                                     @"snippet": @{@"playlistId": @"",
                                                   @"position": @(position)},
                                     @"resourceId": @{@"kind": @"youtube#video",
                                                      @"videoId": videoID
                                     }
                                     
    };
    NSLog(@"[tuyu] post: %@", postDictionary);
    //NSLog(@"postString: %@", [finalDict JSONString]);
    // Encode post string
    NSData* postData = [NSJSONSerialization dataWithJSONObject:postDictionary options:NSJSONWritingPrettyPrinted error:nil];
    AFOAuthCredential *cred = [self defaultCredential];
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",cred.accessToken];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"PUT"];
    [request setHTTPBody:postData];
    
    NSHTTPURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    //NSLog(@"datString: %@", datString);
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    // NSLog(@"jsonDict: %@", jsonDict);
    if ([jsonDict valueForKey:@"error"] != nil){
        return datString;
    }
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"[tuyu] status string: %@", returnString);
    return jsonDict;
}

/*
 curl \
   'https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet%2CcontentDetails&maxResults=25&playlistId=PLBCF2DAC6FFB574DE&key=[YOUR_API_KEY]' \
   --header 'Authorization: Bearer [YOUR_ACCESS_TOKEN]' \
   --header 'Accept: application/json' \
   --compressed
 */

- (void)getPlaylistItems:(NSString *)playlistID completion:(void(^)(NSArray <KBYTSearchResult *> *channels, NSString *error))completionBlock {
    __block NSMutableArray *channels = [NSMutableArray new];
    NSString *initialString = @"https://youtube.googleapis.com/youtube/v3/playlistItems?part=snippet%2CcontentDetails&maxResults=50&playlistId";
    NSString *getString = [NSString stringWithFormat:@"%@=%@", initialString, playlistID];
    [self genericGetCommand:getString completion:^(NSDictionary *jsonResponse, NSString *error) {
        NSLog(@"[tuyu] jsonResponse: %@", jsonResponse);
        NSArray *items = jsonResponse[@"items"];
        [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
        }];
        //NSLog(@"[tuyu] count: %lu %@", channels.count, channels);
        if (completionBlock) {
            completionBlock(channels, error);
        }
        
        [jsonResponse writeToFile:@"/var/mobile/Library/Preferences/playlistItemsResponse.plist" atomically:TRUE];
    }];
}

- (id)removeVideo:(NSString *)videoID FromPlaylist:(NSString *)favoriteID {
    
    [self refreshAuthToken];
    NSError* error;
    
    // Create URL request and set url, method, content-length, content-type, and body
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?id=%@&key=%@", favoriteID, ytClientID];
    
    NSLog(@"[tuyu] urlString: %@", urlString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    //[request addValue:@"2.1" forHTTPHeaderField:@"GData-Version"];
    AFOAuthCredential *cred = [self defaultCredential];
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",cred.accessToken];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"DELETE"];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    NSLog(@"[tuyu] datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"[tuyu] status string: %@", returnString);
    
    
    return @"Success";
    
}

- (id)deletePlaylist:(NSString *)playlistID {
    
    [self refreshAuthToken];
    NSError* error;
    
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlists?id=%@&key=%@", playlistID, ytClientID];
    
    //NSLog(@"urlString: %@", urlString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[[self defaultCredential] accessToken]];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"DELETE"];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"status string: %@", returnString);
    
    
    return @"Success";
    
}

- (void)signOut {
    [AFOAuthCredential deleteCredentialWithIdentifier:@"default"];
    self.tokenData = nil;
    self.authorized = NO;
    [UD removeObjectForKey:@"access_token"];
    [UD removeObjectForKey:@"refresh_token"];
}

- (BOOL)checkAndSetCredential {
    AFOAuthCredential * cred =  [AFOAuthCredential retrieveCredentialWithIdentifier:@"default"];
    //NSLog(@"[tuyu] cred: %@", cred);
    if (cred) {
        [self setCredential:cred];
        self.authorized = YES;
        return YES;
    }
    self.authorized = NO;
    return NO;
}

- (id)newcreatePlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:playlistTitle, @"title", nil];
    NSDictionary *status = [NSDictionary dictionaryWithObjectsAndKeys:privacyStatus, @"privacyStatus", nil];
    
    NSString *token = [[AFOAuthCredential retrieveCredentialWithIdentifier:@"default" accessGroup:nil] accessToken];
    
    NSDictionary *finalDict = [NSDictionary dictionaryWithObjectsAndKeys:dict, @"snippet", status, @"status", nil];
    
    DLog(@"%@", [finalDict JSONStringRepresentation]);
    
    NSError* error;
    [self POST:[NSString stringWithFormat:@"playlists?part=%@&key=%@", @"snippet%2cstatus", ytClientID] parameters:finalDict progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"response object: %@", responseObject);
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSLog(@"error: %@", error);
        
    }];
    return nil;
}
- (id)createPlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus {
    
    [self refreshAuthToken];
    //NSLog(@"creating playlist: %@ with status: %@", playlistTitle, privacyStatus);
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:playlistTitle, @"title", nil];
    NSDictionary *status = [NSDictionary dictionaryWithObjectsAndKeys:privacyStatus, @"privacyStatus", nil];
    
    NSDictionary *finalDict = [NSDictionary dictionaryWithObjectsAndKeys:dict, @"snippet", status, @"status", nil];
    NSError* error;
    
    NSLog(@"post: %@", finalDict);
    //NSLog(@"postString: %@", [finalDict JSONString]);
    
    // Encode post string
    NSData* postData = [NSJSONSerialization dataWithJSONObject:finalDict options:NSJSONWritingPrettyPrinted error:nil];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    //https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&key={YOUR_API_KEY}
    
    // Create URL request and set url, method, content-length, content-type, and body
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlists?part=%@&key=%@", @"snippet%2cstatus", ytClientID];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[[self defaultCredential] accessToken]];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    NSLog(@"datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"status string: %@", returnString);
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    // NSLog(@"jsonDict: %@", jsonDict);
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    }
    //NSLog(@"jsonDict: %@", jsonDict);
    //[jsonDict writeToFile:@"/var/mobile/Library/Preferences/createPlaylistResponse.plist" atomically:TRUE];
    
    KBYTSearchResult *searchResult = [KBYTSearchResult new];
    searchResult.videoId = jsonDict[@"id"];
    searchResult.title = playlistTitle;
    searchResult.resultType =kYTSearchResultTypePlaylist;
    
    if (searchResult.videoId.length > 0)
    {
        NSMutableDictionary *userDict = [[[KBYourTube sharedInstance]userDetails] mutableCopy];
        NSMutableArray *results = [userDict[@"results"] mutableCopy];
        [results addObject:searchResult];
        userDict[@"results"] = results;
        [[KBYourTube sharedInstance] setUserDetails:userDict];
    }
    
    return searchResult;
}

/*
 code=4/P7q7W91a-oMsCeLvIaQm6bTrgtp7&
 client_id=your_client_id&
 client_secret=your_client_secret&
 redirect_uri=http%3A//127.0.0.1%3A9004&
 grant_type=authorization_code
 */

- (void)postCodeToGoogle:(NSString *)code completion:(void(^)(NSDictionary *returnData))block {
    
    // LOG_SELF;
    NSString* post = [[NSString stringWithFormat:@"code=%@&client_id=%@&client_secret=%@&grant_type=authorization_code&redirect_uri=http://127.0.0.1:9004",code, ytClientID, ytSecretKey] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
     NSLog(@"postString: %@", post);
    
    // Encode post string
    NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    // Create URL request and set url, method, content-length, content-type, and body
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/token"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    if ([jsonDict valueForKey:@"error"] != nil) {
        if (block){
            block(jsonDict);
        }
    } else {
        AFOAuthCredential *newCred = [[AFOAuthCredential alloc] initWithOAuthToken:[jsonDict valueForKey:@"access_token"] tokenType:[jsonDict valueForKey:@"token_type"]];
        [newCred setRefreshToken:[jsonDict valueForKey:@"refresh_token"]];
        
        DLog(@"newcred: %@", newCred);
        [self setCredential:newCred];
        self.authorized = true;
        [AFOAuthCredential storeCredential:newCred withIdentifier:@"default"];
        [UD setObject:[jsonDict valueForKey:@"access_token"] forKey:@"access_token"];
        [UD setObject:[jsonDict valueForKey:@"refresh_token"] forKey:@"refresh_token"];
        [UD synchronize];
        [[KBYourTube sharedInstance] getUserDetailsDictionaryWithCompletionBlock:^(NSDictionary *outputResults) {
            [[KBYourTube sharedInstance] setUserDetails:outputResults];
        } failureBlock:^(NSString *error) {
            
        }];
        if (block){
            block(jsonDict);
        }
    }
}

- (id)refreshAuthToken{
    
    // LOG_SELF;
    NSString* post = nil;
    
    AFOAuthCredential *token = [self defaultCredential];
    
    post = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&scope=&client_secret=%@&grant_type=refresh_token&&", token.refreshToken, ytClientID, ytSecretKey];
    
    // NSLog(@"postString: %@", post);
    
    // Encode post string
    NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    // Create URL request and set url, method, content-length, content-type, and body
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/token"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return jsonDict;
    } else {
        NSString *refreshToken = token.refreshToken;
        AFOAuthCredential *credential = [AFOAuthCredential credentialWithOAuthToken:[jsonDict valueForKey:@"access_token"] tokenType:[jsonDict valueForKey:@"token_type"]];
        credential.refreshToken = refreshToken;
        [AFOAuthCredential storeCredential:credential withIdentifier:@"default"];
        //NSLog(@"[tuyu] refreshed credential: %@", credential);
        [UD setObject:[jsonDict valueForKey:@"access_token"] forKey:@"access_token"];
        
    }
    return jsonDict;
    
}

- (NSArray *)playlists {
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSMutableArray *finalArray = [NSMutableArray new];
    NSArray *results = userDetails[@"results"];
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType ==kYTSearchResultTypePlaylist)
        {
            [finalArray addObject:result];
        }
    }
    return finalArray;
}

- (id)addVideo:(NSString *)videoID toPlaylistWithID:(NSString *)playlistID {
    
    [self refreshAuthToken];
    NSLog(@"adding a video: %@ to favorites: %@", videoID, playlistID);
    
    NSMutableDictionary *finalDict = [[NSMutableDictionary alloc] init];
    NSDictionary *resourceId = [NSDictionary dictionaryWithObjectsAndKeys:@"youtube#video", @"kind", videoID, @"videoId", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:playlistID, @"playlistId",resourceId , @"resourceId", nil];
    [finalDict setObject:dict forKey:@"snippet"];
    
    
    NSError* error;
    
    // Encode post string
    NSData* postData = [NSJSONSerialization dataWithJSONObject:finalDict options:NSJSONWritingPrettyPrinted error:nil];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    //https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&key={YOUR_API_KEY}
    
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&key=%@", ytClientID];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    NSString *accessToken = [[self defaultCredential] accessToken];
    
    NSLog(@"access token: %@", accessToken);
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",accessToken];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"status string: %@", returnString);
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    // NSLog(@"jsonDict: %@", jsonDict);
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    }
    
    return jsonDict;
}

- (void)postOAuth2CodeToGoogle:(NSString *)code completion:(void(^)(NSString *value))block {
    NSURL *baseURL = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2"];
    
    
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                    clientID:ytClientID
                                      secret:ytSecretKey];
    
    
    NSDictionary *params = @{@"code": code, @"grant_type": @"authorization_code", @"redirect_uri": [@"urn:ietf:wg:oauth:2.0:oob:auto" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"client_id": ytClientID, @"client_secret": ytSecretKey };
    
    DLog(@"params: %@", params);
    
    
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"https://accounts.google.com/o/oauth2/token" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject, AFOAuthCredential * _Nonnull credential) {
        
        [AFOAuthCredential storeCredential:credential withIdentifier:@"default"];
        
        DLog(@"credential: %@", credential);
        block(@"Success");
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        DLog(@"fail!!");
        block(@"fail");
    }];
    
}

- (void)startAuthAndGetUserCodeDetails:(DeviceCodeBlock)codeBlock completion:(FinishedBlock)finished {
    
    self.finishedBlock = finished;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [self getOAuthCodeWithCompletion:^(NSDictionary *codeDict) {
            if (codeDict) {
                
                self.authResponse = codeDict;
                NSLog(@"self.authResponse: %@", self.authResponse);
                [self startAuthPolling];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                codeBlock(self.authResponse);
            });
        }];
    });
}

- (void)getOAuthCodeWithCompletion:(void(^)(NSDictionary *codeDict))block {
    
    //curl -d "client_id=670004260779-f193lea0mkihris4cr8gi4qaek46c0kl.apps.googleusercontent.com&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube.readonly" \
    https://oauth2.googleapis.com/device/code
    NSString* post = [NSString stringWithFormat:@"client_id=%@&scope=%@",ytClientID, [@"https://www.googleapis.com/auth/youtube" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // Encode post string
    NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    // Create URL request and set url, method, content-length, content-type, and body
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://oauth2.googleapis.com/device/code"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSHTTPURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    
    //NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"datString: %@", datString);
    
    //NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    if (block){
        block(jsonDict);
    }
}

- (id)postOAuth2CodeToGoogle:(NSString *)code{
    
    NSString* post = [NSString stringWithFormat:@"code=%@&client_id=%@&scope=&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&", [code stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],ytClientID, ytSecretKey, [@"urn:ietf:wg:oauth:2.0:oob:auto" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    DLog(@"post: %@", post);
    
    // Encode post string
    NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
    
    // Calculate length of post data
    NSString* postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    
    // Create URL request and set url, method, content-length, content-type, and body
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    NSHTTPURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"datString: %@", datString);
    
    //NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    } else {
        
        AFOAuthCredential *newCred = [[AFOAuthCredential alloc] initWithOAuthToken:[jsonDict valueForKey:@"access_token"] tokenType:[jsonDict valueForKey:@"token_type"]];
        [newCred setRefreshToken:[jsonDict valueForKey:@"refresh_token"]];
        
        //DLog(@"newcred: %@", newCred);
        [self setCredential:newCred];
        [AFOAuthCredential storeCredential:newCred withIdentifier:@"default"];
        [UD setObject:[jsonDict valueForKey:@"access_token"] forKey:@"access_token"];
        [UD setObject:[jsonDict valueForKey:@"refresh_token"] forKey:@"refresh_token"];
        [UD synchronize];
        
        
    }
    return @"Success";
    
}

@end
