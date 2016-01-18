
typedef void (^CDUnknownBlockType)(void); // return type and parameters are unknown

%hook JOiTunesImporter

+ (void)startPreImportProcessing:(id)arg1 completeBlock:(id)arg2 {
	%log;
	%orig;
}

%end 

%hook JOiTunesImportHelper
+ (_Bool)importAudioFileAtPath:(id)arg1 mediaKind:(id)arg2 withMetadata:(id)arg3 serverURL:(id)arg4
{ 
	%log; 
	_Bool  r = %orig; 
	NSLog(@" = %d", r); 
//	NSData *theData = [arg3 valueForKey:@"imageData"];
	
	//UIImage *theImage [UIImage imageWithData:imageData];
//	NSString *outputFile = @"/var/mobile/Library/Preferences/imageTest.png";
//	[theData writeToFile:outputFile atomically:YES];
 	return r;
 }
	
//+ (void)_waitForDownloadCompletion:(id)arg1 { %log; %orig; }
//+ (id)downloadManager { %log;  id r = %orig; NSLog(@" = %d", r); return r; }	// IMP=0x000000000000a6c4
//+ (id)downloadQueue  { %log;  id r = %orig; NSLog(@" = %d", r); return r; }	// IMP=0x000000000000a614

%end

%hook SpringBoard
#import "AppSupport/CPDistributedMessagingCenter.h"
#import "YTBrowserHelper.h"
- (id)init
{
	%log;
	
	Class sci = NSClassFromString(@"YTBrowserHelper");
	Class SB = NSClassFromString(@"SpringBoard");
	id ytbh = [YTBrowserHelper sharedInstance]; //allocate it
	id r = %orig;
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"org.nito.importscience"];
    [center runServerOnCurrentThread];
    [center registerForMessageName:@"org.nito.importscience.import" target:self selector:@selector(handleMessageName:userInfo:)];
    [center registerForMessageName:@"org.nito.importscience.startAirplay" target:self selector:@selector(handleMessageName:userInfo:)];
    
    [center registerForMessageName:@"org.nito.importscience.stopAirplay" target:ytbh selector:@selector(stopPlayback)];
    [center registerForMessageName:@"org.nito.importscience.pauseAirplay" target:ytbh selector:@selector(togglePaused)];
    [center registerForMessageName:@"org.nito.importscience.airplayState" target:ytbh selector:@selector(airplayState)];
	Method ourMessageHandler = class_getInstanceMethod(sci, @selector(handleMessageName:userInfo:));
    
	class_addMethod(SB, @selector(handleMessageName:userInfo:), method_getImplementation(ourMessageHandler), method_getTypeEncoding(ourMessageHandler));
	
	return r;
}

%end

#include "InspCWrapper.m"
	@class YTBrowserHelper;
static __attribute__((constructor)) void myHooksInit() {
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;

	
  	//setMaximumRelativeLoggingDepth(5);
	//watchClass([SSDownloadMetadata class]);
	//watchClass(NSClassFromString(@"SSDownload"));
	//watchClass(NSClassFromString(@"JOiTunesImportHelper"));
//	[pool drain];	
}
