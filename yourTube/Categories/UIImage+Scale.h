//
//  UIImage+UIImage_Scale.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 1/27/16.
//
//

#import <UIKit/UIKit.h>


@interface UIImage (Scale)
+ (id)symbolImageNamed:(id)arg1 size:(long long)arg2 weight:(long long)arg3 compatibleWithFontSize:(double)arg4;
- (UIImage *)scaledImagedToSize:(CGSize)newSize;
+ (NSData *)pngDataForLargeSymbolImage:(NSString *)symbolImageName;
@end
