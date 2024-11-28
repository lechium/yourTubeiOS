//
//  M3U8ExtXIFrameInfList.h
//  ILSLoader
//
//  Created by Jin Sun on 13-4-15.
//  Copyright (c) 2013年 iLegendSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "M3U8ExtXIFrameInf.h"

@interface M3U8ExtXIFrameInfList : NSObject

@property (nonatomic, assign ,readonly) NSUInteger count;

- (void)addExtXIFrameInf:(M3U8ExtXIFrameInf *)extIFrameInf;
- (M3U8ExtXIFrameInf *)xIFrameInfAtIndex:(NSUInteger)index;
- (M3U8ExtXIFrameInf *)firstXIFrameInf;
- (M3U8ExtXIFrameInf *)lastXIFrameInf;
- (NSArray <M3U8ExtXIFrameInf*> *)allStreams;

- (void)sortByBandwidthInOrder:(NSComparisonResult)order;

@end
