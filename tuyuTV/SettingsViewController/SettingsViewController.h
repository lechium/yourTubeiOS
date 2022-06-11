//
//  ViewController.h
//  tvOSSettings
//
//  Created by Kevin Bradley on 3/18/16.
//  Copyright © 2016 nito. All rights reserved.
//

/**

 This is a rough attempt at creating a highly customizable list / settings view on tvOS, an attempt to recreate BRMediaMenuControllers and BRMetadataControls from the older generation AppleTV's. Full disclosure my AutoLayout skills are still very fresh so I'm certain I'm doing some things wrong. And there is DEFINITELY a lot of ambiguous layout so this view hierarchy is incredible fragile. Thank being said, the latest modifications appear to make it pretty robust and flexible so far.
 
 if you set the backgroundColor the views will update as necessary, and if you choose a blackBackground color the meta
 will update as necessary to a white color.
 
 Check MetadataPreviewView.h for more information on the formatting of the metadata dictionary / asset.
 
 
 the unfocusedBackgroundColor code is based on code taken from this gist
 
 https://gist.github.com/mhpavl/f7819743027684b9e890
 

 */
#import "UIView+RecursiveFind.h"
#import "MetadataPreviewView.h"

#import <UIKit/UIKit.h>

#define DEFAULT_TABLE_OFFSET 180

@interface SettingsTableViewCell : UITableViewCell
{
    UIColor *unfocusedBackgroundColor;

}


@end

@interface DetailView : UIView

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) MetadataPreviewView *previewView;


- (void)updateMetaColor;

@end

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSString *_backingTitle;
    BOOL _observersRegistered;
}

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSString *defaultImageName;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) DetailView *detailView;
@property (readwrite, assign) CGFloat topOffset;
@property (readwrite, assign) CGFloat metaTopOffset;
@property (nonatomic, strong) NSIndexPath *focusedIndexPath;
@property (nonatomic, strong) NSIndexPath *savedIndexPath;
@property (nonatomic, strong) NSArray <MetaDataAsset *>*extraItems; //optional
@property (nonatomic, strong) NSString *extraTitle; //optional
- (void)safeReloadData;
- (void)focusedCell:(SettingsTableViewCell *)focusedCell;
- (void)performLongPressActionForSelectedRow;
@end

