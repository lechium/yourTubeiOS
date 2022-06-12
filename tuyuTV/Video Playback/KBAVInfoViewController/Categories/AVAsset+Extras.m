//
//  AVAsset+Extras.m
//  Ethereal
//
//  Created by kevinbradley on 1/16/22.
//  Copyright © 2022 nito. All rights reserved.
//

#import "AVAsset+Extras.h"

@implementation AVAsset (Extras)

- (BOOL)hasClosedCaptions {
    __block BOOL returnedValue = false;
    AVMediaSelectionGroup *group = [self mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"mediaType == %@",AVMediaTypeClosedCaption];
    AVMediaSelectionOption *opt = [[group.options filteredArrayUsingPredicate:pred] firstObject];
    NSLog(@"[Ethereal]: hasClosedCaptions opt: %@", opt);
    [group.options enumerateObjectsUsingBlock:^(AVMediaSelectionOption * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.mediaType == AVMediaTypeClosedCaption) {
            returnedValue = true;
            *stop = true;
        }
    }];
    return returnedValue;
}

- (BOOL)isHD {
    AVAssetTrack *track = [[self tracksWithMediaCharacteristic:AVMediaCharacteristicVisual] firstObject];
    CGSize trackSize = [track naturalSize];
    return trackSize.width >= 1280;
}
@end
