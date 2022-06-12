//
//  KBAction.m
//  Ethereal
//
//  Created by Kevin Bradley on 2/24/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "KBAction.h"

@interface KBMenuElement (private)
- (void)_setTitle:(NSString *)title;
- (void)_setImage:(UIImage *)image;
@end

@implementation KBAction

@dynamic title, image;

- (void)setTitle:(NSString *)title {
    [self _setTitle:title];
}

- (void)setImage:(UIImage *)image {
    [self _setImage:image];
}

- (NSString *)description {
    NSString *sup = [super description];
    return [NSString stringWithFormat:@"%@ title: %@ state: %lu", sup, self.title, _state];
}


+ (instancetype)actionWithTitle:(NSString *)title
                          image:(nullable UIImage *)image
                     identifier:(nullable NSString *)identifier
                        handler:(KBActionHandler)handler {
    KBAction *action = [KBAction new];
    [action setTitle:title];
    [action setImage:image];
    [action setHandler:handler];
    return action;
}

+ (KBAction *)actionWithHandler:(KBActionHandler)actionHandler {
    KBAction *action = [KBAction new];
    [action setHandler:actionHandler];
    return action;
}

@end
