//
//  KBSection.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 12/23/17.
//  Copyright © 2017 nito. All rights reserved.
//

//#import "Defines.h"
#import "KBSection.h"
#import "KBModelItem.h"
#import "NSObject+Additions.h"
#import "KBYourTube.h"

@implementation KBSection

- (instancetype)initWithSectionDictionary:(NSDictionary *)dict {
    //DLog(@"dict: %@", dict);
    self = [super init];
    if (self) {
        _title = dict[@"title"];
        _order = [dict[@"order"] integerValue];
        _infinite = [dict[@"infinite"] boolValue];
        _autoScroll = [dict[@"autoScroll"] boolValue];
        _type = dict[@"type"];
        _size = dict[@"size"];
        _className = dict[@"className"];
        if (!_className) {
            _className = @"KBModelItem";
        }
        [self parseItems:dict[@"items"]];
    }
    return self;
}

+ (KBSection *)defaultSection {
    KBSection *section = [KBSection new];
    section.infinite = false;
    section.autoScroll = false;
    section.className = @"KBSection";
    section.size = @"320x240";
    section.type = @"standard";
    section.channelDisplayType = ChannelDisplayTypeShelf;
    return section;
}

- (BOOL)isLoaded {
    return self.content.count > 0;
}

- (CGSize)imageSize {
    return CGSizeMake(self.imageWidth, self.imageHeight);
}

- (CGFloat)imageWidth {
    return [[[[self size] componentsSeparatedByString:@"x"] firstObject] floatValue];
}

- (CGFloat)imageHeight {
    return [[[[self size] componentsSeparatedByString:@"x"] lastObject] floatValue];
}

- (SectionType)sectionType {
    if ([self.type isEqualToString:@"banner"]) {
        return SectionTypeBanner;
    } else if ([self.type isEqualToString:@"standard"]) {
        return SectionTypeStandard;
    }
    return SectionTypeStandard;
}

- (void)parseItems:(NSArray <NSDictionary *> *)items {
    //LOG_SELF;
    __block NSMutableArray <KBCollectionItemProtocol>*newItems = [NSMutableArray new];
    [items enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSError *error = nil;
        KBModelItem *model = [NSObject objectFromDictionary:obj usingClass:objc_getClass([self.className UTF8String])];
        if (error == nil) {
            [newItems addObject:model];
        }
    }];
    _content = newItems;
}

- (void)addResult:(KBYTSearchResult *)result {
    if (!result) return;
    NSLog(@"adding result: %@", result);
    NSMutableArray *_mutContent = [[self content] mutableCopy];
    if (!_mutContent) _mutContent = [NSMutableArray new];
    [_mutContent addObject:result];
    self.content = _mutContent;
}

- (void)addResults:(NSArray <KBYTSearchResult *>*)results {
    if (!results) return;
    //NSLog(@"adding result: %@", result);
    NSMutableArray *_mutContent = [[self content] mutableCopy];
    if (!_mutContent) _mutContent = [NSMutableArray new];
    [_mutContent addObjectsFromArray:results];
    self.content = _mutContent;
}

- (NSString *)description {
    //NSString *superDesc = [super description];
    return [NSString stringWithFormat:@"Title: %@ Items: %@", self.title, self.content];
}

@end
