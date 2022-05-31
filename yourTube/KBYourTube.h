//
//  KBYourTube.h
//  yourTube
//
//  Created by Kevin Bradley on 12/21/15.
//  Copyright © 2015 nito. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "KBYourTube+Categories.h"
#import "APDeviceController.h"
#if TARGET_OS_IOS
#import "KBYTMessagingCenter.h"
#endif
#import "YTKBPlayerViewController.h"
#import "KBYTQueuePlayer.h"

@class KBYTSearchResult;

// Logging

/*
 //PLFgquLnL59ampo3SyfL95RBPrT6Q3a84N
 //music channel = UC-9-kyTW8ZkZNDHQJ6FgpwQ
 //popular on yt = UCF0pVplsI8R5kcAqgtoRqoA
 //sports = UCEgdi0XIXXZ-qJOFPf4JSKw
 //gaming = UCOpNcN46UbXVtpKMrmU4Abg
 //360 = UCzuqhhs6NWbgTzMuM09WKDQ
 
 dont have videos
 
 //news = UCYfdidRxbB8Qhf0Nx7ioOYw
 //live = UC4R8DWoMoI7CAwX8_LjQHig
 
 
 */

static NSString *const KBYTMusicChannelID   =  @"UC-9-kyTW8ZkZNDHQJ6FgpwQ";
static NSString *const KBYTPopularChannelID =  @"UCF0pVplsI8R5kcAqgtoRqoA";
static NSString *const KBYTSportsChannelID  =  @"UCEgdi0XIXXZ-qJOFPf4JSKw";
static NSString *const KBYTGamingChannelID  =  @"UCOpNcN46UbXVtpKMrmU4Abg";
static NSString *const KBYT360ChannelID     =  @"UCzuqhhs6NWbgTzMuM09WKDQ";
static NSString *const KBYTFashionAndBeautyID =  @"UCrpQ4p1Ql_hG8rKXIKM1MOQ";
static NSString *const KBYTSpotlightChannelID = @"UCBR8-60-B28hp2BmDPdntcQ";

@protocol YTPlayerItemProtocol <NSObject>
- (NSString *)duration;
- (NSString *)title;
- (NSString *)videoId;
@end

@interface YTBrowserHelper : NSObject

+ (id)sharedInstance;
- (void)importFileWithJO:(NSString *)theFile duration:(NSInteger)duration;
- (void)fixAudio:(NSString *)theFile volume:(NSInteger)volume completionBlock:(void(^)(NSString *newFile))completionBlock;
- (void)fileCopyTest:(NSString *)theFile;

@end

typedef NS_ENUM(NSUInteger, YTSearchResultType) {
    
    kYTSearchResultTypeUnknown,
   kYTSearchResultTypeVideo,
   kYTSearchResultTypePlaylist,
   kYTSearchResultTypeChannel,
   kYTSearchResultTypeChannelList,
};

typedef NS_ENUM(NSUInteger, KBYTSearchType) {
    KBYTSearchTypeAll,
    KBYTSearchTypeVideos,
    KBYTSearchTypeChannels,
    KBYTSearchTypePlaylists,
};


@interface KBYTLocalMedia : NSObject <YTPlayerItemProtocol>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSDictionary *images;
@property (nonatomic, strong) NSString *extension;
@property (nonatomic, strong) NSString *format;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *outputFilename;
@property (readwrite, assign) BOOL inProgress;

- (id)initWithDictionary:(NSDictionary *)inputDict;
- (NSDictionary *)dictionaryValue;

@end

@interface YTPlayerItem: AVPlayerItem

@property (nonatomic, weak) NSObject <YTPlayerItemProtocol> *associatedMedia;

@end

@interface KBYTSearchResults: NSObject

@property (nonatomic, strong) NSString *continuationToken;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *videos;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *playlists;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *channels;
@property (readwrite, assign) NSInteger estimatedResults;
- (void)processJSON:(NSDictionary *)jsonData;

@end

@interface KBYTMedia : NSObject <YTPlayerItemProtocol>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *keywords;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *channelId; //what channel does video belong to
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSDictionary *images;
@property (nonatomic, strong) NSArray *streams;
@property (nonatomic, strong) NSString *details; //description
@property (readwrite, assign) NSInteger expireTime;

- (BOOL)isExpired;
- (NSDictionary *)dictionaryRepresentation;
- (YTPlayerItem *)playerItemRepresentation;
@end

@interface KBYTSearchResult: NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *channelPath; //what channel does video belong to
@property (nonatomic, strong) NSString *channelId; //what channel does video belong to
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *age;
@property (nonatomic, strong) NSString *views;
@property (nonatomic, strong) NSString *details;
@property (nonatomic, strong) KBYTMedia *media;
@property (nonatomic, strong) NSString *continuationToken;
@property (readwrite, assign) YTSearchResultType resultType;
@property (nonatomic, strong) NSArray *items; //only relevant for channel list

- (id)initWithDictionary:(NSDictionary *)resultDict;
- (NSString *)readableSearchType;
@end

@interface KBYTSection: NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *content;
- (void)addResult:(KBYTSearchResult *)result;
@end

