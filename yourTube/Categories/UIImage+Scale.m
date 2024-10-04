//
//  UIImage+UIImage_Scale.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 1/27/16.
//
//

#import "UIImage+Scale.h"

@implementation UIImage (scale)

+ (NSData *)pngDataForLargeSymbolImage:(NSString *)symbolImageName {
    UIImage *image = [UIImage symbolImageNamed:symbolImageName size:3 weight:UIFontWeightRegular compatibleWithFontSize:100];
    return UIImagePNGRepresentation(image);
}

+ (void)writeFile:(NSString *)file ForLargePNGImageNamed:(NSString *)imageName {
    NSData *data = [UIImage pngDataForLargeSymbolImage:imageName];
    [data writeToFile:file atomically:true];
}

- (UIImage *)scaledImagedToSize:(CGSize)newSize
{
    CGSize scaledSize = newSize;
    CGFloat scaleFactor = 1.0;
    if (self.size.width > self.size.height ) {
        scaleFactor = self.size.width / self.size.height;
        scaledSize.width = newSize.width;
        scaledSize.height = newSize.width / scaleFactor;
    } else {
        scaleFactor = self.size.height / self.size.width;
        scaledSize.height = newSize.height;
        scaledSize.width = newSize.width / scaleFactor;
    }
    UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0);
    CGRect scaledImagedRect = CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height);
    [self drawInRect:scaledImagedRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

/*
 func scaledImagetoSize(newSize: CGSize) -> UIImage {
 
 var scaledSize = newSize
 var scaleFactor: CGFloat = 1.0
 
 if self.size.width > self.size.height {
 scaleFactor = self.size.width / self.size.height
 scaledSize.width = newSize.width
 scaledSize.height = newSize.width / scaleFactor
 } else {
 scaleFactor = self.size.height / self.size.width
 scaledSize.height = newSize.height
 scaledSize.width = newSize.width / scaleFactor
 }
 
 UIGraphicsBeginImageContextWithOptions(scaledSize, false, 0.0)
 let scaledImageRect = CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height)
 [self .drawInRect(scaledImageRect)]
 let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
 UIGraphicsEndImageContext()
 
 return scaledImage
 }
 
 */

@end
