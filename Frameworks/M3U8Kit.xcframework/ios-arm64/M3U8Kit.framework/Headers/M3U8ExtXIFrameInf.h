//
//  M3U8ExtXIFrameInf.h
//  ILSLoader
//
//  Created by Jin Sun on 13-4-15.
//  Copyright (c) 2013年 iLegendSoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "M3U8ExtXStreamInf.h"
/*!
 @class M3U8SegmentInfo
 @abstract This is the class indicates #EXT-X-I-FRAME-STREAM-INF:<attribute-list> + <URI> in master playlist file.
 
 /// EXT-X-I-FRAME-STREAM-INF

 @format    #EXT-X-I-FRAME-STREAM-INF:<attribute-list>
 <URI>
 @example   #EXT-X-I-FRAME-STREAM-INF:BANDWIDTH=65531,PROGRAM-ID=1,CODECS="avc1.42c00c",RESOLUTION=320x180,URI="/talks/769/video/64k_iframe.m3u8?sponsor=Ripple"
 
 @note      All attributes defined for the EXT-X-STREAM-INF tag (Section 3.4.10) are also defined for the EXT-X-I-FRAME-STREAM-INF tag, except for the AUDIO, SUBTITLES and CLOSED-CAPTIONS attributes.
            The EXT-X-I-FRAME-STREAM-INF tag MUST NOT appear in a Media Playlist.
 

 */
@interface M3U8ExtXIFrameInf : NSObject

@property (nonatomic, readonly, assign) NSInteger bandwidth;
@property (nonatomic, readonly, assign) NSInteger averageBandwidth;
@property (nonatomic, readonly, assign) NSInteger programId;        // removed by draft 12
@property (nonatomic, readonly, copy) NSArray *codecs;
@property (nonatomic, readonly) MediaResoulution resolution;
@property (nonatomic, readonly, copy) NSString *video;
@property (nonatomic, readonly, copy) NSURL   *URI;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSURL *)m3u8URL; // the absolute url

- (NSString *)m3u8PlainString;

@end
