//
//  UIStackView+Helper.m
//  Ethereal
//
//  Created by Kevin Bradley on 7/16/20.
//  Copyright © 2020 nito. All rights reserved.
//

#import "UIStackView+Helper.h"

@implementation UIStackView (Helper)

- (void)removeAllArrangedSubviews {
    [[self arrangedSubviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj respondsToSelector:@selector(removeAllArrangedSubviews)]){
            [obj removeAllArrangedSubviews];
        }
        [self removeArrangedSubview:obj];
    }];
}

- (void)setArrangedViews:(NSArray *)views {
    if ([self arrangedSubviews].count > 0){
        [self removeAllArrangedSubviews];
    }
    [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addArrangedSubview:obj];
    }];
}

@end

