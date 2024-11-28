//
//  KBModelItem.m
//  tvOSGridTest
//
//  Created by Kevin Bradley on 4/16/23.
//

#import "KBModelItem.h"
//#import "Defines.h"
@implementation KBModelItem

-(instancetype)initWithTitle:(NSString *)title imagePath:(NSString *)path uniqueID:(NSString *)unique {
    self = [super init];
    if (self) {
        _title = title;
        _imagePath = path;
        _uniqueID = unique;
    }
    return self;
}

- (NSString *)description {
    NSString *og = [super description];
    return [NSString stringWithFormat:@"%@ title: %@ id: %@", og, self.title, self.uniqueID];
}

@end
