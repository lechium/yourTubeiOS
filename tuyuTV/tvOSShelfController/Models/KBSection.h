//
//  KBSection.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 12/23/17.
//  Copyright © 2017 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBProtocols.h"
//#import "KBYourTube.h"
@class KBModelItem, KBYTSearchResult, KBYTChannel, KBYTPlaylist;
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
@property (readwrite, assign) NSUInteger sectionResultType;
@property (nonatomic, strong) NSString *uniqueId; //either channel ID or playlist ID for now.
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) KBYTChannel *channel; //optional
@property (nonatomic, strong) KBYTPlaylist *playlist;//optional
@property (nonatomic, strong) NSString *browseId; //optional
@property (nonatomic, strong) NSString *continuationToken;
@property (nonatomic, strong) NSString *params;

+ (KBSection *)defaultSection;
- (BOOL)isLoaded;
- (CGFloat)imageWidth;
- (CGFloat)imageHeight;
- (CGSize)imageSize;
- (SectionType)sectionType;
- (void)addResult:(KBYTSearchResult *)result;
- (void)addResults:(NSArray <KBYTSearchResult *>*)results;
- (instancetype)initWithSectionDictionary:(NSDictionary *)dict;

@end
