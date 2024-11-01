//
//  RZSplitViewController.h
//
//  Created by Joe Goullaud on 8/6/12.

// Copyright 2014 Raizlabs and other contributors
// http://raizlabs.com/
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import "KBYTDownloadCell.h"

@class KBYTPlaylist;

@interface PlaylistTableViewCell : KBYTDownloadCell

@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, strong) UIColor *viewBackgroundColor;

@end

@protocol PLDetailViewSelectionDelegate <NSObject>

- (void)selectedItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)addImageURLs:(NSArray *)URLs;

@end

@interface PLDetailViewController : UIViewController <PLDetailViewSelectionDelegate>


@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) NSArray *imageURLs;

- (void)addImageURLs:(NSArray *)urls;

@end

@protocol PlaylistTableViewSelectionDelegate <NSObject>

- (void)itemSelectedAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface PlaylistTableViewController : UITableViewController <PLDetailViewSelectionDelegate>

@property (nonatomic, weak) id<PlaylistTableViewSelectionDelegate> selectionDelegate;
@property (nonatomic, weak) id<PLDetailViewSelectionDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *itemNames;
@property (nonatomic, weak) NSString *nextHREF;
@property (nonatomic, strong) KBYTPlaylist *playlistItem;
@property (nonatomic, strong) void (^alertHandler)(UIAlertAction *action);
@property (nonatomic, strong) void (^channelAlertHandler)(UIAlertAction *action);

- (void)focusedCell:(UITableViewCell *)focusedCell;

@end


@protocol PlaylistViewDelegate <NSObject>


- (void)itemSelectedAtIndexPath:(NSIndexPath *)indexPath fromNavigationController:(UINavigationController *)nav;

@end

@interface YTTVPlaylistViewController : UIViewController <PlaylistTableViewSelectionDelegate>

/*

 properties copied over from the settings view
 
 */


@property (nonatomic, weak) id <PlaylistViewDelegate> selectionDelegate;
@property (nonatomic, strong) NSArray *itemNames;
@property (nonatomic, strong) NSArray *imageNames;
@property (nonatomic, strong) NSString *viewTitle;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) NSString *loadMoreHREF;
@property (nonatomic, strong) UILabel *titleView;


@property (copy, nonatomic) NSArray *viewControllers;
@property (weak, nonatomic) id delegate;        // Not used yet
@property (strong, nonatomic) UIImage *collapseBarButtonImage;
@property (strong, nonatomic) UIImage *expandBarButtonImage;
@property (strong, nonatomic, readonly) UIBarButtonItem *collapseBarButton;
@property (assign, nonatomic, getter = isCollapsed) BOOL collapsed;
@property (nonatomic, assign) CGFloat masterWidth;
@property (strong, nonatomic) UIColor* viewBorderColor;
@property (nonatomic, assign) CGFloat viewCornerRadius;
@property (nonatomic, assign) CGFloat viewBorderWidth;
@property (readwrite, assign) CGFloat preferredPrimaryColumnWidthFraction; //doesnt do anything right now


@property (nonatomic, readonly) UIViewController *masterViewController;
@property (nonatomic, readonly) UIViewController *detailViewController;

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated;
- (void)setDetailViewController:(UIViewController*)detailVC;
- (void)setMasterViewController:(UIViewController*)masterVC;

/*
 
 you MUST initialize with this method or nothing will work and everything will need to be done manually! (for now)
 
 */

+ (id)playlistViewControllerWithTitle:(NSString *)theTitle backgroundColor:(UIColor *)bgColor withPlaylistItems:(NSArray *)playlistItems;

+ (id)playlistViewControllerForPlaylist:(KBYTPlaylist *)playlist backgroundColor:(UIColor* )bgColor;

@end


