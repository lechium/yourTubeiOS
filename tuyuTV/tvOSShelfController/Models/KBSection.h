//
//  KBSection.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 12/23/17.
//  Copyright © 2017 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBProtocols.h"
@class KBModelItem, KBYTSearchResult;
typedef enum {
    KBSectionTypeBanner = 0,
    KBSectionTypeStandard = 1,
} KBSectionType;

@interface KBSection : NSObject <KBSectionProtocol>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *type; //banner or standard
@property (readwrite, assign) NSInteger order;
@property (readwrite, assign) BOOL infinite;
@property (readwrite, assign) BOOL autoScroll;
@property (nonatomic, strong) NSArray <KBCollectionItemProtocol>*content;
@property (nonatomic, strong) NSString *size;
@property (nonatomic, strong) NSString *className;

- (CGFloat)imageWidth;
- (CGFloat)imageHeight;
- (CGSize)imageSize;
- (SectionType)sectionType;
- (void)addResult:(KBYTSearchResult *)result;
- (instancetype)initWithSectionDictionary:(NSDictionary *)dict;

@end
