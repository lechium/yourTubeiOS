//
//  TYUserShelfViewController.h
//  tuyuTV
//
//  Created by js on 9/28/24.
//

#import "TYBaseShelfViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TYUserShelfViewController : TYBaseShelfViewController {
    BOOL _jiggling;
    UITapGestureRecognizer *menuTapRecognizer;
    UITapGestureRecognizer *_pressGestureRecognizer;
    UITapGestureRecognizer *_playPauseGestureRecognizer;
}

@end

NS_ASSUME_NONNULL_END
