/* APDeviceController */

#import <Foundation/Foundation.h>
#import "Reachability/Reachability.h"

@interface APDeviceController : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
	BOOL searching;
    NSMutableData * currentDownload;
	NSArray *receivedFiles;
}

@property (nonatomic, strong) NSNetServiceBrowser *acbrowser;
@property (nonatomic, strong) NSNetServiceBrowser *apbrowser;
@property (nonatomic, strong) NSDictionary *deviceDictionary;
@property (nonatomic, strong) NSArray *airplayServers;
@property (nonatomic, strong) NSMutableArray *services;
@property (nonatomic, strong) Reachability *reachabilityManager;

- (NSDictionary *)stringDictionaryFromService:(NSNetService *)theService;
- (NSDictionary *)currentServiceDictionary;
- (NSString *)deviceIPAtIndex:(NSInteger)deviceIndex;
- (int)deviceTypeAtIndex:(NSInteger)deviceIndex;
- (NSString *)deviceIPFromName:(NSString *)deviceName andType:(int)deviceType;
@end
