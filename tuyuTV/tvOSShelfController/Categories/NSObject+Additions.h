
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface UICollectionView (section)

@property NSInteger section;

@end

@interface UILabel (shadow)
- (void)shadowify;
@end

@interface NSObject (Additions)
//- (BOOL)darkMode;
- (id)safeObjectForKey:(id)key;
- (void)clearAllProperties;
- (void)showHUD;
- (void)dismissHUD;
//- (UIViewController *)topViewController;
- (NSArray *)ivars;
- (NSArray *)properties;
- (BOOL)alertShowing;
- (id)safeObjectAtIndex:(NSInteger)index;
- (id)objectAtIndexedSubscript:(NSInteger)idx;
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj atIndexedSubscript:(NSInteger)idx;
- (NSArray *)ivarsForClass:(Class)clazz;
- (NSArray *)propertiesForClass:(Class)clazz;
+ (NSString *)documentsFolder;
- (NSDictionary *)dictionaryRepresentation;
+ (id)objectFromDictionary:(NSDictionary *)dictionary usingClass:(Class)cls;
+ (id)objectFromDictionary:(NSDictionary *)dictionary;
@end
