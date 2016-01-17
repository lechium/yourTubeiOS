/* APDeviceController */

#import <Foundation/Foundation.h>

@interface APDeviceController : NSObject <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
	BOOL searching;
    NSMutableData * currentDownload;
	NSArray *receivedFiles;
}

@property (nonatomic, strong) NSNetServiceBrowser *browser;
@property (nonatomic, strong) NSDictionary *deviceDictionary;
@property (nonatomic, strong) NSArray *airplayServers;
@property (nonatomic, strong) NSMutableArray *services;


- (NSDictionary *)stringDictionaryFromService:(NSNetService *)theService;
- (NSDictionary *)currentServiceDictionary;
- (NSString *)deviceIPAtIndex:(NSInteger)deviceIndex;
- (int)deviceTypeAtIndex:(NSInteger)deviceIndex;
- (NSString *)deviceIPFromName:(NSString *)deviceName andType:(int)deviceType;
@end
