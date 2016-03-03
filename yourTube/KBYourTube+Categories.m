//
//  KBYourTube+Categories.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

#import <Foundation/Foundation.h>
#import "KBYourTube+Categories.h"


@implementation NSDictionary (strings)

- (NSString *)stringValue
{
    NSString *error = nil;
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
    NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
    return s;
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
    return ![FM fileExistsAtPath:@"/var/mobile/Library/Application Support/tuyu"];
}

- (NSString *)downloadFile
{
    return [[self appSupportFolder] stringByAppendingPathComponent:@"Downloads.plist"];
}

- (NSString *)vanillaAppSupport
{
    NSArray *paths =
    NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
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