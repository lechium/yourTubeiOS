//
//  ViewController.m
//  yourMusic
//
//  Created by Kevin Bradley on 1/8/16.
//  Copyright © 2016 nito. All rights reserved.
//

#define MessageHandler @"didGetPosts"
#import "OurViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "APDeviceController.h"

@interface OurViewController ()

@end

@implementation OurViewController

@synthesize downloading, airplayIP;

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor redColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkAirplay];
   
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:[self webView] action:@selector(reload)];
    //self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStylePlain target:[self webView] action:@selector(goBack)];
}

- (void)pauseVideos
{
    NSString *script = @"var videos = document.querySelectorAll(\"video\"); for (var i = videos.length - 1; i >= 0; i--) { videos[i].pause(); };";
    [self.webView evaluateJavaScript:script completionHandler:^(id result, NSError *error) {
        NSLog(@"Error : %@",error.localizedDescription);
        NSLog(@"Java script result = %@",result);
    }];
}

//currently not used for anything, was added when messing around with trying to prevent autoplaying videos.
- (void)videoPlayingDidChange:(NSNotification *)notification
{
    BOOL isPlaying = [notification.userInfo[@"IsPlaying"] boolValue];
    if (isPlaying == true) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"grey_arrow_right.png"] style:UIBarButtonItemStylePlain target:self action:@selector(showPlayerview)];
                                                  
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:[self webView] action:@selector(reload)];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayingDidChange:)
                                                 name:@"SomeClientPlayingDidChange"
                                               object:nil];
    
    // Video playing state handler
    
    CGRect mainFrame = [[self view] frame];
    CGFloat height = 63; //self.navigationController.navigationBar.frame.size.height;
    mainFrame.origin.y = height;
    mainFrame.size.height-= height;
    self.downloading = false;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]
                                      init];
    
    self.progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0,height,mainFrame.size.width, 20)];
    [self.progressView.layer setZPosition:2];
    [self.webView.layer setZPosition:1];
    [self.view addSubview:self.progressView];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    //self.progressView.hidden = false;
    
    if ([config respondsToSelector:@selector(requiresUserActionForMediaPlayback)])
    {
        //    config.requiresUserActionForMediaPlayback = true;
    }
    config.mediaPlaybackRequiresUserAction = true;
    config.allowsInlineMediaPlayback = false;
    
    self.webView = [[WKWebView alloc] initWithFrame:mainFrame configuration:config];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [[self view] addSubview:self.webView];
    

 //   [[self view] addSubview:self.progressView];
   // [self.view bringSubviewToFront:self.progressView];
    
    //a script to attempt to pause any videos from autoplaying, used in conjunction with a bunch of other hacks
    //to stop autoplaying from occuring.
    
    NSString *scriptContent = @"var videos = document.querySelectorAll(\"video\"); for (var i = videos.length - 1; i >= 0; i--) { videos[i].pause(); };";
    
    if (scriptContent)
    {
        WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptContent injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        [config.userContentController addUserScript:script];
        [config.userContentController addScriptMessageHandler:self name:MessageHandler];
    }
    
    NSString *lastVisited = [[KBYTPreferences preferences] valueForKey:@"lastVisitedURL"];
    
    NSLog(@"last visited url: %@", lastVisited);
    
    if (lastVisited == nil || lastVisited.length == 0)
    {
       lastVisited = @"https://www.youtube.com";
    }
    
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:lastVisited] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    //these observers are a hacky way to know a good time to check URL to see if we land on a page that has a video URL
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    [[self webView] setNavigationDelegate:self];
    [[self webView] loadRequest:request];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  //  LOG_SELF;
    NSLog(@"size: %@", NSStringFromCGSize(size));
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (size.height > size.width) //portrait
    {
        CGRect mainFrame = [[self view] frame];
        CGFloat height = 63; //self.navigationController.navigationBar.frame.size.height;
        mainFrame.origin.y = height;
        mainFrame.size.height-= height;
        self.webView.frame = mainFrame;
        CGRect progressFrame = self.progressView.frame;
        progressFrame.origin.y = height;
        self.progressView.frame = progressFrame;
    } else { //landscape
        
        CGRect mainFrame = [[self view] frame];
        CGFloat height = 32; //self.navigationController.navigationBar.frame.size.height;
        mainFrame.origin.y = height;
        mainFrame.size.height-= height;
        self.webView.frame = mainFrame;
        CGRect progressFrame = self.progressView.frame;
        progressFrame.origin.y = height;
        self.progressView.frame = progressFrame;
    }

}


