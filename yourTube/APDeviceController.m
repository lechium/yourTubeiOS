

#import "APDeviceController.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import "KBYourTube.h"

@implementation APDeviceController

@synthesize deviceDictionary, airplayServers, acbrowser, apbrowser, services;

- (id)init {
    
    self = [super init];
    acbrowser = [[NSNetServiceBrowser alloc] init];
    apbrowser = [[NSNetServiceBrowser alloc] init];
    services = [NSMutableArray array];
    [acbrowser setDelegate:self];
    [apbrowser setDelegate:self];
    // Passing in "" for the domain causes us to browse in the default browse domain
   
    [acbrowser searchForServicesOfType:@"_airplay._tcp." inDomain:@""];
    [apbrowser searchForServicesOfType:@"_aircontrol._tcp." inDomain:@""];
    return self;
}


- (NSString *)convertedName:(NSString *)inputName
{
    NSMutableString	*fixedNetLabel = [NSMutableString stringWithString:[inputName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".#,<>/?\'\\\[]{}+=-~`\";:"]]];
    [fixedNetLabel replaceOccurrencesOfString:@" " withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [fixedNetLabel length])];
    
    return [NSString stringWithString:fixedNetLabel];
}

- (NSString *)fixedName:(NSString *)inputName
{
    NSInteger nameLength = [inputName length];
    NSString *newName = [inputName substringToIndex:(nameLength-1)];
    return newName;
}

