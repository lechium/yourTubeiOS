//
//  ViewController.h
//  Browser
//
//  Created by Steven Troughton-Smith on 20/09/2015.
//  Improved by Jip van Akker on 14/10/2015
//  Copyright © 2015 High Caffeine Content. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface WebViewController : GCEventViewController  <UIWebViewDelegate>
{
    BOOL emailEntered; //hacky bool to keep track of if email was already entered.
}

typedef enum {
    WebViewControllerAuthMode = 0,
    WebViewControllerPermissionMode = 1,
} WebViewMode;

@property (nonatomic, strong) NSString *initialURL;
@property (readwrite, assign) WebViewMode viewMode;


- (id)initWithURL:(NSString *)theURLString;

@end

