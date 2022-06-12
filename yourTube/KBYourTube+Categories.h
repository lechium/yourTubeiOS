//
//  KBYourTube+Categories.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/9/16.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (copy)
- (UIColor *)copyWithAlpha:(CGFloat)alpha;
@end

@interface UIViewController (Presentation)
- (void)safePresentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^__nullable)(void))completion;
@end

@interface NSData(MD5)
- (NSString*)MD5;
@end

@interface NSHTTPCookieStorage (ClearAllCookies)

- (void)clearAllCookies;

@end

@interface UIWindow (Additions)
- (UIViewController *)visibleViewController;
@end

@interface UITableView (completion)

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock;

@end

@interface UICollectionView (completion)

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock;

@end

@interface NSDictionary (strings)
- (NSMutableDictionary *)convertDictionaryToObjects;
- (NSString *)stringValue;
- (NSString *)JSONStringRepresentation;
- (NSMutableDictionary *)convertObjectsToDictionaryRepresentations;
@end

@interface NSArray (strings)
- (NSString *)runsToString;
- (NSMutableArray *)convertArrayToObjects;
- (NSString *)stringFromArray;
- (NSMutableArray *)convertArrayToDictionaries;
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
- (NSURL *)highResVideoURL;
- (NSArray *)parameterArray;
- (NSDictionary *)parameterDictionary;
@end

@interface NSObject  (convenience)
- (UIViewController *)topViewController;
#if TARGET_OS_TV
- (BOOL)darkMode;
#endif
+ (id)objectFromDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;
- (void)recursiveInspectObjectLikeKey:(NSString *)desiredKey saving:(NSMutableArray *)array;
- (void)recursiveInspectObjectForKey:(NSString *)desiredKey saving:(NSMutableArray *)array;
- (id)recursiveObjectsLikeKey:(NSString *)desiredKey;
- (id)recursiveObjectLikeKey:(NSString *)desiredKey;
- (id)recursiveObjectForKey:(NSString *)desiredKey;
- (id)recursiveObjectsForKey:(NSString *)desiredKey;
- (void)addCookies:(NSArray *)cookies forRequest:(NSMutableURLRequest *)request;
- (BOOL)vanillaApp;
- (NSString *)downloadFile;
- (NSString *)appSupportFolder;
- (NSString *)downloadFolder;
- (NSMutableDictionary *)parseFlashVars:(NSString *)vars;
- (NSArray *)matchesForString:(NSString *)string withRegex:(NSString *)pattern;
- (NSMutableDictionary *)dictionaryFromString:(NSString *)string withRegex:(NSString *)pattern;
- (NSString *)stringFromRequest:(NSString *)url;
#define recursiveObjectsLike(key, object, array) NSMutableArray *array = [NSMutableArray new]; [object recursiveInspectObjectLikeKey:key saving:array]
#define recursiveObjectsFor(key, object, array) NSMutableArray *array = [NSMutableArray new]; [object recursiveInspectObjectForKey:key saving:array]

@end


@interface NSString  (SplitString)

- (NSString *)firstPathComponent;
- (NSArray *)splitString;
- (NSString *)highResChannelURL;
- (NSString *)maxResVideoURL;
- (NSString *)highResVideoURL;
@end

@interface UILabel (Additions)
- (void)shadowify;

@end

@interface NSObject (AMAssociatedObjects)
- (void)associateValue:(id)value withKey:(void *)key; // Strong reference
- (void)weaklyAssociateValue:(id)value withKey:(void *)key;
- (id)associatedValueForKey:(void *)key;
@end

NS_ASSUME_NONNULL_END
