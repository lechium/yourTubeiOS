//
//  KBFocusHelper.m
//  UIFocusHelper
//
//  Created by Kevin Bradley on 1/15/24.
//

#import "KBFocusHelper.h"

//TODO: Research _UIFocusMap.h

@implementation KBFocusHelper

+ (UIImage *)createFocusSnapshotFromViewController:(UIViewController *)viewController clipping:(BOOL)clipping {
    return [self createFocusSnapshotFromViewController:viewController withHeading:UIFocusHeadingDown clipping:clipping];
}

+ (UIImage *)createFocusSnapshotFromViewController:(UIViewController *)viewController withHeading:(UIFocusHeading)focusHeading clipping:(BOOL)clipping {
    
    id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    UIWindow *window = [appDelegate window];
    UIFocusSystem *fs = [UIFocusSystem focusSystemForEnvironment:viewController];
    //_UIFocusMovementRequest need to make one of these to have the focus engine assess the layout to create a 'quick look' representation
    NSArray *uifmr = @[@"_U", @"IFoc", @"usMo", @"veme", @"ntRequest"];
    id focusMovementRequest = [[NSClassFromString([uifmr componentsJoinedByString:@""]) alloc] initWithFocusSystem:fs window:window];
    NSArray *uifmi = @[@"_U",@"IFo", @"cus", @"Mov", @"eme", @"ntInfo"];
    SEL movementInfoSelector = @selector(initWithHeading:linearHeading:isInitial:shouldLoadScrollableContainer:looping:groupFilter:);
    Class uifmiClass = NSClassFromString([uifmi componentsJoinedByString:@""]);
    id movementInfo = nil; //_UIFocusMovementInfo, need these to tell the focus manager what direction to calculate the focus path for
    if ([uifmiClass instancesRespondToSelector:movementInfoSelector]) { //14.5+
        movementInfo = [[uifmiClass alloc] initWithHeading:focusHeading linearHeading:0 isInitial:true shouldLoadScrollableContainer:true looping:false groupFilter:0];
    } else { //14.0 -> 14.4
        movementInfo = [uifmiClass _movementWithHeading:focusHeading linearHeading:0 shouldLoadScrollableContainer:true isInitial:true looping:false];
    }
    //NSLog(@"movementInfo: %@", movementInfo);
    [focusMovementRequest setMovementInfo:movementInfo];
    id itemInfo = [focusMovementRequest focusedItemInfo]; //_UIFocusItemInfo
    id searchInfo = [focusMovementRequest searchInfo]; //_UIFocusSearchInfo
    id region = [itemInfo focusedRegion]; //14-15: _UIFocusRegion 16+: _UIFocusItemRegion
    //Need coordinate space, can get it from other places too, but this still works so meh
    NSArray *uifssc = @[@"_U",@"IFo",@"cu",@"sSys",@"temS",@"cen",@"eCom",@"ponent"]; //_UIFocusSystemSceneComponent
    id sceneComp = [NSClassFromString([uifssc componentsJoinedByString:@""]) sceneComponentForFocusSystem: fs];
    id coordSpace = [sceneComp coordinateSpace];
    NSArray *uifmss = @[@"_U",@"IF",@"oc",@"usM",@"apS",@"nap",@"shotter"];
    Class snapshotterClass = NSClassFromString([uifmss componentsJoinedByString:@""]); //_UIFocusMapSnapshotter
    id snapshotter = nil;
    if ([snapshotterClass instancesRespondToSelector:@selector(initWithFocusSystem:rootContainer:coordinateSpace:searchInfo:)]) {
        snapshotter = [[snapshotterClass alloc] initWithFocusSystem:fs rootContainer:window coordinateSpace:coordSpace searchInfo:searchInfo];
    } else { //16+
        snapshotter = [[snapshotterClass alloc] initWithFocusSystem:fs rootContainer:window coordinateSpace:coordSpace searchInfo:searchInfo ignoresRootContainerClippingRect:true];
    }
    [snapshotter setFocusedRegion: region];
    if (clipping) {
        CGRect frame = CGRectZero;
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        if ([region respondsToSelector:@selector(frame)]) { //_UIFocusRegion
            frame = [region frame];
        } else { // in 16 + its a _UIFocusItemRegion instead of _UIFocusRegion, need to convert the coordinate space
            frame = [itemInfo focusedRectInCoordinateSpace:[UIScreen mainScreen]];
        }
            switch (focusHeading) {
                case UIFocusHeadingDown:
                    frame.origin.y += frame.size.height;
                    frame.size.height = screenSize.height - frame.origin.y;
                    break;
                    
                case UIFocusHeadingRight:
                    frame.origin.x += frame.size.width;
                    frame.size.width = screenSize.width - frame.origin.x;
                    break;
                case UIFocusHeadingLeft:
                    frame.size.width = frame.origin.x;
                    frame.origin.x = -2;
                    break;
                case UIFocusHeadingUp:
                    frame.size.height = frame.origin.y;
                    frame.origin.y = -1;
                    break;
                default:
                    break;
            }
            [snapshotter setSnapshotFrame:frame];
            [snapshotter setClipToSnapshotRect:true];
    }
    id shot = [snapshotter captureSnapshot];
    return [shot debugQuickLookObject];
}

@end
