//
//  YTBrowserHelper.h
//  YTBrowserHelper
//
//  Created by Kevin Bradley on 12/30/15.
//  Copyright © 2015 nito. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import "GCDWebServer/GCDWebServer.h"

@interface YTBrowserHelper : NSObject

- (void) doScience;
+ (id)sharedInstance;

@property (nonatomic, strong) GCDWebServer *webServer;
@end
