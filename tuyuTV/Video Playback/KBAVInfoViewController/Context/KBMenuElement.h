//
//  KBMenuElement.h
//  Ethereal
//
//  Created by Kevin Bradley on 2/24/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;

typedef NS_ENUM(NSInteger, KBMenuElementState) {
    KBMenuElementStateOff,
    KBMenuElementStateOn,
    KBMenuElementStateMixed
} NS_SWIFT_NAME(KBMenuElement.State);

typedef NS_OPTIONS(NSUInteger, KBMenuElementAttributes) {
    KBMenuElementAttributesDisabled     = 1 << 0,
    KBMenuElementAttributesDestructive  = 1 << 1,
    KBMenuElementAttributesHidden       = 1 << 2,
    KBMenuElementAttributesToggle       = 1 << 3,
    
} NS_SWIFT_NAME(KBMenuElement.Attributes);

NS_ASSUME_NONNULL_BEGIN

@interface KBMenuElement : NSObject<NSCopying>

/// The element's title.
@property (nonatomic, readonly) NSString *title;

/// The element's subtitle.
@property (nonatomic, nullable, copy) NSString *subtitle;

/// Image to be displayed alongside the element's title.
@property (nonatomic, nullable, readonly) UIImage *image;

@end

NS_ASSUME_NONNULL_END
