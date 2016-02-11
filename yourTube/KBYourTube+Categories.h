//
//  KBYourTube+Categories.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

@interface NSDictionary (strings)

- (NSString *)stringValue;

@end

@interface NSArray (strings)

- (NSString *)stringFromArray;

@end

@interface NSString (TSSAdditions)

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)timeInterval;
- (id)dictionaryValue;
- (NSInteger)timeFromDuration;
@end

@interface NSDate (convenience)

- (NSString *)timeStringFromCurrentDate;

@end


@interface NSURL (QSParameters)
- (NSArray *)parameterArray;
- (NSDictionary *)parameterDictionary;
@end

@interface NSObject  (convenience)

- (NSString *)downloadFile;
- (NSString *)appSupportFolder;
- (NSString *)downloadFolder;
- (NSMutableDictionary *)parseFlashVars:(NSString *)vars;
- (NSArray *)matchesForString:(NSString *)string withRegex:(NSString *)pattern;
- (NSMutableDictionary *)dictionaryFromString:(NSString *)string withRegex:(NSString *)pattern;

@end

@interface NSString  (SplitString)

- (NSArray *)splitString;

@end