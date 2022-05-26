//
//  ViewController.h
//  yourMusic
//
//  Created by Kevin Bradley on 1/8/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>
#import "KBYourTube.h"
#import "KBYTPreferences.h"


typedef enum {
    TYWebViewControllerDefaultMode = 0,
    TYWebViewControllerAuthMode = 1,
    TYWebViewControllerPermissionMode = 2,
} TYWebViewMode;


@interface KBYTWebViewController : UIViewController <WKNavigationDelegate, UIActionSheetDelegate, WKScriptMessageHandler, UIWebViewDelegate >
{
    WebView *wv;
}
@property (readwrite, assign) TYWebViewMode viewMode;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (nonatomic, strong) KBYTMedia *currentMedia;
@property (nonatomic, strong) NSString *previousVideoID;
@property (readwrite, assign) BOOL gettingDetails;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) NSTimer *airplayTimer;
@property (nonatomic, strong) NSString *airplayIP;
@property (nonatomic, strong) UISlider *airplaySlider;
@property (nonatomic, strong) UIView *sliderView;
@property (readwrite, assign) CGFloat airplayProgressPercent;
@property (readwrite, assign) CGFloat airplayDuration;

- (id)initWithURL:(NSString*)theURL;
- (id)initWithURL:(NSString*)theURL mode:(TYWebViewMode)mode;
@end

