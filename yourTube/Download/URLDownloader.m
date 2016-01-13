//
//  Downloader.m
//  iOS-URLDownloader
//
//  Created by Kristijan Sedlak on 7/21/11.
//  Copyright 2011 AppStrides. All rights reserved.
//

#import "URLDownloader.h"


#pragma mark -

@interface URLDownloader()

@property(retain) NSURLConnection *urlConnection;
@property(retain) NSURLResponse *urlResponse;
@property(retain) NSMutableData *urlData;
@property(retain) URLCredential *urlCredential;

@end


#pragma mark -

@implementation URLDownloader

@synthesize delegate;
@synthesize state;

@synthesize urlConnection;
@synthesize urlResponse;
@synthesize urlData;
@synthesize urlCredential;

#pragma mark Setters

- (void)setState:(URLDownloaderState)downloaderState
{
    if (downloaderState != state) 
    {
        state = downloaderState;
        if ([self.delegate respondsToSelector:@selector(urlDownloader:didChangeStateTo:)])
        {
            [self.delegate urlDownloader:self didChangeStateTo:downloaderState];
        }
    }
}

#pragma mark General

- (void)dealloc 
{
    [urlConnection cancel];
    
	//[delegate release];
    
	//[urlConnection release];
    //[urlResponse release];
//	[urlData release];
  //  [urlCredential release];
	
   // [super dealloc];
}

- (id)initWithDelegate:(id)obj
{
	if(self == [self init])
	{
		self.delegate = obj;
        [self setState:URLDownloaderStateInactive];
	}
	return self;
}

+ (id)downloaderWithDelegate:(id)obj
{
    return [[URLDownloader alloc] initWithDelegate:obj];
}

- (void)reset
{
  //  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark Actions

- (void)download:(NSURLRequest *)request withCredential:(URLCredential *)credential
{
    [self setState:URLDownloaderStateConnecting];
    
    self.urlCredential = credential;
    self.urlResponse = nil;
	self.urlData = [[NSMutableData alloc] init];
	self.urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];

    [self.urlConnection start];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSLog(@"[URLDownloader] Download started");
}

- (void)cancel
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
	[urlConnection cancel];
	
	NSLog(@"[URLDownloader] Download canceled");
    if ([self.delegate respondsToSelector:@selector(urlDownloaderDidCancelDownloading:)])
    {
        [self.delegate urlDownloaderDidCancelDownloading:self];
    }
    
    [self setState:URLDownloaderStateCanceled];
}

#pragma mark Information

- (int)fullContentSize
{
    @try 
    {
        return [[NSNumber numberWithLongLong:[urlResponse expectedContentLength]] intValue]; 
    }
    @catch (NSException * e) 
    {
        return 0;
    }
}

- (int)downloadedContentSize
{
    @try 
    {
        return [[NSNumber numberWithInteger:[self.urlData length]] intValue];
    }
    @catch (NSException * e) 
    {
        return 0;
    }
}

- (float)downloadCompleteProcent
{
    float contentSize = [self fullContentSize];
    float downloadedSize = [self downloadedContentSize];

    return contentSize > 0.0 ? downloadedSize / contentSize : 0.0;
}

#pragma mark Connection

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self setState:URLDownloaderStateAuthenticating];
    
	if ([challenge previousFailureCount] == 0)
	{
		NSLog(@"[URLDownloader] Authentication challenge received");
		
		NSURLCredential *credential = [NSURLCredential credentialWithUser:self.urlCredential.username
																 password:self.urlCredential.password
															  persistence:self.urlCredential.persistance];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];

		NSLog(@"[URLDownloader] Credentials sent");
	}
	else
	{
   //     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
		NSLog(@"[URLDownloader] Authentication failed");
        [self.delegate urlDownloader:self didFailOnAuthenticationChallenge:challenge];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.urlResponse = response;
    [self.urlData setLength:0]; // in case of 302

    [self setState:URLDownloaderStateDownloading];
    NSLog(@"[URLDownloader] Downloading %@ ...", [[response URL] absoluteString]);
    if ([self.delegate respondsToSelector:@selector(urlDownloaderDidStart:)])
    {
        [self.delegate urlDownloaderDidStart:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
	[self.urlData appendData:data];
    
    if ([self.delegate respondsToSelector:@selector(urlDownloader:didReceiveData:)])
    {
        [self.delegate urlDownloader:self didReceiveData:data];
    }

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
    [self setState:URLDownloaderStateInactive];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	NSLog(@"[URLDownloader] Error: %@, %d", error, [error code]);
	switch ([error code])
	{
		case NSURLErrorNotConnectedToInternet:
			[self.delegate urlDownloader:self didFailWithNotConnectedToInternetError:error];
			break;
		default:
            [self.delegate urlDownloader:self didFailWithError:error];;
			break;
	}    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    NSLog(@"[URLDownloader] Download finished");

    NSData *data = [NSData dataWithData:self.urlData];
    [self.delegate urlDownloader:self didFinishWithData:data];

    [self setState:URLDownloaderStateFinished];
}

@end
