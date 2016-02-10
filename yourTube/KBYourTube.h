//
//  KBYourTube.h
//  yourTube
//
//  Created by Kevin Bradley on 12/21/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppSupport/CPDistributedMessagingCenter.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYourTube+Categories.h"
#import "APDeviceController.h"
#import "KBYTMessagingCenter.h"
// Logging


@interface YTKBPlayerViewController : AVPlayerViewController

@end

@interface YTBrowserHelper : NSObject

+ (id)sharedInstance;
- (void)importFileWithJO:(NSString *)theFile duration:(NSInteger)duration;
- (void)fixAudio:(NSString *)theFile volume:(NSInteger)volume completionBlock:(void(^)(NSString *newFile))completionBlock;
- (void)fileCopyTest:(NSString *)theFile;

@end


@interface KBYTMedia : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *keywords;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSDictionary *images;
@property (nonatomic, strong) NSArray *streams;
@property (nonatomic, strong) NSString *details; //description

@end

@interface KBYTSearchResult: NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *age;
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *details;
@property (nonatomic, strong) KBYTMedia *media;


- (id)initWithDictionary:(NSDictionary *)resultDict;

@end

@interface KBYTStream : NSObject

@property (readwrite, assign) BOOL multiplexed;
@property (nonatomic, strong) NSString *outputFilename;
@property (nonatomic, strong) NSString *quality;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *format;
@property (nonatomic, strong) NSNumber *height;
@property (readwrite, assign) NSInteger itag;
@property (nonatomic, strong) NSString *s;
@property (nonatomic, strong) NSString *extension;
@property (nonatomic, strong) NSURL *url;
@property (readwrite, assign) BOOL playable;
@property (nonatomic, assign) KBYTStream *audioStream; //will be empty if its multiplexed

- (id)initWithDictionary:(NSDictionary *)streamDict;
- (NSDictionary *)dictionaryValue;

@end


@interface KBYourTube : NSObject
{
    NSInteger bestTag;
}

@property (nonatomic, strong) APDeviceController *deviceController;
@property (nonatomic, strong) NSString *yttimestamp;
@property (nonatomic, strong) NSString *ytkey;
@property (nonatomic, strong) NSString *airplayIP;


+ (id)sharedInstance;

- (NSString *)videoDescription:(NSString *)videoID;

/**
 
 searchQuery is just a basic unescaped search string, this will return a dictionary with 
 results, pageCount, resultCount. Beware this is super fragile, if youtube website changes
 this will almost definitely break. that being said its MUCH quicker then getSearchResults
 
 */

- (void)youTubeSearch:(NSString *)searchQuery
           pageNumber:(NSInteger)page
      completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
         failureBlock:(void(^)(NSString* error))failureBlock;


- (void)getSearchResults:(NSString *)searchQuery
              pageNumber:(NSInteger)page
         completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
            failureBlock:(void(^)(NSString* error))failureBlock;

- (void)getVideoDetailsForID:(NSString*)videoID
             completionBlock:(void(^)(KBYTMedia* videoDetails))completionBlock
                failureBlock:(void(^)(NSString* error))failureBlock;


- (NSString *)decodeSignature:(NSString *)theSig;

+ (NSDictionary *)formatFromTag:(NSInteger)tag;
- (void)playMedia:(KBYTMedia *)media ToDeviceIP:(NSString *)deviceIP;
- (void)airplayStream:(NSString *)stream ToDeviceIP:(NSString *)deviceIP;
- (void)pauseAirplay;
- (NSInteger)airplayStatus;
@end
