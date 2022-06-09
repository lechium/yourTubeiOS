//
//  KBAirDropHelper.m
//  Ethereal
//
//  Created by kevinbradley on 9/19/21.
//  Copyright © 2021 nito. All rights reserved.
//

#import "KBAirDropHelper.h"
#import <UIKit/UIApplication.h>
@implementation KBAirDropHelper

+(void)airdropFile:(NSString *)file {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSString *path = [NSString stringWithFormat:@"airdropper://%@?sender=%@",[file stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[[NSBundle mainBundle] bundleIdentifier]];
    NSURL *URL = [NSURL URLWithString:path];
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}
#pragma clang diagnostic pop
@end
