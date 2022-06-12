//
//  KBMenuElement.m
//  Ethereal
//
//  Created by Kevin Bradley on 2/24/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "KBMenuElement.h"

@interface KBMenuElement() {
    UIImage *_image;
    NSString *_title;
}
@end

@implementation KBMenuElement

- (void)_setImage:(UIImage *)image {
    _image = image;
}

- (UIImage *)image {
    return _image;
}

- (void)_setTitle:(NSString *)title {
    _title = title;
}

- (NSString *)title {
    return _title;
}
/*
- (NSString *)description {
    NSString *sup = [super description];
    return [NSString stringWithFormat:@"%@ title: %@", sup, _title];
}
*/
- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    KBMenuElement *clone = [[KBMenuElement alloc] init];
    [clone setSubtitle:self.subtitle];
    [clone _setTitle:self.title];
    [clone _setImage:self.image];
    return clone;
}

@end
