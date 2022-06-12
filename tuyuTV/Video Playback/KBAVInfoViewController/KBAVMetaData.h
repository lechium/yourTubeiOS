#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KBAVMetaData: NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) NSString *summary;
@property (readwrite, assign) NSInteger duration;
@property (nonatomic) NSURL *imageURL;
@property (nonatomic) UIImage *image;
@property (nonatomic) NSString *genre;
@property (nonatomic) NSString *year;
@property (readwrite, assign) BOOL isHD;
@property (readwrite, assign) BOOL hasCC;
@end

NS_ASSUME_NONNULL_END