- (BOOL)serviceHasYoutube:(NSNetService *)netService
{
    LOG_SELF;
    NSString *ip;
    int port;
    struct sockaddr_in *addr;
    addr = (struct sockaddr_in *) [[[netService addresses] objectAtIndex:0]
                                   bytes];
    ip = [NSString stringWithUTF8String:(char *) inet_ntoa(addr->sin_addr)];
    port = ntohs(((struct sockaddr_in *)addr)->sin_port);
    NSString *deviceIP = [NSString stringWithFormat:@"%@:%i", ip, port];
    NSURL *deviceURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/pids", deviceIP]];
    
    // Create URL request and set url, method, content-length, content-type, and body
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:deviceURL];
    [request setHTTPMethod:@"GET"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    NSArray *pidArray = [[datString dictionaryValue] valueForKey:@"plugins"];
    NSDictionary *ytObject = [[pidArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.id == %@", @"com.apple.frontrow.appliance.ft"]]lastObject];
    if (ytObject != nil)
    {
        return TRUE;
    }
    return FALSE;
    
}

- (NSDictionary *)stringDictionaryFromService:(NSNetService *)theService
{
    NSData *txtRecordDict = [theService TXTRecordData];
    
    NSDictionary *theDict = [NSNetService dictionaryFromTXTRecordData:txtRecordDict];
    NSMutableDictionary *finalDict = [[NSMutableDictionary alloc] init];
    NSArray *keys = [theDict allKeys];
    for (NSString *theKey in keys)
    {
        NSString *currentString = [[NSString alloc] initWithData:[theDict valueForKey:theKey] encoding:NSUTF8StringEncoding];
        [finalDict setObject:currentString forKey:theKey];
    }
    
    return finalDict;
}

- (int)deviceTypeAtIndex:(NSInteger)deviceIndex // 0 = airplay 1 = aircontrol
{
    NSNetService * clickedService = [services objectAtIndex:deviceIndex];
    if ([[clickedService type] isEqualToString:@"_airplay._tcp."])
    {
        return 0;
    }
    
    return 1;
    
}

- (NSString *)deviceIPFromName:(NSString *)deviceName andType:(int)deviceType;
{
    for (NSNetService *service in services)
    {
        NSString *dt = nil;
        if (deviceType == 0) //airplay
            dt = @"_airplay._tcp.";
        else
            dt = @"_aircontrol._tcp.";
        
        if ([[service name] isEqualToString:deviceName] && [[service type] isEqualToString:dt])
        {
            NSString *ip;
            int port;
            struct sockaddr_in *addr;
            
            addr = (struct sockaddr_in *) [[[service addresses] objectAtIndex:0]
                                           bytes];
            ip = [NSString stringWithUTF8String:(char *) inet_ntoa(addr->sin_addr)];
            port = ntohs(((struct sockaddr_in *)addr)->sin_port);
            //NSLog(@"ipaddress: %@", ip);
            //NSLog(@"port: %i", port);
            
            NSString *fullIP = [NSString stringWithFormat:@"%@:%i", ip, port];
            NSLog(@"fullIP: %@", fullIP);
            return fullIP;
        }
    }
    return nil;
}


- (NSString *)deviceIPAtIndex:(NSInteger)deviceIndex
{
    NSNetService * clickedService = [services objectAtIndex:deviceIndex];
    NSDictionary *finalDict = [self stringDictionaryFromService:clickedService];
    
    if ([[finalDict allKeys] count] > 0)
    {
        [self setDeviceDictionary:[finalDict copy]];
        NSLog(@"_deviceDictionary: %@", [self deviceDictionary]);
    } else {
        
        
        return nil;
    }
    
    
    
    NSString *ip;
    int port;
    struct sockaddr_in *addr;
    
    addr = (struct sockaddr_in *) [[[clickedService addresses] objectAtIndex:0]
                                   bytes];
    ip = [NSString stringWithUTF8String:(char *) inet_ntoa(addr->sin_addr)];
    port = ntohs(((struct sockaddr_in *)addr)->sin_port);
    //NSLog(@"ipaddress: %@", ip);
    //NSLog(@"port: %i", port);
    
    NSString *fullIP = [NSString stringWithFormat:@"%@:%i", ip, port];
    NSLog(@"fullIP: %@", fullIP);
    return fullIP;
    //[DEFAULTS setObject:fullIP forKey:ATV_HOST];
}



- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser

{
    //NSLog(@"%@ %s", self, _cmd);
    searching = NO;
    [self updateUI];
    
}

- (void)updateUI

{
    //NSLog(@"%@ %s", self, _cmd);
    if(searching)
        
    {
        
        // Update the user interface to indicate searching
        
        // Also update any UI that lists available services
        
    }
    
    else
        
    {
        
        NSLog(@"services: %@", services);
        // Update the user interface to indicate not searching
        
    }
    
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
    LOG_SELF;
    //NSLog(@"%@ %s", self, _cmd);
    searching = YES;
    
    [self updateUI];
    
}

// Error handling code

- (void)handleError:(NSNumber *)error

{
    
    NSLog(@"An error occurred. Error code = %d", [error intValue]);
    
    // Handle error here
    
}


- (BOOL)searching {
    return searching;
}


// This object is the delegate of its NSNetServiceBrowser object. We're only interested in services-related methods, so that's what we'll call.
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {

    [services addObject:aNetService];
    [aNetService setDelegate:self];
    [aNetService resolveWithTimeout:10.0];
    
    if(!moreComing) {
        
        searching = false;
        airplayServers = services;
       
        // if ([[aNetService type] isEqualToString:@"_aircontrol._tcp."])
//        if([[aNetService type] isEqualToString:@"_airplay._tcp."])
//        {
//            
//            NSLog(@"firing off aircontrol search now");
//            browser = [[NSNetServiceBrowser alloc] init];
//            [browser setDelegate:self];
//            //[browser searchForServicesOfType:@"_airplay._tcp." inDomain:@""];
//            [browser searchForServicesOfType:@"_aircontrol._tcp." inDomain:@""];
//            
//        }
    }
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    LOG_SELF;
    
}




- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    [services removeObject:aNetService];
    
    if(!moreComing) {
         airplayServers = services;
    }
}


//resolution stuff


- (BOOL)addressesComplete:(NSArray *)addresses

           forServiceType:(NSString *)serviceType

{
    LOG_SELF;
    //NSLog(@"%@ %s", self, _cmd);
    // Perform appropriate logic to ensure that [netService addresses]
    
    // contains the appropriate information to connect to the service
    
    return YES;
    
}

// Sent when addresses are resolved

- (void)netServiceDidResolveAddress:(NSNetService *)netService

{
    LOG_SELF;
    if ([[netService type] isEqualToString:@"_aircontrol._tcp."])
    {
        if (![self serviceHasYoutube:netService])
        {
            [services removeObject:netService];
        }
    }
    //    if ([self addressesComplete:[netService addresses]
    //
    //				 forServiceType:[netService type]]) {
    //
    //
    //    }
    
}



// Sent if resolution fails

- (void)netService:(NSNetService *)netService

     didNotResolve:(NSDictionary *)errorDict

{
    LOG_SELF;
    [self handleError:[errorDict objectForKey:NSNetServicesErrorCode]];
    
    [services removeObject:netService];
    
}



@end