@interface KBYTChannel: NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) NSString *owner;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *channelID;
@property (nonatomic, strong) NSString *continuationToken;
@property (nonatomic, strong) NSString *banner;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *videos;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *playlists;
@property (nonatomic, strong) NSArray <KBYTSection *> *sections;
- (NSArray <KBYTSearchResult *>*)allSectionItems;
- (NSArray <KBYTSearchResult *>*)allSortedItems; //legacy
- (void)mergeChannelVideos:(KBYTChannel *)channel;
@end

@interface KBYTPlaylist: NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *owner;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *image;
@property (nonatomic, strong) NSString *playlistID;
@property (nonatomic, strong) NSString *continuationToken;
@property (nonatomic, strong) NSArray <KBYTSearchResult *> *videos;

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
@property (readwrite, assign) NSInteger expireTime;

- (id)initWithDictionary:(NSDictionary *)streamDict;
- (NSDictionary *)dictionaryValue;
- (BOOL)isExpired;

@end

#import "Ono/ONOXMLDocument.h"

@interface KBYourTube : NSObject
{
    NSInteger bestTag;
}



@property (nonatomic, strong) APDeviceController *deviceController;
@property (nonatomic, strong) NSString *yttimestamp;
@property (nonatomic, strong) NSString *ytkey;
@property (nonatomic, strong) NSString *airplayIP;
@property (nonatomic, strong) NSString *lastSearch;
@property (nonatomic, strong) NSDictionary *userDetails; 

- (KBYTSearchResult *)searchResultFromVideoRenderer:(NSDictionary *)current;
+ (YTSearchResultType)resultTypeForString:(NSString *)string;
+ (id)sharedInstance;
- (BOOL)isSignedIn;
- (void)documentFromURL:(NSString *)theURL completion:(void(^)(ONOXMLDocument *document))block;
- (ONOXMLDocument *)documentFromURL:(NSString *)theURL;
- (NSDictionary *)channelIDAndWatchLaterCount;
- (NSString *)videoDescription:(NSString *)videoID;
- (NSDictionary *)videoDetailsFromID:(NSString *)videoID;

- (void)getUserDetailsDictionaryWithCompletionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                                       failureBlock:(void(^)(NSString *error))failureBlock;

- (void)loadMoreVideosFromHREF:(NSString *)loadMoreLink
               completionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                  failureBlock:(void(^)(NSString *error))failureBlock;

- (void)loadMorePlaylistVideosFromHREF:(NSString *)loadMoreLink
                       completionBlock:(void(^)(NSDictionary *outputResults))completionBlock
                          failureBlock:(void(^)(NSString *error))failureBlock;

/**
 
 searchQuery is just a basic unescaped search string, this will return a dictionary with 
 results, pageCount, resultCount. Beware this is super fragile, if youtube website changes
 this will almost definitely break. that being said its MUCH quicker then getSearchResults
 
 */

- (void)getOrganizedChannelData:(NSString *)channelID
                completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                   failureBlock:(void(^)(NSString* error))failureBlock;

- (void)apiSearch:(NSString *)search
             type:(KBYTSearchType)type
     continuation:(NSString *)continuation
  completionBlock:(void(^)(KBYTSearchResults *result))completionBlock
     failureBlock:(void(^)(NSString* error))failureBlock;


- (void)getPlaylistVideos:(NSString *)listID
             continuation:(NSString *)continuationToken
          completionBlock:(void(^)(KBYTPlaylist *playlist))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock;

- (void)getPlaylistVideos:(NSString *)listID
          completionBlock:(void(^)(KBYTPlaylist *playlist))completionBlock
             failureBlock:(void(^)(NSString *error))failureBlock;

- (void)getUserVideos:(NSString *)channelID
      completionBlock:(void(^)(NSDictionary *searchDetails))completionBlock
         failureBlock:(void(^)(NSString *error))failureBlock;

- (void)getChannelVideos:(NSString *)channelID
            continuation:(NSString *)continuationToken
         completionBlock:(void (^)(KBYTChannel *))completionBlock
            failureBlock:(void (^)(NSString *))failureBlock;

- (void)getChannelVideos:(NSString *)channelID
         completionBlock:(void(^)(KBYTChannel *channel))completionBlock
            failureBlock:(void(^)(NSString *error))failureBlock;

- (void)getChannelVideosAlt:(NSString *)channelID
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
               failureBlock:(void(^)(NSString *error))failureBlock;

- (void)getChannelVideosAlt:(NSString *)channelID
               continuation:(NSString *)continuationToken
          completionBlock:(void(^)(KBYTChannel *channel))completionBlock
               failureBlock:(void(^)(NSString *error))failureBlock;

- (void)getAllFeaturedVideosWithFilter:(NSString *)filter
                       completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                          failureBlock:(void(^)(NSString* error))failureBlock;

- (void)getFeaturedVideosWithCompletionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
                                failureBlock:(void(^)(NSString* error))failureBlock;

- (void)getVideoDetailsForSearchResults:(NSArray*)searchResults
                        completionBlock:(void(^)(NSArray* videoArray))completionBlock
                           failureBlock:(void(^)(NSString* error))failureBlock;

- (void)getSearchResults:(NSString *)searchQuery
              pageNumber:(NSInteger)page
         completionBlock:(void(^)(NSDictionary* searchDetails))completionBlock
            failureBlock:(void(^)(NSString* error))failureBlock;

- (void)getVideoDetailsForIDs:(NSArray*)videoIDs
              completionBlock:(void(^)(NSArray* videoArray))completionBlock
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
