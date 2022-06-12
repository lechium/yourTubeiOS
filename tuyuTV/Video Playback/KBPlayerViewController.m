//
//  KBPlayerViewController.m
//  Ethereal
//
//  Created by kevinbradley on 9/18/21.
//  Copyright © 2021 nito. All rights reserved.
//

#import "KBPlayerViewController.h"

@implementation KBQueuePlayer
@end

@interface KBPlayerViewController () {
    NSURL *_mediaURL;
}

@end

@implementation KBPlayerViewController

- (NSURL *)mediaURL {
    return _mediaURL;
}

- (BOOL)setMediaURL:(NSURL *)mediaURL {
    _mediaURL = mediaURL;
    AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:mediaURL];
    if (![[singleItem asset] isPlayable]){
        TLog(@"this is not playable!!");
        singleItem = nil;
        return false;
    }
    self.player = [KBQueuePlayer playerWithPlayerItem:singleItem];
    [self.player play];
    return true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
