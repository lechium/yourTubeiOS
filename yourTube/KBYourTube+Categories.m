//
//  KBYourTube+Categories.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KBYourTube+Categories.h"
#ifndef SHELF_EXT
#import "TYAuthUserManager.h"
#endif
@implementation NSHTTPCookieStorage (ClearAllCookies)

- (void)clearAllCookies
{
    [self.cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self deleteCookie:obj];
        
    }];
}

@end


@implementation UITableView (completion)

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock
{
    [self reloadData];
    
    dispatch_async(dispatch_get_main_queue(),^{
       // NSIndexPath *path = [NSIndexPath indexPathForRow:yourRow inSection:yourSection];
        //Basically maintain your logic to get the indexpath
        //[yourTableview scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
        completionBlock();
    });
}

@end

@implementation UICollectionView (completion)

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock
{
    [self reloadData];
    
    dispatch_async(dispatch_get_main_queue(),^{
        // NSIndexPath *path = [NSIndexPath indexPathForRow:yourRow inSection:yourSection];
        //Basically maintain your logic to get the indexpath
        //[yourTableview scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
        completionBlock();
    });
}


@end

@implementation NSDictionary (strings)

- (NSString *)stringValue
{
    NSString *error = nil;
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
    return s;
}

- (NSString *)JSONStringRepresentation
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end

@implementation NSArray (strings)

- (NSString *)stringFromArray
{
    NSString *error = nil;
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
    return s;
}

@end


@implementation NSString (TSSAdditions)

- (NSInteger)timeFromDuration
{
    NSLog(@"duration: %@", self);
    NSArray *durationArray = [self componentsSeparatedByString:@":"];
    if ([durationArray count] == 3)
    {
        //has hours
        NSLog(@"has hours???");
        NSInteger hoursInSeconds = [[durationArray firstObject] integerValue] * 3600;
        NSInteger minutesInSeconds = [[durationArray objectAtIndex:1] integerValue] * 60;
        NSInteger seconds = [[durationArray lastObject] integerValue];
        return hoursInSeconds + minutesInSeconds + seconds;
    } else {
        NSInteger minutesInSeconds = [[durationArray firstObject] integerValue] * 60;
        NSInteger seconds = [[durationArray lastObject] integerValue];
        return  minutesInSeconds + seconds;
    }
    return 0;
}

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger interval = timeInterval;
    long seconds = interval % 60;
    long minutes = (interval / 60) % 60;
    long hours = (interval / 3600);
    
    if (hours > 0)
    {
        return [NSString stringWithFormat:@"%ld:%ld:%0.2ld", hours, minutes, seconds];
    }
    
    return [NSString stringWithFormat:@"%ld:%0.2ld", minutes, seconds];
}

/*
 
 we use this to convert a raw dictionary plist string into a proper NSDictionary
 
 */

- (id)dictionaryValue
{
    NSString *error = nil;
    NSPropertyListFormat format;
    NSData *theData = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    id theDict = [NSPropertyListSerialization propertyListFromData:theData
                                                  mutabilityOption:NSPropertyListImmutable
                                                            format:&format
                                                  errorDescription:&error];
    return theDict;
}

@end

@implementation NSDate (convenience)

+ (BOOL)passedEpochDateInterval:(NSTimeInterval)interval
{
    //return true; //force to test to see if it works
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
    NSComparisonResult result = [date compare:[NSDate date]];
    if (result == NSOrderedAscending)
    {
        return true;
    }
    return false;
}


- (NSString *)timeStringFromCurrentDate
{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInt = [currentDate timeIntervalSinceDate:self];
    // NSLog(@"timeInt: %f", timeInt);
    NSInteger minutes = floor(timeInt/60);
    NSInteger seconds = round(timeInt - minutes * 60);
    return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
    
}

@end

@implementation NSURL (QSParameters)
- (NSArray *)parameterArray {
    
    if (![self query]) return nil;
    NSScanner *scanner = [NSScanner scannerWithString:[self query]];
    if (!scanner) return nil;
    
    NSMutableArray *array = [NSMutableArray array];
    
    NSString *key;
    NSString *val;
    while (![scanner isAtEnd]) {
        if (![scanner scanUpToString:@"=" intoString:&key]) key = nil;
        [scanner scanString:@"=" intoString:nil];
        if (![scanner scanUpToString:@"&" intoString:&val]) val = nil;
        [scanner scanString:@"&" intoString:nil];
        
        key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        val = [val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        if (key) [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                   key, @"key", val, @"value", nil]];
    }
    return array;
}


