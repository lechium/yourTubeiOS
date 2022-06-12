//
//  KBMenu.h
//  Ethereal
//
//  Created by Kevin Bradley on 2/24/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KBMenuElement.h"
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, KBMenuOptions) {
    /// Show children inline in parent, instead of hierarchically
    KBMenuOptionsDisplayInline  = 1 << 0,

    /// Indicates whether the menu should be rendered with a destructive appearance in its parent
    KBMenuOptionsDestructive    = 1 << 1,
    
    /// Indicates whether the menu (and any submenus) should only allow a single "on" menu item.
    KBMenuOptionsSingleSelection = 1 << 5,
    
} NS_SWIFT_NAME(KBMenu.Options);

NS_ASSUME_NONNULL_BEGIN

@interface KBMenu : KBMenuElement

/// Options.
@property (nonatomic, readonly) KBMenuOptions options;

/// The menu's sub-elements and sub-menus. On iOS 14.0, elements of your own menus are mutable, -copying a menu will produce mutable elements, and UIKit will take immutable copies of menus it receives. Prior to iOS 14.0, menus are always fully immutable.
@property (nonatomic, readonly) NSArray<KBMenuElement *> *children;

/// The element(s) in the menu and sub-menus that have an "on" menu item state.
@property (nonatomic, readonly) NSArray <KBMenuElement *> *selectedElements;

- (NSArray *)visibleChildren;

/*!
 * @abstract Creates a KBMenu with an empty title, nil image, automatically generated identifier, and default options.
 *
 * @param children    The menu's action-based sub-elements and sub-menus.
 *
 * @return A new KBMenu.
 */
+ (KBMenu *)menuWithChildren:(NSArray<KBMenuElement *> *)children;

/*!
 * @abstract Creates a KBMenu with the given arguments.
 *
 * @param title       The menu's title.
 * @param children    The menu's action-based sub-elements and sub-menus.
 *
 * @return A new KBMenu.
 */
+ (KBMenu *)menuWithTitle:(NSString *)title children:(NSArray<KBMenuElement *> *)children;

/*!
 * @abstract Creates a KBMenu with the given arguments.
 *
 * @param title       The menu's title.
 * @param image       Image to be displayed alongside the menu's title.
 * @param identifier  The menu's unique identifier. Pass nil to use an auto-generated identifier.
 * @param options     The menu's options.
 * @param children    The menu's action-based sub-elements and sub-menus.
 *
 * @return A new KBMenu.
 */
+ (KBMenu *)menuWithTitle:(NSString *)title
                    image:(nullable UIImage *)image
               identifier:(nullable NSString*)identifier
                  options:(KBMenuOptions)options
                 children:(NSArray<KBMenuElement *> *)children;

@end

NS_ASSUME_NONNULL_END