//currently unused
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    LOG_SELF;
    if ([message.name isEqualToString:MessageHandler]) {
        
        id postList = message.body;
        
    }
}

- (void)updateBackButtonState
{
    if ([[self webView] canGoBack])
    {
     self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"grey_arrow_left.png"] style:UIBarButtonItemStylePlain target:[self webView] action:@selector(goBack)];
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}
/*
 
 This observer is where we determine whether or not we are on an actual video / playlist page
 
 If we are, jump through a whole bunch of hoops to stop the page from loading / autoplaying videos / ads. Then fetch
 video details for downloading / playback and show an action sheet.
 
 */

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        [self updateBackButtonState];
    }
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
     //      NSLog(@"estimated progress: %f", self.webView.estimatedProgress);
        self.progressView.hidden = self.webView.estimatedProgress == 1;
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
        [self updateBackButtonState];
        //among the initial hacks, since title gets changed a lot during a load cycle we dont want to fetch
        //the info twice, if we did then the action sheet would appear twice and we are wasting network calls.
        if (self.gettingDetails == true)
        {
            NSLog(@"already getting details, dont try again...");
            return;
        }
        
        //when we go back a page the video url may show up twice, and the name of page tends to be a generic "youtube"
        //return in this case.
        if ([self.webView.title isEqualToString:@"YouTube"]) {
            return;
        }
        
        //check the parameters of the URL to see if it has an associated video link in "v"
        
        NSDictionary *paramDict = [self.webView.URL parameterDictionary];
        if ( [[paramDict allKeys] containsObject:@"v"])
        {
            NSString *videoID = paramDict[@"v"];
            NSLog(@"videoID: %@", videoID);
            //another hack to prevent us from fetching details for the same video twice in a row.
            if (self.currentMedia != nil)
            {
                if ([self.previousVideoID isEqualToString:videoID])
                {
                    return;
                }
            }
            
            /**
             
             The biggest hack yet, if we just stopLoading and goBack google still finds a way to force 
             ads down our throat / autoplay after the page has been left. So we get the URL from the last
             back item, store that, load a completely blank page after stopping and going back, then
             reload this saved URL from the previous link to go back to a page where we are safe from autoplaying
             ads and videos.
             
             */
            
            NSURL *backURL = [[[[self webView] backForwardList] backItem] URL];
            
            [[KBYTPreferences preferences] setObject:[backURL absoluteString] forKey:@"lastVisitedURL"];
            //we have the URL we need stop the loading AND go back
            [[self webView] stopLoading];
            [[self webView] goBack];
            
            //load a blank page, helps prevent ads / videos from autoplaying.
            [[self webView] loadHTMLString:@"<html/>" baseURL:nil];
            
            //now time to reload the previous page requests so we can successfully go "back" without
            //autoplaying garbage.
            
            NSURLRequest * request = [[NSURLRequest alloc]initWithURL:backURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [[self webView] loadRequest:request];
            
            //now we can finally fetch the video details so we can show the action sheet for the user to make
            //a decision on their next action.
            [self getVideoIDDetails:videoID];
            self.gettingDetails = true;
        } else {
            
            [[KBYTPreferences preferences] setObject:[self.webView.URL absoluteString] forKey:@"lastVisitedURL"];
        }
        
        
    }
}


- (void)checkAirplay
{
    NSInteger status = [[KBYourTube sharedInstance] airplayStatus];
    
    if (status == 0) {
        [self.navigationController setToolbarHidden:YES animated:YES];
        [self.airplayTimer invalidate];
    } else {
        [self.navigationController setToolbarHidden:NO animated:YES];
        [self populateToolbar:status];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        @autoreleasepool {
            
            NSDictionary *playbackInfo = [self getAirplayDetails];
            CGFloat duration = [[playbackInfo valueForKey:@"duration"] floatValue];
            CGFloat position = [[playbackInfo valueForKey:@"position"] floatValue];
            CGFloat percent = position / duration;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.airplayProgressPercent = percent;
                self.airplaySlider.value = percent;
                self.airplayDuration = duration;
            });
        }
    });
    
    
}

- (void)fireAirplayTimer
{
    self.airplayTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkAirplay) userInfo:nil repeats:TRUE];
}

#define FLEXY                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]

- (void)sliderMoved:(UISlider *)slider
{
    CGFloat translatedSpot = self.airplayDuration * slider.value;
    [self scrubToPosition:translatedSpot];
}

