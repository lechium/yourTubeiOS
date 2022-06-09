//
//  TYGridUserViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//

#import "TYBaseGridViewController.h"

@interface TYGridUserViewController : TYBaseGridViewController
{
    BOOL _jiggling;
    UITapGestureRecognizer *menuTapRecognizer;
    UITapGestureRecognizer *_pressGestureRecognizer;
    UITapGestureRecognizer *_playPauseGestureRecognizer;
}

- (void)updateUserData:(NSDictionary *)userData;
@end
