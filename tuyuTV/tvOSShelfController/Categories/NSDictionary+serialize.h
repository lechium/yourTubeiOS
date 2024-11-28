//
//  NSDictionary+serialize.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 7/10/14.
//  Copyright (c) 2014 Kevin Bradley. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface NSNull (science)
- (BOOL)boolValue;
@end
@interface NSDictionary (serialize)

- (NSMutableDictionary *)convertDictionaryToObjects;
- (NSMutableDictionary *)convertObjectsToDictionaryRepresentations;

@end

@interface NSArray (serialize)

- (NSMutableArray *)convertArrayToObjects;
- (NSString *)stringFromArray;
- (NSMutableArray *)convertArrayToDictionaries;

- (id)objectOfType:(Class)classType;
- (NSArray *)reverseArray;
@end