- (void)populateToolbar:(NSInteger)status
{
    self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
    self.airplaySlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, 220, 40)];
    self.airplaySlider.value = self.airplayProgressPercent;
    [self.airplaySlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    [self.sliderView addSubview:self.airplaySlider];

    UIBarButtonItem *sliderItem = [[UIBarButtonItem alloc] initWithCustomView:self.sliderView];
    
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:[KBYourTube sharedInstance] action:@selector(stopAirplay)];
    UIBarButtonItem *playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:[KBYourTube sharedInstance] action:@selector(pauseAirplay)];
    if (status == 1) //playing
        playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:[KBYourTube sharedInstance] action:@selector(pauseAirplay)];
    UIBarButtonItem *fixSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixSpace.width = 10.0f;
    self.toolbarItems = @[FLEXY,stopButton, fixSpace,playButton, fixSpace, sliderItem, FLEXY];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSDictionary *)returnFromURLRequest:(NSString *)requestString requestType:(NSString *)type
{
    NSURL *deviceURL = [NSURL URLWithString:requestString];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
    [request setURL:deviceURL];
    [request setHTTPMethod:type];
    [request addValue:@"MediaControl/1.0" forHTTPHeaderField:@"User-Agent"];
    NSURLResponse *theResponse = nil;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&theResponse error:nil];
    NSString *datString = [[NSString alloc] initWithData:returnData  encoding:NSUTF8StringEncoding];
    NSLog(@"return details: %@", datString);
    return [datString dictionaryValue];
}

- (NSDictionary *)scrubToPosition:(CGFloat)position
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/scrub?position=%f", [self airplayIP], position];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"POST"];
    NSLog(@"returnDict: %@", returnDict);
    return returnDict;
    
 //   /scrub?position=20.097000
}

- (NSDictionary *)getAirplayDetails
{
    NSString *requestString = [NSString stringWithFormat:@"http://%@/playback-info", [self airplayIP]];
    NSDictionary *returnDict = [self returnFromURLRequest:requestString requestType:@"GET"];
    NSLog(@"returnDict: %@", returnDict);
    return returnDict;
}

//the action sheet result handler
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    self.previousVideoID = nil;
    KBYTStream *chosenStream = nil;
    NSInteger airplayIndex = 0;
    NSString *deviceIP = nil;
    NSDictionary *deviceDict = nil;
    APDeviceController *deviceController = nil;
    int deviceType;
    switch (buttonIndex) {
        case 0: //Play video
            
            chosenStream = [[self.currentMedia streams] objectAtIndex:0];
            [self playStream:chosenStream];
            break;
            
        case 1: //download video
            
            chosenStream = [[self.currentMedia streams] objectAtIndex:0];
            [self downloadStream:chosenStream];
            
        case 2: //download audio
            
            chosenStream = [[self.currentMedia streams] lastObject];
            [self downloadStream:chosenStream];
        
            
        default:
            
            if (buttonIndex == actionSheet.cancelButtonIndex)
            {
                return;
            }
            
            NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
            NSString *isolatedTitle = [[buttonTitle componentsSeparatedByString:@" "] lastObject];
            if ([buttonTitle containsString:@"AirPlay"])
            {
                isolatedTitle = [[buttonTitle componentsSeparatedByString:@"AirPlay to "] lastObject];
                deviceType = 0;
            } else {
                isolatedTitle = [[buttonTitle componentsSeparatedByString:@"Play in YouTube on "] lastObject];
                deviceType = 1;
            }
            chosenStream = [[self.currentMedia streams] objectAtIndex:0];
            //need to adjust the index to subtract the three objects above us to get the proper device index
            airplayIndex = buttonIndex - 3;
            deviceController = [[KBYourTube sharedInstance] deviceController];
            self.airplayIP = [deviceController deviceIPFromName:isolatedTitle andType:deviceType];
            
            if (deviceType == 0) //airplay
            {
                
                [[KBYourTube sharedInstance] airplayStream:chosenStream ToDeviceIP:self.airplayIP ];
                [self fireAirplayTimer];
            } else {
                
                //aircontrol
                 [[KBYourTube sharedInstance] playMedia:self.currentMedia ToDeviceIP:self.airplayIP];
            }
    }
}

