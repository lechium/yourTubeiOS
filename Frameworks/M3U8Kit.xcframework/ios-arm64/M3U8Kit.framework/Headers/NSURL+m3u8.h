//
//  NSURL+m3u8.h
//  M3U8Kit
//
//  Created by Frank on 16/06/2017.
//

#import <Foundation/Foundation.h>

@class M3U8PlaylistModel;
@interface NSURL (m3u8)

/* for some reason the m3u8URL from appears complete when logged out, but its 'path' value is incorrect and is missing the last path component, this reconstructs the URL without a 'baseURL' so the 'absoluteURL' or 'absoluteString' returns the proper path. ie layer_3_x15ae724f9359493b9699514a833cd94b/30310_02__055017_2083254851776_mp4_video_640x360_311000_primary_audio_eng_1_x15ae724f9359493b9699514a833cd94b_3.m3u8 -- https://website.net/Company/185/711/2083252803943/1665503927621
 
 for some reason the 'absoluteString' value of this URL is 'https://website.net/Company/185/711/2083252803943/layer_3_x15ae724f9359493b9699514a833cd94b/30310_02__055017_2083254851776_mp4_video_640x360_311000_primary_audio_eng_1_x15ae724f9359493b9699514a833cd94b_3.m3u8'
 
 '1665503927621' is missing so playing or loading these particular URL's doesn't work.
 
*/

- (NSURL *)m3u_properM3UURL;

/**
 return baseURL if exists.
 if baseURL is nil, return [scheme://host]

 @return URL
 */
- (NSURL *)m3u_realBaseURL;

/**
 Load the specific url and get result model with completion block.
 
 @param completion when the url resource loaded, completion block could get model and detail error;
 */
- (void)m3u_loadAsyncCompletion:(void (^)(M3U8PlaylistModel *model, NSError *error))completion;

@end
