//
//  KBProtocols.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 4/12/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    SectionTypeBanner = 0,
    SectionTypeStandard = 1,
} SectionType;

@protocol KBCollectionItemProtocol <NSObject>
- (NSString *)title;
- (NSString *)uniqueID;
- (NSString *)imagePath;
@optional
@optional
- (NSString *)duration;
- (NSString *)author;
- (NSString *)banner;
- (NSString *)secondaryTitle;
- (NSString *)details;
- (NSNumber *)resultType;
@end

@protocol KBSectionProtocol <NSObject>

- (NSString *)sectionName;
- (NSString *)type; //banner or standard
- (SectionType)sectionType;
- (NSInteger)order;
- (BOOL)infinite;
- (BOOL)autoScroll;
- (NSArray <KBCollectionItemProtocol>*)items;
- (NSString *)size;

@end

NS_ASSUME_NONNULL_END