- (NSDictionary *)parameterDictionary {
    if (![self query]) return nil;
    NSArray *parameterArray = [self parameterArray];
    
    NSArray *keys = [parameterArray valueForKey:@"key"];
    NSArray *values = [parameterArray valueForKey:@"value"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    return dictionary;
}

@end


/**
 
 Is it bad form to add categories to NSObject for frequently used convenience methods? probably. does it make
 calling these methods from anywhere incredibly easy? yes. so... DONT CARE :-P
 
 */

@implementation NSObject (convenience)

- (id)recursiveObjectLikeKey:(NSString *)desiredKey {
    return [self recursiveObjectLikeKey:desiredKey parent:nil];
}

- (id)recursiveObjectLikeKey:(NSString *)desiredKey parent:(id)parent {
    if ([self isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictSelf = (NSDictionary *)self;
        NSPredicate *likePred = [NSPredicate predicateWithFormat:@"self like[c] %@ || self contains[c] %@", desiredKey, desiredKey];
        //NSLog(@"dict: %@", dictSelf.allKeys);
        for (NSString *key in dictSelf.allKeys) {
            if ([likePred evaluateWithObject:key]){
                //DLog(@"got im!: %@", key);
                return dictSelf[key];
            } else {
                NSDictionary *dict = dictSelf[key];
                
                if ([dict isKindOfClass:NSDictionary.class] || [dict isKindOfClass:NSArray.class]){
                    //NSLog(@"checking key: %@", key);
                    id obj = [dict recursiveObjectLikeKey:desiredKey parent:key];
                    if (obj) {
                        //NSLog(@"found key: %@ in parent: %@", [obj valueForKey:@"title"], key);
                        //return dict;
                        return obj;
                    }
                }
            }
        }
    } else if ([self isKindOfClass:NSArray.class]){
        NSArray *arraySelf = (NSArray *)self;
        for (NSDictionary *item in arraySelf) {
            if ([item isKindOfClass:NSDictionary.class]){
                id obj = [item recursiveObjectLikeKey:desiredKey parent:arraySelf];
                if (obj) {
                    return obj;
                }
                //return [item recursiveObjectForKey:desiredKey];
            }
        }
    } else {
        NSLog(@"%@ %@ is not an NSDictionary or an NSArray, bail!", NSStringFromSelector(_cmd), self);
    }
    
    return nil;
}

- (id)recursiveObjectsLikeKey:(NSString *)desiredKey {
    return [self recursiveObjectsLikeKey:desiredKey parent:nil];
}

- (id)recursiveObjectsLikeKey:(NSString *)desiredKey parent:(id)parent {
    if ([self isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictSelf = (NSDictionary *)self;
        NSPredicate *likePred = [NSPredicate predicateWithFormat:@"self like[c] %@ || self contains[c] %@", desiredKey, desiredKey];
        //NSLog(@"dict: %@", dictSelf.allKeys);
        for (NSString *key in dictSelf.allKeys) {
            if ([likePred evaluateWithObject:key]){
                //DLog(@"got im!: %@", key);
                return parent ? parent : dictSelf[key];//return dictSelf[key];
            } else {
                NSDictionary *dict = dictSelf[key];
                
                if ([dict isKindOfClass:NSDictionary.class] || [dict isKindOfClass:NSArray.class]){
                    //NSLog(@"checking key: %@", key);
                    id obj = [dict recursiveObjectsLikeKey:desiredKey parent:key];
                    if (obj) {
                        //NSLog(@"found key: %@ in parent: %@", [obj valueForKey:@"title"], key);
                        //return dict;
                        return obj;
                    }
                }
            }
        }
    } else if ([self isKindOfClass:NSArray.class]){
        NSArray *arraySelf = (NSArray *)self;
        for (NSDictionary *item in arraySelf) {
            if ([item isKindOfClass:NSDictionary.class]){
                id obj = [item recursiveObjectsLikeKey:desiredKey parent:arraySelf];
                if (obj) {
                    return obj;
                }
                //return [item recursiveObjectForKey:desiredKey];
            }
        }
    } else {
        NSLog(@"%@ %@ is not an NSDictionary or an NSArray, bail!", NSStringFromSelector(_cmd), self);
    }
    
    return nil;
}


- (id)recursiveObjectsForKey:(NSString *)desiredKey parent:(id)parent {
    if ([self isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictSelf = (NSDictionary *)self;
        //NSLog(@"dict: %@", dictSelf.allKeys);
        for (NSString *key in dictSelf.allKeys) {
            if ([desiredKey isEqualToString:key]){
                //NSLog(@"got im!: %@", parent);
                return parent ? parent : dictSelf[key];
            } else {
                NSDictionary *dict = dictSelf[key];
                
                if ([dict isKindOfClass:NSDictionary.class] || [dict isKindOfClass:NSArray.class]){
                    //NSLog(@"checking key: %@", key);
                    id obj = [dict recursiveObjectsForKey:desiredKey parent:key];
                    if (obj) {
                        //NSLog(@"found key: %@ in parent: %@", [obj valueForKey:@"title"], key);
                        //return dict;
                        return obj;
                    }
                }
            }
        }
    } else if ([self isKindOfClass:NSArray.class]){
        NSArray *arraySelf = (NSArray *)self;
        for (NSDictionary *item in arraySelf) {
            if ([item isKindOfClass:NSDictionary.class]){
                id obj = [item recursiveObjectsForKey:desiredKey parent:arraySelf];
                if (obj) {
                    return obj;
                }
                //return [item recursiveObjectForKey:desiredKey];
            }
        }
    } else {
        NSLog(@"%@ is not an NSDictionary or an NSArray, bail!", self);
    }
    
    return nil;
}

- (id)recursiveObjectForKey:(NSString *)desiredKey parent:(id)parent {
    if ([self isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictSelf = (NSDictionary *)self;
        //NSLog(@"dict: %@", dictSelf.allKeys);
        for (NSString *key in dictSelf.allKeys) {
            if ([desiredKey isEqualToString:key]){
                //NSLog(@"got im!: %@", parent);
                return dictSelf[key];
            } else {
                NSDictionary *dict = dictSelf[key];
                
                if ([dict isKindOfClass:NSDictionary.class] || [dict isKindOfClass:NSArray.class]){
                    //NSLog(@"checking key: %@", key);
                    id obj = [dict recursiveObjectForKey:desiredKey parent:key];
                    if (obj) {
                        //NSLog(@"found key: %@ in parent: %@", [obj valueForKey:@"title"], key);
                        //return dict;
                        return obj;
                    }
                }
            }
        }
    } else if ([self isKindOfClass:NSArray.class]){
        NSArray *arraySelf = (NSArray *)self;
        for (NSDictionary *item in arraySelf) {
            if ([item isKindOfClass:NSDictionary.class]){
                id obj = [item recursiveObjectForKey:desiredKey parent:arraySelf];
                if (obj) {
                    return obj;
                }
                //return [item recursiveObjectForKey:desiredKey];
            }
        }
    } else {
        NSLog(@"%@ is not an NSDictionary or an NSArray, bail!", self);
    }
    
    return nil;
}

- (id)recursiveObjectForKey:(NSString *)desiredKey {
    return [self recursiveObjectForKey:desiredKey parent:nil];
}

- (id)recursiveObjectsForKey:(NSString *)desiredKey {
    return [self recursiveObjectsForKey:desiredKey parent:nil];
}


+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval
{
    NSInteger interval = timeInterval;
    NSInteger ms = (fmod(timeInterval, 1) * 1000);
    long seconds = interval % 60;
    long minutes = (interval / 60) % 60;
    long hours = (interval / 3600);
    
    return [NSString stringWithFormat:@"%0.2ld:%0.2ld:%0.2ld,%0.3ld", hours, minutes, seconds, (long)ms];
}

#pragma mark Parsing & Regex magic


//change a wall of "body" text into a dictionary like &key=value

- (NSMutableDictionary *)parseFlashVars:(NSString *)vars
{
    return [self dictionaryFromString:vars withRegex:@"([^&=]*)=([^&]*)"];
}

//give us the actual matches from a regex, rather then NSTextCheckingResult full of ranges

- (NSArray *)matchesForString:(NSString *)string withRegex:(NSString *)pattern
{
    NSMutableArray *array = [NSMutableArray new];
    NSError *error = NULL;
    NSRange range = NSMakeRange(0, string.length);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
    NSArray *matches = [regex matchesInString:string options:NSMatchingReportProgress range:range];
    for (NSTextCheckingResult *entry in matches)
    {
        NSString *text = [string substringWithRange:entry.range];
        [array addObject:text];
    }
    
    return array;
}


//the actual function that does the &key=value dictionary creation mentioned above

- (NSMutableDictionary *)dictionaryFromString:(NSString *)string withRegex:(NSString *)pattern
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSArray *matches = [self matchesForString:string withRegex:pattern];
    
    for (NSString *text in matches)
    {
        NSArray *components = [text componentsSeparatedByString:@"="];
        [dict setObject:[components objectAtIndex:1] forKey:[components objectAtIndex:0]];
    }
    
    return dict;
}

- (BOOL)vanillaApp
{
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                        NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:
                                                0] : NSTemporaryDirectory();
    //NSLog(@"basePath: %@", basePath);
    return ![basePath isEqualToString:@"/var/mobile/Library/Application Support"];
   
}

- (NSString *)downloadFile
{
    return [[self appSupportFolder] stringByAppendingPathComponent:@"Downloads.plist"];
}

- (NSString *)vanillaAppSupport
{
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                        NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:
                                                0] : NSTemporaryDirectory();
    if (![FM fileExistsAtPath:basePath])
        [FM createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
    return basePath;
}

- (NSString *)appSupportFolder
{
    if ([self vanillaApp])
    {
        return [self vanillaAppSupport];
    }
   
    NSString *outputFolder = @"/var/mobile/Library/Application Support/tuyu";
    if (![FM fileExistsAtPath:outputFolder])
    {
        [FM createDirectoryAtPath:outputFolder withIntermediateDirectories:true attributes:nil error:nil];
    }
    return outputFolder;
}

- (NSString *)downloadFolder
{
    NSString *dlF = [[self appSupportFolder] stringByAppendingPathComponent:@"Downloads"];
    if (![FM fileExistsAtPath:dlF])
    {
        [FM createDirectoryAtPath:dlF withIntermediateDirectories:true attributes:nil error:nil];
    }
    return dlF;
}

- (void)addCookies:(NSArray *)cookies forRequest:(NSMutableURLRequest *)request
{
    if ([cookies count] > 0)
    {
        NSHTTPCookie *cookie;
        NSString *cookieHeader = nil;
        for (cookie in cookies)
        {
            if (!cookieHeader)
            {
                cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
            }
            else
            {
                cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
            }
        }
        if (cookieHeader)
        {
            [request setValue:cookieHeader forHTTPHeaderField:@"Cookie"];
        }
    }
}

//take a url and get its raw body, then return in string format

- (NSString *)stringFromRequest:(NSString *)url
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:10];
    
    //[request setValue:@"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0 Mobile/12B410 Safari/601.2.7" forHTTPHeaderField:@"User-Agent"];
    
   // NSLog(@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/603.3.8 (KHTML, like Gecko) Version/10.1.2 Safari/603.3.8");
#ifndef SHELF_EXT
    AFOAuthCredential *cred = [AFOAuthCredential retrieveCredentialWithIdentifier:@"default"];
    if (cred) {
        NSString *authorization = [NSString stringWithFormat:@"Bearer %@",cred.accessToken];
        [request setValue:authorization forHTTPHeaderField:@"Authorization"];
    }
#endif
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    //DLog(@"cookies: %@", cookies);
    if (cookies != nil){
        [request setHTTPShouldHandleCookies:YES];
        [self addCookies:cookies forRequest:request];
    }
    
    NSURLResponse *response = nil;
    
    [request setHTTPMethod:@"GET"];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    //DLog(@"response: %@", response);
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
}

@end



//split a string into an NSArray of characters

@implementation NSString (SplitString)

- (NSArray *)splitString
{
    NSUInteger index = 0;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.length];
    
    while (index < self.length) {
        NSRange range = [self rangeOfComposedCharacterSequenceAtIndex:index];
        NSString *substring = [self substringWithRange:range];
        [array addObject:substring];
        index = range.location + range.length;
    }
    
    return array;
}


@end

@implementation UILabel (Additions)
//TODO: since this particular shadow is ALWAYS the same, can probably cache/reuse a static version
- (void)shadowify
{
    NSShadow* shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(1.0f, 1.0f);
    shadow.shadowBlurRadius = 4;
    NSDictionary *attrs = @{NSFontAttributeName: self.font, NSForegroundColorAttributeName: self.textColor, NSShadowAttributeName: shadow};
    NSAttributedString *theString = [[NSAttributedString alloc] initWithString:self.text attributes:attrs];
    
    self.attributedText = theString;
}

@end

#import <objc/runtime.h>

@implementation NSObject (AMAssociatedObjects)


- (void)associateValue:(id)value withKey:(void *)key
{
    objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN);
}

- (void)weaklyAssociateValue:(id)value withKey:(void *)key
{
    objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_ASSIGN);
}

- (id)associatedValueForKey:(void *)key
{
    return objc_getAssociatedObject(self, key);
}

@end
