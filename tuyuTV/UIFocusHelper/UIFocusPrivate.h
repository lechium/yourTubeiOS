//
//  UIFocusPrivate.h
//  UIFocusHelper
//
//  Created by Kevin Bradley on 1/15/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface _UIFocusMapSnapshot : NSObject
-(UIImage *)debugQuickLookObject;
@end

@interface _UIFocusRegion: NSObject
- (CGRect)frame;
@end

@interface _UIFocusMapSnapshotter: NSObject
@property (nonatomic,copy) _UIFocusRegion * focusedRegion;
-(id)captureSnapshot;
-(void)setSnapshotFrame:(CGRect)arg1;
-(void)setClipToSnapshotRect:(BOOL)arg1;
-(id)initWithFocusSystem:(id)arg1 rootContainer:(id)arg2 coordinateSpace:(id)arg3 searchInfo:(id)arg4;
//15.x+
- (id)initWithFocusSystem:(id)arg1 rootContainer:(id)arg2 coordinateSpace:(id)arg3 searchInfo:(id)arg4 ignoresRootContainerClippingRect:(_Bool)arg5;
@end

@interface _UIFocusSystemSceneComponent: NSObject
+(id)sceneComponentForFocusSystem:(UIFocusSystem*)system;
-(id)coordinateSpace;
@end

@interface UIFocusUpdateContext (priv)
-(id)_initWithFocusMovementRequest:(id)arg1 nextFocusedItem:(id)arg2;
@end

@interface _UIFocusSearchInfo : NSObject
+(id)defaultInfo;
@end

@interface _UIFocusMovementInfo: NSObject
//14.5 +
-(id)initWithHeading:(unsigned long long)arg1 linearHeading:(unsigned long long)arg2 isInitial:(BOOL)arg3 shouldLoadScrollableContainer:(BOOL)arg4 looping:(BOOL)arg5 groupFilter:(long long)arg6;
//14.0 - 14.4
+(id)_movementWithHeading:(unsigned long long)arg1 linearHeading:(unsigned long long)arg2 shouldLoadScrollableContainer:(BOOL)arg3 isInitial:(BOOL)arg4 looping:(BOOL)arg5;
@end

@interface _UIFocusItemInfo: NSObject
-(_UIFocusRegion *)focusedRegion;
//16+
- (struct CGRect)focusedRectInCoordinateSpace:(id)arg1;
//14-15
-(id)_focusedRegionInCoordinateSpace:(id)arg1;
@end

@interface _UIFocusMovementRequest : NSObject
@property (nonatomic,retain) _UIFocusMovementInfo * movementInfo;
@property (nonatomic,retain) _UIFocusSearchInfo * searchInfo;
@property (nonatomic,retain) _UIFocusItemInfo * focusedItemInfo;

-(id)initWithFocusSystem:(id)arg1 window:(id)arg2;
@end


