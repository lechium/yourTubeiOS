//
//  UIImage+Template.m
//  WondriumTV
//
//  Created by Kevin Bradley on 1/22/22.
//  Copyright © 2022 The Teaching Company. All rights reserved.
//

#import "UIImage+Template.h"

@implementation UIImage (Template)

+ (UIImage *)templateImageNamed:(NSString *)imageName {
    return [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end
