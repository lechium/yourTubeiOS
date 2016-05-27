//
//  TYAuthUserManager.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
//

#import "TYAuthUserManager.h"
#import "YTCreds.h"



@implementation TYAuthUserManager

+ (WebViewController *)OAuthWebViewController
{
    NSString *authString = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?client_id=%@&redirect_uri=%@", ytClientID, @"urn:ietf:wg:oauth:2.0:oob&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutube.force-ssl+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fyoutubepartner&response_type=code&access_type=offline&pageId=none"];
    return [[WebViewController alloc] initWithURL:authString];
}

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    static TYAuthUserManager *shared;
    if (!shared){
        dispatch_once(&onceToken, ^{
            shared = [TYAuthUserManager new];
        });
    }
    
    return shared;
    
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

- (id)subscribeToChannel:(NSString *)channelId
{
    
    NSString *channel = [[channelId stringByDeletingLastPathComponent] lastPathComponent];
    
    //NSLog(@"subscribe to channel: %@", channel);
    
    [self refreshAuthToken];
    
    NSMutableDictionary *finalDict = [[NSMutableDictionary alloc] init];
    NSDictionary *resourceId = [NSDictionary dictionaryWithObjectsAndKeys:@"youtube#channel", @"kind", channel, @"channelId", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:resourceId , @"resourceId", nil];
    [finalDict setObject:dict forKey:@"snippet"];
    
    
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

- (id)createPlaylistWithTitle:(NSString *)playlistTitle andPrivacyStatus:(NSString *)privacyStatus
{
    
    [self refreshAuthToken];
    //NSLog(@"creating playlist: %@ with status: %@", playlistTitle, privacyStatus);
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:playlistTitle, @"title", nil];
    NSDictionary *status = [NSDictionary dictionaryWithObjectsAndKeys:privacyStatus, @"privacyStatus", nil];
    
    NSDictionary *finalDict = [NSDictionary dictionaryWithObjectsAndKeys:dict, @"snippet", status, @"status", nil];
    NSError* error;
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
    
    //NSLog(@"datString: %@", datString);
    
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
    
    return jsonDict;
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

- (id)postOAuth2CodeToGoogle:(NSString *)code{
    
    NSString* post = nil;
    post = [NSString stringWithFormat:@"code=%@&client_id=%@&scope=&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&", [code stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],ytClientID, ytSecretKey, [@"urn:ietf:wg:oauth:2.0:oob" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
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
    
    NSString *returnString = [NSString stringWithFormat:@"Request returned with response: \"%@\" with status code: %ld",[NSHTTPURLResponse localizedStringForStatusCode:(long)[theResponse statusCode]], (long)[theResponse statusCode] ];
    
    //JSON data
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:returnData options:NSJSONReadingAllowFragments error:nil];
    
    if ([jsonDict valueForKey:@"error"] != nil)
    {
        return datString;
        
    } else {
        
        [UD setObject:[jsonDict valueForKey:@"access_token"] forKey:@"access_token"];
        [UD setObject:[jsonDict valueForKey:@"refresh_token"] forKey:@"refresh_token"];
        [UD synchronize];
        
        
    }
    return @"Success";
    
}

@end
