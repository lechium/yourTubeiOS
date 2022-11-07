//
//  AppDelegate.h
//  tuyuTV
//
//  Created by Kevin Bradley on 3/6/16.
//
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"

typedef NS_ENUM(NSInteger, KBSocketOrigin) {
    KBSocketOriginServer,
    KBSocketOriginClient,
} NS_SWIFT_NAME(KBSocket.Type);

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIBarPositioningDelegate, UISearchBarDelegate, GCDAsyncSocketDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    
    //server properties
    
    NSNetService *netService;
    GCDAsyncSocket *asyncSocket;
    NSMutableArray <GCDAsyncSocket*>*connectedSockets;
    
    //client properties
    
    NSNetServiceBrowser *netServiceBrowser;
    NSNetService *serverService;
    NSMutableArray *serverAddresses;
    GCDAsyncSocket *asyncClientSocket;
    BOOL connected;
    
}
@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) UITabBarController *tabBar;

- (void)updateForSignedIn;
- (void)updateForSignedOut;

@end

