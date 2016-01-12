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
@interface OurViewController ()

@end

@implementation OurViewController

@synthesize downloading;

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view.backgroundColor = [UIColor redColor];
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
    } else {
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
    self.downloading = false;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]
                                      init];
    
    if ([config respondsToSelector:@selector(requiresUserActionForMediaPlayback)])
    {
        //    config.requiresUserActionForMediaPlayback = true;
    }
    config.mediaPlaybackRequiresUserAction = true;
    config.allowsInlineMediaPlayback = false;
    
    self.webView = [[WKWebView alloc] initWithFrame:mainFrame configuration:config];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [[self view] addSubview:self.webView];
    
    //a script to attempt to pause any videos from autoplaying, used in conjunction with a bunch of other hacks
    //to stop autoplaying from occuring.
    
    NSString *scriptContent = @"var videos = document.querySelectorAll(\"video\"); for (var i = videos.length - 1; i >= 0; i--) { videos[i].pause(); };";
    
    if (scriptContent)
    {
        WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptContent injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        [config.userContentController addUserScript:script];
        [config.userContentController addScriptMessageHandler:self name:MessageHandler];
    }
    
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:@"https://www.youtube.com"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    //these observers are a hacky way to know a good time to check URL to see if we land on a page that has a video URL
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    [[self webView] setNavigationDelegate:self];
    [[self webView] loadRequest:request];
    
}

//currently unused
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    LOG_SELF;
    if ([message.name isEqualToString:MessageHandler]) {
        
        id postList = message.body;
        
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

    }
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        //   NSLog(@"estimated progress: %f", self.webView.estimatedProgress);
    }
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
        
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
                if ([self.currentMedia.videoId isEqualToString:videoID])
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
        }
        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//the action sheet result handler
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    KBYTStream *chosenStream = nil;
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
            break;
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
    NSString *actionSheetTitle = [NSString stringWithFormat:@"Choose action for %@", self.currentMedia.title];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Play video", @"Download Video", @"Download Audio", nil];
    
    [actionSheet showInView:self.view];
}

//actually get the video details for the selected video.

- (void)getVideoIDDetails:(NSString *)details
{
    [[KBYourTube sharedInstance] getVideoDetailsForID:details completionBlock:^(KBYTMedia *videoDetails) {
        
        if (self.currentMedia != nil)
        {
            if ([self.currentMedia.videoId isEqualToString:videoDetails.videoId])
            {
                NSLog(@"already got this video, dont do anything");
                return;
            }
        }
        
        //  NSLog(@"got details successfully: %@", videoDetails);
        self.currentMedia = videoDetails;
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

//play the video stream
- (IBAction)playStream:(KBYTStream *)stream
{
    NSURL *playURL = [stream url];
   //NSLog(@"play url: %@", playURL);
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            NSLog(@"already playing");
            return;
        }
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
