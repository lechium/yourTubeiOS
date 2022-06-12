//
//  KBContextMenuRepresentation.h
//  Ethereal
//
//  Created by kevinbradley on 2/25/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBMenu.h"
#import "KBContextMenuSection.h"
NS_ASSUME_NONNULL_BEGIN

@interface KBContextMenuRepresentation : NSObject {
    NSArray *_menuElements;    // 16 = 0x10
    NSArray *_sections;    // 24 = 0x18
}

@property(readonly, copy, nonatomic) NSArray <KBContextMenuSection *>*sections; // @synthesize sections=_sections;
@property(readonly, copy, nonatomic) NSArray *menuElements; // @synthesize menuElements=_menuElements;
+ (instancetype)representationForMenu:(KBMenu *)menu;
- (id)initWithMenu:(KBMenu *)menu;
@end

NS_ASSUME_NONNULL_END
