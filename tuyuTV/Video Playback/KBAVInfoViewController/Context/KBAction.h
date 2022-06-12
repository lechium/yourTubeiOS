//
//  KBAction.h
//  Ethereal
//
//  Created by Kevin Bradley on 2/24/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "KBMenuElement.h"

@class KBAction;

/*
 typedef returnType (^TypeName)(parameterTypes);
 TypeName blockName = ^returnType(parameters) {...};
 */

NS_ASSUME_NONNULL_BEGIN
typedef void (^KBActionHandler)(__kindof KBAction *action);

@interface KBAction : KBMenuElement

/// Short display title.
@property (nonatomic, copy) NSString *title;

/// Image that can appear next to this action.
@property (nullable, nonatomic, copy) UIImage *image;

/// Elaborated title, if any.
@property (nullable, nonatomic, copy) NSString *discoverabilityTitle;

/// This action's identifier.
@property (nonatomic, readonly) NSString *identifier;

/// This action's style.
@property (nonatomic) KBMenuElementAttributes attributes;

/// State that can appear next to this action.
@property (nonatomic) KBMenuElementState state;

/// If available, the object on behalf of which the actionHandler is called.
@property (nonatomic, readonly, nullable) id sender;

@property (nonatomic, nullable) KBActionHandler handler;

/*!
 * @abstract Creates a KBAction with an empty title, nil image, and automatically generated identifier
 *
 * @param handler  Handler block. Called when the user selects the action.
 *
 * @return A new KBAction.
 */
+ (instancetype)actionWithHandler:(KBActionHandler)handler;

/*!
 * @abstract Creates a KBAction with the given arguments.
 *
 * @param title    The action's title.
 * @param image    Image that can appear next to this action, if needed.
 * @param identifier  The action's identifier. Pass nil to use an auto-generated identifier.
 * @param handler  Handler block. Called when the user selects the action.
 *
 * @return A new KBAction.
 */
+ (instancetype)actionWithTitle:(NSString *)title
                          image:(nullable UIImage *)image
                     identifier:(nullable NSString *)identifier
                        handler:(KBActionHandler)handler;


@end

NS_ASSUME_NONNULL_END
