//
//  KBContextMenuRepresentation.m
//  Ethereal
//
//  Created by kevinbradley on 2/25/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "KBContextMenuRepresentation.h"
#import "KBAction.h"

@interface KBContextMenuRepresentation()
@property (nonatomic, weak) KBMenu *menu;
@end

@implementation KBContextMenuRepresentation

@synthesize sections = _sections;
@synthesize menuElements = _menuElements;

- (id)initWithMenu:(KBMenu *)menu {
    self = [super init];
    if (self) {
        _menuElements = [menu children];
        [self _buildMenuSectionsWithMenuElements:_menuElements ofMenu:menu];;
    }
    return self;
}

+ (instancetype)representationForMenu:(KBMenu *)menu {
    KBContextMenuRepresentation *rep = [[KBContextMenuRepresentation alloc] initWithMenu:menu];
    return rep;
}

- (void)_buildMenuSectionsWithMenuElements:(NSArray *)elements ofMenu:(KBMenu *)menu{
    __block NSMutableArray *sections = [NSMutableArray new];
    [menu.children enumerateObjectsUsingBlock:^(KBMenuElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isMemberOfClass:KBAction.class]){
            KBContextMenuSection *section = [KBContextMenuSection new];
            section.items = menu.visibleChildren;
            section.title = menu.title;
            section.singleSelection = (menu.options & KBMenuOptionsSingleSelection) != 0;
            [sections addObject:section];
            *stop = true;
        } else if ([obj isMemberOfClass:KBMenu.class]) {
            KBMenu *menuObj = (KBMenu *)obj;
            KBContextMenuSection *section = [KBContextMenuSection new];
            section.items = menuObj.visibleChildren;
            section.title = menuObj.title;
            section.singleSelection = (menuObj.options & KBMenuOptionsSingleSelection) != 0;
            [sections addObject:section];
        }
    }];
    _sections = sections;
}

@end
