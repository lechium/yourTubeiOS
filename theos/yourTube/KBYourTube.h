//
//  KBYourTube.h
//  yourTube
//
//  Created by Kevin Bradley on 12/21/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);

// Logging
#define LOG_SELF        NSLog(@"%@ %@", self, NSStringFromSelector(_cmd))

@interface YTBrowserHelper : NSObject

+ (id)sharedInstance;
- (void)importFileWithJO:(NSString *)theFile duration:(NSInteger)duration;
- (void)fixAudio:(NSString *)theFile volume:(NSInteger)volume completionBlock:(void(^)(NSString *newFile))completionBlock;
- (void)fileCopyTest:(NSString *)theFile;

@end

@interface NSURL (QSParameters)
- (NSArray *)parameterArray;
- (NSDictionary *)parameterDictionary;
@end

@interface NSTask (convenience)

- (void)waitUntilExit;

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

@interface KBYourTube : NSObject
{
    NSInteger bestTag;
}

@property (nonatomic, strong) NSString *yttimestamp;
@property (nonatomic, strong) NSString *ytkey;


+ (id)sharedInstance;

- (void)getVideoDetailsForID:(NSString*)videoID
             completionBlock:(void(^)(KBYTMedia* videoDetails))completionBlock
                failureBlock:(void(^)(NSString* error))failureBlock;


- (void)fixAudio:(NSString *)theFile
          volume:(NSInteger)volume
 completionBlock:(void(^)(NSString *newFile))completionBlock;

- (void)extractAudio:(NSString *)theFile
     completionBlock:(void(^)(NSString *newFile))completionBlock;
- (NSString *)decodeSignature:(NSString *)theSig;

- (void)muxFiles:(NSArray *)theFiles completionBlock:(void(^)(NSString *newFile))completionBlock;

+ (NSDictionary *)formatFromTag:(NSInteger)tag;

@end
