//
//  KBYourTube+Categories.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

@interface NSHTTPCookieStorage (ClearAllCookies)

- (void)clearAllCookies;

@end

@interface UITableView (completion)

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock;

@end

@interface UICollectionView (completion)

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock;

@end

@interface NSDictionary (strings)

- (NSString *)stringValue;
- (NSString *)JSONStringRepresentation;
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
+ (BOOL)passedEpochDateInterval:(NSTimeInterval)interval;

@end


@interface NSURL (QSParameters)
- (NSArray *)parameterArray;
- (NSDictionary *)parameterDictionary;
@end

@interface NSObject  (convenience)

- (void)addCookies:(NSArray *)cookies forRequest:(NSMutableURLRequest *)request;
- (BOOL)vanillaApp;
- (NSString *)downloadFile;
- (NSString *)appSupportFolder;
- (NSString *)downloadFolder;
- (NSMutableDictionary *)parseFlashVars:(NSString *)vars;
- (NSArray *)matchesForString:(NSString *)string withRegex:(NSString *)pattern;
- (NSMutableDictionary *)dictionaryFromString:(NSString *)string withRegex:(NSString *)pattern;
- (NSString *)stringFromRequest:(NSString *)url;

@end

@interface NSString  (SplitString)

- (NSArray *)splitString;

@end

@interface UILabel (Additions)
- (void)shadowify;

@end

@interface NSObject (AMAssociatedObjects)
- (void)associateValue:(id)value withKey:(void *)key; // Strong reference
- (void)weaklyAssociateValue:(id)value withKey:(void *)key;
- (id)associatedValueForKey:(void *)key;
@end
