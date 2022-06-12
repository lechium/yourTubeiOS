#import "backward.h"
#import "forward.h"
#import "gobackward.h"
#import "goforward.h"
#import "checkmark.h"
#import "hd.h"
#import "cc.h"
#import "audio.h"
#import "captions.h"
#import "appletv.h"
#import "tvhifi.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KBSliderImages.h"


@implementation KBSliderImages

#define SliderImage(base) ([self imageWithBytesNoCopy:(void *)(base) length:sizeof(base) scale:1.0])
#define SliderImageTemplate(base) ([SliderImage(base) imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate])

+ (UIImage *)imageWithBytesNoCopy:(void *)bytes length:(NSUInteger)length scale:(CGFloat)scale {
    NSData *data = [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
    return [UIImage imageWithData:data scale:scale];
}

+ (UIImage *)backwardsImage {
    return SliderImageTemplate(backward_fill_png);
}
+ (UIImage *)forwardsImage {
    return SliderImageTemplate(forward_fill_png);
}
+ (UIImage *)skipForwardsImage {
    return SliderImageTemplate(goforward_10_png);
}
+ (UIImage *)skipBackwardsImage {
    return SliderImageTemplate(gobackward_10_png);
}
+ (UIImage *)checkmarkImage {
    return SliderImageTemplate(checkmark_png);
}
+ (UIImage *)HDImage {
    return SliderImageTemplate(HD_png);
}
+ (UIImage *)CCImage {
    return SliderImageTemplate(CC_png);
}
+ (UIImage *)audioImage {
    return SliderImageTemplate(audio_png);
}
+ (UIImage *)captionsImage {
    return SliderImageTemplate(captions_png);
}
+(UIImage *)appletvImage {
    return SliderImageTemplate(appletv_png);
}
+(UIImage *)tvHifiImage {
    return SliderImageTemplate(tv_and_hifispeaker_fill_png);
}
@end
