//
//  Defines.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 3/11/16.
//  Copyright © 2016 nito. All rights reserved.
//


#import "NSObject+Additions.h"
#import "UIColor+Additions.h"
#import "UIImageView+WebCache.h"
#import "SVProgressHUD.h"
#import "UIView+RecursiveFind.h"
#import "NSDictionary+serialize.h"
#import "KBSection.h"

static NSString * const kShelfControllerRoundedEdges = @"kShelfControllerRoundedEdges";

//#define INFINITE_CELL_COUNT 100000

#if (TARGET_IPHONE_SIMULATOR)
//#define DUMMY_CODE
#endif

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        DLog(@"%@ %@", self, NSStringFromSelector(_cmd))
#define DLOG_SELF DLog(@"%@ %@", self, NSStringFromSelector(_cmd))

#define HOUR_MINUTES	60
#define DAY_MINUTES		1440
#define WEEK_MINUTES	10080

// System info
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
