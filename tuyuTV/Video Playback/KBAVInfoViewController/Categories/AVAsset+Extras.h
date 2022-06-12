//
//  AVAsset+Extras.h
//  Ethereal
//
//  Created by kevinbradley on 1/16/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (Extras)
- (BOOL)isHD;
- (BOOL)hasClosedCaptions;
@end

NS_ASSUME_NONNULL_END
