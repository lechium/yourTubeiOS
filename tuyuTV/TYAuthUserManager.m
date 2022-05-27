//
//  TYAuthUserManager.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
//

#import "TYAuthUserManager.h"
#import "YTCreds.h"
#import "KBYourTube.h"


@implementation TYAuthUserManager

#if TARGET_OS_TV
+ (WebViewController *)ytAuthWebViewController
{
    WebViewController *webView = [[WebViewController alloc] initWithURL:[self ytAuthURL]];
    webView.viewMode = WebViewControllerAuthMode;
    return webView;
}

+ (WebViewController *)OAuthWebViewController
{
    
    WebViewController *webView = [[WebViewController alloc] initWithURL:[self suastring]];
    webView.viewMode = WebViewControllerPermissionMode;
    return webView;
}

#endif

#if TARGET_OS_IOS
+ (KBYTWebViewController *)ytAuthWebViewController
{
    KBYTWebViewController *webView = [[KBYTWebViewController alloc] initWithURL:[self ytAuthURL] mode:TYWebViewControllerAuthMode ];
    return webView;
}

+ (KBYTWebViewController *)OAuthWebViewController
{
    
    KBYTWebViewController *webView = [[KBYTWebViewController alloc] initWithURL:[self suastring] mode:TYWebViewControllerPermissionMode];
   // webView.viewMode = TYWebViewControllerPermissionMode;
    return webView;
}


#endif

+ (NSString *)ytAuthURL
{
    return @"https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fwww.youtube.com%2Fsignin%3Fnext%3D%252F%26hl%3Den%26feature%3Dsign_in_button%26app%3Ddesktop%26action_handle_signin%3Dtrue&hl=en&passive=true&service=youtube&uilel=3";
}

+ (NSString *)suastring
{
    return [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?client_id=%@&redirect_uri=%@", ytClientID, @"urn:ietf:wg:oauth:2.0:oob:auto&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube.force-ssl+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutubepartner&response_type=code&access_type=offline&pageId=none"];
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

- (void)setCredential:(AFOAuthCredential *)credential
{
    [self.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
}

//DELETE https://www.googleapis.com/youtube/v3/subscriptions?id=Y3ufRxVp116IMX8y_Gy1238MBhIUUSvzIfjGlLit6F0&key={YOUR_API_KEY}

- (id)unSubscribeFromChannel:(NSString *)subscriptionID
{
    
    //  NSLog(@"unsubscribe with ID: %@", subscriptionID);
    
    [self refreshAuthToken];
        NSError* error;
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/subscriptions?id=%@&key=%@", subscriptionID, ytClientID];
    
    // Create URL request and set url, method, content-length, content-type, and body
    //resourceId
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[UD valueForKey: @"access_token"]];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    //[request setURL:[NSURL URLWithString:@"https://gdata.youtube.com/feeds/api/users/default/favorites"]];
    [request setHTTPMethod:@"DELETE"];
    
    // [request addValue:[[DeviceAuth sharedDeviceAuth] signatureForRequest:request] forHTTPHeaderField:@"X-GData-Device"];
    
    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    //NSLog(@"datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"status string: %@", returnString);
    
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

- (void)copyPlaylist:(KBYTSearchResult *)result completion:(void(^)(NSString *response))completion
{
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

- (id)subscribeToChannel:(NSString *)channelId
{
    
    NSString *channel = [[channelId stringByDeletingLastPathComponent] lastPathComponent];
    
    
    
    if (channel.length == 0)
    {
        channel = channelId;
    }
    
    NSLog(@"subscribe to channel: %@", channel);
    
    [self refreshAuthToken];
    
    NSMutableDictionary *finalDict = [[NSMutableDictionary alloc] init];
    NSDictionary *resourceId = [NSDictionary dictionaryWithObjectsAndKeys:@"youtube#channel", @"kind", channel, @"channelId", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:resourceId , @"resourceId", nil];
    [finalDict setObject:dict forKey:@"snippet"];
    
    DLog(@"finalDict: %@", finalDict);
    
    NSError* error;
    
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
    
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[UD valueForKey: @"access_token"]];
    [request setValue:authorization forHTTPHeaderField:@"Authorization"];

    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];

    
    NSHTTPURLResponse *theResponse = nil;
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:&error];
    
    NSString *datString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    NSLog(@"status string: %@", returnString);
    
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    // NSLog(@"jsonDict: %@", jsonDict);
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    }
    //NSLog(@"jsonDict: %@", jsonDict);
    //[jsonDict writeToFile:@"/var/mobile/Library/Preferences/channelSubscribeResponse.plist" atomically:TRUE];
    
    return jsonDict;
    
}

