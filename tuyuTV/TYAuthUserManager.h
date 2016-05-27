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
@end
