
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SQFContrastingColorMethod) {
    SQFContrastingColorFiftyPercentMethod,
    SQFContrastingColorYIQMethod
};

@interface UIColor (Additions)

- (UIColor*)changeBrightnessByAmount:(CGFloat)amount;
+ (UIColor*)changeBrightness:(UIColor*)color amount:(CGFloat)amount;
- (NSString *)hexValue;
+ (UIColor *)coolBlueColor;
+ (UIColor *)tealColor;
+ (UIColor *)aquaColor;
+ (UIColor *)ceruleanBlue;
+ (UIColor *)darkRedColor;
+ (UIColor *)oceanColor;
+ (UIColor *)nickelColor;
+ (UIColor *)nitoRedColor;
+ (UIColor *)colorFromHex:(NSString *)s;
- (UIColor *)sqf_contrastingColorWithMethod:(SQFContrastingColorMethod)method;
+ (UIColor *)ourLightTextColor;
+ (UIColor *)ourDarkTextColor;
@end
