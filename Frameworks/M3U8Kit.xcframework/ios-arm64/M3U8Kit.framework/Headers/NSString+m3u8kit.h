//
//  NSString+m3u8.h
//  M3U8Kit
//
//  Created by Oneday on 13-1-11.
//  Copyright (c) 2013年 0day. All rights reserved.
//

#import <Foundation/Foundation.h>

@class M3U8ExtXStreamInfList, M3U8SegmentInfoList;
@interface NSString (m3u8kit)

- (BOOL)m3u_isExtendedM3Ufile;

- (BOOL)m3u_isMasterPlaylist;
- (BOOL)m3u_isMediaPlaylist;

- (M3U8SegmentInfoList *)m3u_segmentInfoListValueRelativeToURL:(NSString *)baseURL;
- (NSString *)m3u_stringByTrimmingQuoteMark;
/**
 @return "key=value" transform to dictionary
 */
- (NSMutableDictionary *)m3u_attributesFromAssignment;

@end
