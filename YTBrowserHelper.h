//
//  YTBrowserHelper.h
//  YTBrowserHelper
//
//  Created by Kevin Bradley on 12/30/15.
//  Copyright © 2015 nito. All rights reserved.
//

//#import <Foundation/Foundation.h>
//#import "GCDWebServer/GCDWebServer.h"

@interface YTBrowserHelper : NSObject

- (void) doScience;
+ (id)sharedInstance;
- (void)importFile:(NSString *)filePath withData:(NSDictionary *)inputDict serverURL:(NSString *)serverURL;

//@property (nonatomic, strong) GCDWebServer *webServer;
@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSString *deviceIP;
@property (readwrite, assign) BOOL airplaying;

- (void)fireAirplayTimer;

@end
