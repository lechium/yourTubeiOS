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

@synthesize downloader, downloading;

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

- (void)videoPlayingDidChange:(NSNotification *)notification
{
    NSLog(@"userInfo: %@", notification.userInfo);
    BOOL isPlaying = [notification.userInfo[@"IsPlaying"] boolValue];
    if (isPlaying == true) {
        NSLog(@"is playing!!!");
    } else {
        NSLog(@"is not playing");
    }
    // Do stuff with this newfound knowledge
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPlayingDidChange:)
                                                 name:@"SomeClientPlayingDidChange"
                                               object:nil];
    
    // Video playing state handler
    
    //  self.view = [[WKWebView alloc] init];
    CGRect mainFrame = [[self view] frame];
   // mainFrame.origin.y = 30;
    //mainFrame.size.height -= 30;
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
    // WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    //[config setRequiresUserActionForMediaPlayback:TRUE];
    
    //[[self webView]configuration];
    [[self view] addSubview:self.webView];
    
    NSString *scriptContent = @"var videos = document.querySelectorAll(\"video\"); for (var i = videos.length - 1; i >= 0; i--) { videos[i].pause(); };";
    
    if (scriptContent)
    {
        WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptContent injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        
        [config.userContentController addUserScript:script];
        [config.userContentController addScriptMessageHandler:self name:MessageHandler];
    }
    
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:@"https://www.youtube.com"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    [[self webView] setNavigationDelegate:self];
    //[(WKWebView *)[self view].navigationDelegate ]= self;
    [[self webView] loadRequest:request];
    
    //[[ourWebView mainFrame] loadRequest:request];
    //[[self webWindow] makeKeyAndOrderFront:self];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    LOG_SELF;
    if ([message.name isEqualToString:MessageHandler]) {
        
        id postList = message.body;
        /*
        if ([postList respondsToSelector:@selector(objectEnumerator)])
        {
            [self.posts removeAllObjects];
            
            for (NSDictionary *ps in postList)
            {
                Post *post = [[Post alloc]init];
                post.postTitle = [ps objectForKey:@"postTitle"];
                post.postURL = [ps objectForKey:@"postURL"];
                [self.posts addObject:post];
            }
            
            self.recentPostsButton.enabled = YES;
        }
         */
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        //  self.backButton.enabled = self.webView.canGoBack;
        //self.forwardButton.enabled = self.webView.canGoForward;
    }
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        //   NSLog(@"estimated progress: %f", self.webView.estimatedProgress);
        //self.progressView.hidden = self.webView.estimatedProgress == 1;
        //[self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }
    if ([keyPath isEqualToString:@"title"]) {
         NSLog(@"title changed: %@ url: %@", self.webView.title, self.webView.URL);
        self.title = self.webView.title;
       
        if (self.gettingDetails == true)
        {
            NSLog(@"already getting details, dont try again...");
            return;
        }
        
        
        if ([self.webView.title isEqualToString:@"YouTube"]) {
            return;
        }
        NSDictionary *paramDict = [self.webView.URL parameterDictionary];
        NSLog(@"paramDict: %@", paramDict);
        //NSString *absoluteWV = self.webView.URL.absoluteString;
       // if ([absoluteWV containsString:@"youtube.com/watch?v="])
       if ( [[paramDict allKeys] containsObject:@"v"])
        {
            //NSString *videoID = [[absoluteWV componentsSeparatedByString:@"="] lastObject];
            NSString *videoID = paramDict[@"v"];
            NSLog(@"videoID: %@", videoID);
            
            if (self.currentMedia != nil)
            {
                NSLog(@"self current media: %@", self.currentMedia);
                if ([self.currentMedia.videoId isEqualToString:videoID])
                {
                    
                    return;
                }
            }
          
            NSURL *backURL = [[[[self webView] backForwardList] backItem] URL];
            NSLog(@"backURL: %@", backURL);
            [[self webView] stopLoading];
            [[self webView] goBack];
            
            
            [[self webView] loadHTMLString:@"<html/>" baseURL:nil];
            NSURLRequest * request = [[NSURLRequest alloc]initWithURL:backURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [[self webView] loadRequest:request];
            [self getVideoIDDetails:videoID];
            self.gettingDetails = true;
            //[self getVideoDetailsDelayed:videoID];
        }
        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (void)playCompleteSound
{
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"complete" ofType:@"aif"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: thePath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

- (void)showActionSheet
{
    
    NSString *actionSheetTitle = [NSString stringWithFormat:@"Choose action for %@", self.currentMedia.title];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:actionSheetTitle delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Play video", @"Download Video", @"Download Audio", nil];
    
    [actionSheet showInView:self.view];
}

- (void)getVideoIDDetails:(NSString *)details
{
    NSLog(@"getVideoIDDetails: %@", details);
    LOG_SELF;
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
        //KBYTStream *audioStream = [[videoDetails streams] objectAtIndex:0];
        //[self playStream:audioStream];
        [self performSelectorOnMainThread:@selector(showActionSheet) withObject:nil waitUntilDone:false];
        
        
        
        //[self downloadStream:audioStream];
        /*
         self.titleField.stringValue = videoDetails.title;
         self.userField.stringValue = videoDetails.author;
         self.lengthField.stringValue = videoDetails.duration;
         self.viewsField.stringValue = videoDetails.views;
         self.imageView.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:videoDetails.images[@"high"]]];
         
         self.currentMedia = videoDetails;
         self.streamArray = videoDetails.streams;
         self.streamController.selectsInsertedObjects = true;
         
         [[self window] orderFrontRegardless];
         */
        
    } failureBlock:^(NSString *error) {
        
        NSLog(@"fail!: %@", error);
        
    }];
}

- (void)getVideoDetailsDelayed:(NSString *)videoDetails
{
    [self performSelector:@selector(getVideoIDDetails:) withObject:videoDetails afterDelay:0.5];
    // [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(getVideoIDDetails:) userInfo:videoDetails repeats:false];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler

{
    NSURL *url = navigationAction.request.URL;
    //  NSLog(@"webviewURL: %@ title: %@", webView.URL, webView.title);
    //    NSLog(@"url: %@ type: %i", url, navigationAction.navigationType);
   // NSString *absoluteWV = webView.URL.absoluteString;
    //if ([absoluteWV containsString:@"youtube.com/watch?v="])
    NSDictionary *paramDict = [self.webView.URL parameterDictionary];
    NSLog(@"paramDict: %@", paramDict);
    //NSString *absoluteWV = self.webView.URL.absoluteString;
    // if ([absoluteWV containsString:@"youtube.com/watch?v="])
    if ( [[paramDict allKeys] containsObject:@"v"])
    {
        //     NSString *videoID = [[absoluteWV componentsSeparatedByString:@"="] lastObject];
        //   NSLog(@"videoID: %@", videoID);
        // [self getVideoDetailsDelayed:videoID];
        //[webView goBack];
         //[webView stopLoading];
        [self pauseVideos];
        decisionHandler(WKNavigationActionPolicyCancel);
        
        //[self getVideoIDDetails:videoID];
        
        return;
    }
    
    NSString *absolute = [url absoluteString];
    //if ([absolute containsString:@"googleads.g.doubleclick.net"]  || [absolute containsString:@"about:blank"])
    if([absolute containsString:@"googleads.g.doubleclick.net"])
    {
        NSLog(@"fuck yo ads beeetch");
        //[webView goBack];
         [self pauseVideos];
        [webView stopLoading];
        
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler

{
    NSURL *url = navigationResponse.response.URL;
    NSLog(@"decidePolicyForNavigationResponse url: %@", url);
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
//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
//{
//    LOG_SELF;
//}

- (IBAction)playStream:(KBYTStream *)stream
{
    NSURL *playURL = [stream url];
    NSLog(@"play url: %@", playURL);
    if ([self player] != nil)
    {
        if (self.player.rate != 0)
        {
            NSLog(@"already playing");
            return;
        }
    }
    
    self.playerView = [AVPlayerViewController alloc];
    //Show the controls
    self.playerView.showsPlaybackControls = true;
    self.player = [AVPlayer playerWithURL:playURL];
    self.playerView.player = self.player;
  //  self.downloading = true;
  //  [self presentModalViewController:self.playerView animated:true];
  //  id delegate = [UIApplication sharedA]
    [[self delegate] pushViewController:self.playerView];
    [self.player play];
    
}

- (void)downloadStream:(KBYTStream *)stream
{
    if (self.downloading == true)
    {
        NSLog(@"already downloading");
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



- (void)stopDownload
{
    [self.downloader cancel];
}
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didFinishWithData:(NSData *)data
{
}

- (void)urlDownloader:(URLDownloader *)urlDownloader didChangeStateTo:(URLDownloaderState)state
{
}

- (void)urlDownloader:(URLDownloader *)td didFailOnAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
}
- (void)urlDownloader:(URLDownloader *)td didFailWithError:(NSError *)error {
}
- (void)urlDownloader:(URLDownloader *)td didFailWithNotConnectedToInternetError:(NSError *)error{
}

- (void)urlDownloaderDidStart:(URLDownloader *)td {
}
- (void)urlDownloaderDidCancelDownloading:(URLDownloader *)td {
}
- (void)urlDownloader:(URLDownloader *)td didReceiveData:(NSData *)data {
    float percent = [td downloadCompleteProcent];
    NSLog(@"percentComplete: %f", percent);
    
}

@end

