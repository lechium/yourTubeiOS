
#import "UIColor+Additions.h"

@implementation UIColor (Additions)


- (UIColor*)changeBrightnessByAmount:(CGFloat)amount
{
    
    CGFloat hue, saturation, brightness, alpha;
    if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        brightness += (amount-1.0);
        brightness = MAX(MIN(brightness, 1.0), 0.0);
        return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }
    
    CGFloat white;
    if ([self getWhite:&white alpha:&alpha]) {
        white += (amount-1.0);
        white = MAX(MIN(white, 1.0), 0.0);
        return [UIColor colorWithWhite:white alpha:alpha];
    }
    
    return nil;
}

+ (UIColor*)changeBrightness:(UIColor*)color amount:(CGFloat)amount
{
    
    CGFloat hue, saturation, brightness, alpha;
    if ([color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
        brightness += (amount-1.0);
        brightness = MAX(MIN(brightness, 1.0), 0.0);
        return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }
    
    CGFloat white;
    if ([color getWhite:&white alpha:&alpha]) {
        white += (amount-1.0);
        white = MAX(MIN(white, 1.0), 0.0);
        return [UIColor colorWithWhite:white alpha:alpha];
    }
    
    return nil;
}

+ (UIColor *)colorFromHex:(NSString *)s
{
    NSScanner *scan = [NSScanner scannerWithString:[s substringToIndex:2]];
    unsigned int r = 0, g = 0, b = 0;
    [scan scanHexInt:&r];
    scan = [NSScanner scannerWithString:[[s substringFromIndex:2] substringToIndex:2]];
    [scan scanHexInt:&g];
    scan = [NSScanner scannerWithString:[s substringFromIndex:4]];
    [scan scanHexInt:&b];
    
    
    return [UIColor colorWithRed:(float)r/255 green:(float)g/255 blue:(float)b/255 alpha:1.0];
}

- (NSString *)hexValue
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}



- (UIColor *)sqf_contrastingColorWithMethod:(SQFContrastingColorMethod)method
{
    switch (method) {
            
        case SQFContrastingColorFiftyPercentMethod:
            return [self sqf_contrastingColorFiftyPercentMethod];
            break;
            
        case SQFContrastingColorYIQMethod:
            return [self sqf_contrastingColorYIQMethod];
    }
}

- (UIColor *)sqf_contrastingColorFiftyPercentMethod
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSInteger redDecimal = (NSInteger)(red * 255);
    NSInteger greenDecimal = (NSInteger)(green * 255);
    NSInteger blueDecimal = (NSInteger)(blue * 255);
    
    NSString *hex = [NSString stringWithFormat:@"%02x%02x%02x", (unsigned int)redDecimal, (unsigned int)greenDecimal, (unsigned int)blueDecimal];
    
    unsigned int result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    [scanner scanHexInt:&result];
    
    return (result > 0xffffff / 2) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (UIColor *)sqf_contrastingColorYIQMethod
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CGFloat yiq = ((( red * 255 ) * 299 ) + (( green * 255 ) * 587 ) + (( blue * 255 ) * 114 )) / 1000;
    
    return (yiq >= 128.0) ? [UIColor blackColor] : [UIColor whiteColor];
}


@end
