//
//  NSDictionary+serialize.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 7/10/14.
//  Copyright (c) 2014 Kevin Bradley. All rights reserved.
//

#import "NSDictionary+serialize.h"
#import "NSObject+Additions.h"
@implementation NSNull (science)

- (BOOL)boolValue {
    
    return false;
}

@end

@implementation NSDictionary (serialize)

- (NSMutableDictionary *)convertDictionaryToObjects {
    NSMutableDictionary *_newDict = [NSMutableDictionary new];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            _newDict[key] = [NSObject objectFromDictionary:obj usingClass:NSDictionary.class];
        } else if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
            _newDict[key] = obj;
        } else if ([obj isKindOfClass:NSArray.class]){
            _newDict[key] = [obj convertArrayToObjects];
        }
    }];
    return _newDict;
}

- (NSMutableDictionary *)convertObjectsToDictionaryRepresentations {
    NSMutableDictionary *_newDict = [NSMutableDictionary new];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //DLog(@"processing key: %@", key);
        if ([obj isKindOfClass:NSArray.class]){
            _newDict[key] = [obj convertArrayToDictionaries];
        } else if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
            _newDict[key] = obj;
        } else{
            _newDict[key] = [obj dictionaryRepresentation];
        }
    }];
    return _newDict;
}

@end

@implementation NSArray (serialize)

- (NSMutableArray *)convertArrayToObjects {
    __block NSMutableArray *_newArray = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id newOjb = [NSObject objectFromDictionary:obj];
        [_newArray addObject:newOjb];
    }];
    return _newArray;
}

- (NSString *)stringFromArray {
    NSString *error = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
#pragma clang diagnostic pop
    NSString *s=[[NSString alloc] initWithData:xmlData encoding: NSUTF8StringEncoding];
    return s;
}

- (NSMutableArray *)convertArrayToDictionaries {
    __block NSMutableArray *_newArray = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            [_newArray addObject:obj];
        } else {
            [_newArray addObject:[obj dictionaryRepresentation]];
        }
    }];
    return _newArray;
}

- (id)objectOfType:(Class)classType {
    
    __block id foundObject = nil;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        if ([obj isMemberOfClass:classType]){
            foundObject = obj;
            *stop = TRUE;
        }
    }];
    return foundObject;
}


- (NSArray *)reverseArray {
    return [[self reverseObjectEnumerator] allObjects];
}

@end