- (id)removeVideo:(NSString *)videoID FromPlaylist:(NSString *)favoriteID
{
    
    [self refreshAuthToken];
    NSError* error;
    
    // Create URL request and set url, method, content-length, content-type, and body
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?id=%@&key=%@", favoriteID, ytClientID];
    
    //NSLog(@"urlString: %@", urlString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    //[request addValue:@"2.1" forHTTPHeaderField:@"GData-Version"];
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[UD valueForKey: @"access_token"]];
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

- (id)deletePlaylist:(NSString *)playlistID
{
    
    [self refreshAuthToken];
    NSError* error;
    
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlists?id=%@&key=%@", playlistID, ytClientID];
    
    //NSLog(@"urlString: %@", urlString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:40.0f];
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[UD valueForKey: @"access_token"]];
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



- (void)checkAndSetCredential
{
   AFOAuthCredential * cred =  [AFOAuthCredential retrieveCredentialWithIdentifier:@"default" accessGroup:nil];
    DLog(@"cred: %@", cred);
    if (cred)
    {
        [self setCredential:cred];
    }
}

- (id)newcreatePlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus
{
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
- (id)createPlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus
{
    
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
    
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[UD valueForKey: @"access_token"]];
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
    searchResult.resultType = YTSearchResultTypePlaylist;
    
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

- (id)refreshAuthToken{
    
    // LOG_SELF;
    NSString* post = nil;

    
    
    post = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&scope=&client_secret=%@&grant_type=refresh_token&&", [[UD objectForKey:@"refresh_token"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], ytClientID, ytSecretKey];
    
    // NSLog(@"postString: %@", post);
    
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
    
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
      NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return jsonDict;
    } else {
        
        [UD setObject:[jsonDict valueForKey:@"access_token"] forKey:@"access_token"];
        
    }
    return jsonDict;
    
}

- (NSArray *)playlists
{
    NSDictionary *userDetails = [[KBYourTube sharedInstance] userDetails];
    NSMutableArray *finalArray = [NSMutableArray new];
    NSArray *results = userDetails[@"results"];
    for (KBYTSearchResult *result in results)
    {
        if (result.resultType == YTSearchResultTypePlaylist)
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
    
    NSString *accessToken = [UD valueForKey: @"access_token"];
    
    NSLog(@"access token: %@", accessToken);
    
    NSString *authorization = [NSString stringWithFormat:@"Bearer %@",[UD valueForKey: @"access_token"]];
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

- (void)postOAuth2CodeToGoogle:(NSString *)code completion:(void(^)(NSString *value))block
{
    NSURL *baseURL = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2"];
    
   
    AFOAuth2Manager *OAuth2Manager =
    [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                    clientID:ytClientID
                                      secret:ytSecretKey];
    
    
    NSDictionary *params = @{@"code": code, @"grant_type": @"authorization_code", @"redirect_uri": [@"urn:ietf:wg:oauth:2.0:oob:auto" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"client_id": ytClientID, @"client_secret": ytSecretKey };
    
    DLog(@"params: %@", params);
    
    
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"https://accounts.google.com/o/oauth2/token" parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject, AFOAuthCredential * _Nonnull credential) {
        
        [AFOAuthCredential storeCredential:credential withIdentifier:@"youtube"];
        
        DLog(@"credential: %@", credential);
        block(@"Success");
        
    } failure:^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        
        DLog(@"fail!!");
        block(@"fail");
    }];

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
    
    NSLog(@"datString: %@", datString);
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    } else {
        
        AFOAuthCredential *newCred = [[AFOAuthCredential alloc] initWithOAuthToken:[jsonDict valueForKey:@"access_token"] tokenType:[jsonDict valueForKey:@"token_type"]];
        [newCred setRefreshToken:[jsonDict valueForKey:@"refresh_token"]];
        
        DLog(@"newcred: %@", newCred);
        [self setCredential:newCred];
        [AFOAuthCredential storeCredential:newCred withIdentifier:@"default" accessGroup:nil];
        [UD setObject:[jsonDict valueForKey:@"access_token"] forKey:@"access_token"];
        [UD setObject:[jsonDict valueForKey:@"refresh_token"] forKey:@"refresh_token"];
        [UD synchronize];
        
        
    }
    return @"Success";
    
}

@end
