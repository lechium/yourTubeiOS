//
//  KBYourTube.h
//  yourTube
//
//  Created by Kevin Bradley on 12/21/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppSupport/CPDistributedMessagingCenter.h"

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

// Logging
#define LOG_SELF        NSLog(@"%@ %@", self, NSStringFromSelector(_cmd))

@interface YTBrowserHelper : NSObject

+ (id)sharedInstance;
- (void)importFileWithJO:(NSString *)theFile duration:(NSInteger)duration;
- (void)fixAudio:(NSString *)theFile volume:(NSInteger)volume completionBlock:(void(^)(NSString *newFile))completionBlock;
- (void)fileCopyTest:(NSString *)theFile;

@end

@interface NSDictionary (strings)

- (NSString *)stringValue;

@end

@interface NSArray (strings)

- (NSString *)stringFromArray;

@end

@interface NSString (TSSAdditions)

- (id)dictionaryValue;

@end


@interface NSURL (QSParameters)
- (NSArray *)parameterArray;
- (NSDictionary *)parameterDictionary;
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

@interface NSObject  (convenience)

- (NSString *)applicationSupportFolder;
- (NSString *)downloadFolder;
- (NSMutableDictionary *)parseFlashVars:(NSString *)vars;
- (NSArray *)matchesForString:(NSString *)string withRegex:(NSString *)pattern;
- (NSMutableDictionary *)dictionaryFromString:(NSString *)string withRegex:(NSString *)pattern;

@end

@interface NSString  (SplitString)

- (NSArray *)splitString;

@end
#import "APDeviceController.h"

@interface KBYourTube : NSObject
{
    NSInteger bestTag;
}

@property (nonatomic, strong) APDeviceController *deviceController;
@property (nonatomic, strong) NSString *yttimestamp;
@property (nonatomic, strong) NSString *ytkey;


+ (id)sharedInstance;

- (void)getVideoDetailsForID:(NSString*)videoID
             completionBlock:(void(^)(KBYTMedia* videoDetails))completionBlock
                failureBlock:(void(^)(NSString* error))failureBlock;


- (void)extractAudio:(NSString *)theFile
     completionBlock:(void(^)(NSString *newFile))completionBlock;
- (NSString *)decodeSignature:(NSString *)theSig;

+ (NSDictionary *)formatFromTag:(NSInteger)tag;
- (void)playMedia:(KBYTMedia *)media ToDeviceIP:(NSString *)deviceIP;
- (void)airplayStream:(KBYTStream *)stream ToDeviceIP:(NSString *)deviceIP;
- (void)pauseAirplay;
- (NSInteger)airplayStatus;
@end