//play the import completion sound (standard tri-tone success sound)
- (void)playCompleteSound
{
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"complete" ofType:@"aif"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: thePath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

//action sheet that is shown to allow the user to choose whether or not to download video / audio or play the video


- (void)showActionSheet
{
    
    NSArray *airplayDevices = [[[KBYourTube sharedInstance] deviceController] airplayServers];
    
    NSString *actionSheetTitle = [NSString stringWithFormat:@"Choose action for %@", self.currentMedia.title];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    
    [actionSheet setTitle:actionSheetTitle];
    [actionSheet setDelegate:self];
    [actionSheet addButtonWithTitle:@"Play video"];
    [actionSheet addButtonWithTitle:@"Download Video"];
    [actionSheet addButtonWithTitle:@"Download Audio"];
    for (NSNetService *service in airplayDevices)
    {
        NSString *playTitle = nil;
        if ([[service type] isEqualToString:@"_aircontrol._tcp."])
        {
            playTitle = [NSString stringWithFormat:@"Play in YouTube on %@", [service name]];
        } else {
            playTitle = [NSString stringWithFormat:@"AirPlay to %@", [service name]];
        }
        [actionSheet addButtonWithTitle:playTitle];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet setCancelButtonIndex:3+[airplayDevices count]];
    
    //UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:names, nil];
    
    [actionSheet showInView:self.view];
}

//actually get the video details for the selected video.

- (void)getVideoIDDetails:(NSString *)details
{
    [[KBYourTube sharedInstance] getVideoDetailsForID:details completionBlock:^(KBYTMedia *videoDetails) {
        
        if (self.currentMedia != nil)
        {
            if ([self.previousVideoID isEqualToString:videoDetails.videoId])
            {
                NSLog(@"already got this video, dont do anything");
                return;
            }
        }
        
        //  NSLog(@"got details successfully: %@", videoDetails);
        self.currentMedia = videoDetails;
        self.previousVideoID = videoDetails.videoId;
        self.gettingDetails = false;
        [self showActionSheet]; //show the action sheet
        
    } failureBlock:^(NSString *error) {
        
        NSLog(@"fail!: %@", error);
        
    }];
}


//another place to try and prevent ads and autoplaying from happening, not sure how successful this is.
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler

{
    NSURL *url = navigationAction.request.URL;
    NSDictionary *paramDict = [self.webView.URL parameterDictionary];
//    NSLog(@"paramDict: %@", paramDict);
    if ( [[paramDict allKeys] containsObject:@"v"])
    {
        [self pauseVideos];
        decisionHandler(WKNavigationActionPolicyCancel);

        
        return;
    }
    
    NSString *absolute = [url absoluteString];
    if([absolute containsString:@"googleads.g.doubleclick.net"])
    {
  
        [self pauseVideos];
        [webView stopLoading];
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler

{
    decisionHandler(WKNavigationResponsePolicyAllow);
}
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
}
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Timed out" message:@"Failed to load youtube.com, please try hitting refresh or try again later" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alertView show];
}
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    //   NSLog(@"url: %@", webView.URL);
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    // LOG_SELF;
}

- (BOOL)isPlaying
{
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            return true;
        }
    }
    return false;
    
}

- (void)showPlayerview
{
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
             [[self delegate] pushViewController:self.playerView];
            return;
        }
    }
    
  
}

//play the video stream
- (IBAction)playStream:(KBYTStream *)stream
{
    NSURL *playURL = [stream url];
   //NSLog(@"play url: %@", playURL);
    if ([self isPlaying] == true  ){
        return;
    }
    self.playerView = [AVPlayerViewController alloc];
    self.playerView.showsPlaybackControls = true;
    self.player = [AVPlayer playerWithURL:playURL];
    self.playerView.player = self.player;
    [[self delegate] pushViewController:self.playerView];
    [self.player play];
    
}

//download the selected stream, currently doesn't have any kind of UI indication.

- (void)downloadStream:(KBYTStream *)stream
{
    //currently just one download at a time.
    if (self.downloading == true)
    {
        return;
    }
    
    self.downloadFile = [KBYTDownloadStream new];
    NSInteger durationSeconds = [self.currentMedia.duration integerValue];
    [self.downloadFile setTrackDuration:durationSeconds*1000];
    self.downloading = true;
    [self.downloadFile downloadStream:stream progress:^(double percentComplete, NSString *downloadedFile) {
        
        NSLog(@"downloadProgress: %f", percentComplete);
        
        
    } completed:^(NSString *downloadedFile) {
        
        NSLog(@"file download complete: %@", downloadedFile);
        [self playCompleteSound];
        self.downloading = false;
    }];
    
}

@end

