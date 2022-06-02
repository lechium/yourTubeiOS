//
//  ViewController.m
//  tvOSSettings
//
//  Created by Kevin Bradley on 3/18/16.
//  Copyright © 2016 nito. All rights reserved.
//

#import "SettingsViewController.h"
#import "PureLayout.h"
#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"


 

@implementation SettingsTableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{

    unfocusedBackgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    self.contentView.backgroundColor = unfocusedBackgroundColor;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = true;
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.accessoryView.backgroundColor = unfocusedBackgroundColor;
    //NSString *recursiveDesc = [self performSelector:@selector(recursiveDescription)];
    //NSLog(@"%@", recursiveDesc);

}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    
    [coordinator addCoordinatedAnimations:^{
    
         self.contentView.backgroundColor = self.focused ? [UIColor clearColor] : unfocusedBackgroundColor;
         self.accessoryView.backgroundColor = self.focused ? [UIColor clearColor] : unfocusedBackgroundColor;
         self.layer.masksToBounds = !self.focused;
        
    } completion:^{
        
    }];

}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end

/**
 
 The detail view that contains the centered UIImageView on the left hand side
 
 */

@implementation DetailView

- (id)initForAutoLayout
{
    self = [super initForAutoLayout];
    [self addSubview:self.previewView];
    //[self addSubview:self.imageView];
    return self;
}

- (void)updateConstraints{
    
   // [NSLayoutConstraint deactivateConstraints:self.constraints];
    
    //[self.previewView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.superview];
    //[self.previewView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.superview];
    [self.previewView autoCenterInSuperview];
    [super updateConstraints];
}

- (void)updateMetaColor
{
    UIColor *newColor = [UIColor blackColor];
    if (self.backgroundColor == [UIColor blackColor])
    {
        newColor = [UIColor whiteColor];
    }
    for (MetadataLineView *lineView in self.previewView.linesView.subviews) {
        
        NSLog(@"lineView: %@", lineView);
        if ([lineView isKindOfClass:[MetadataLineView class]])
        {
            [lineView.valueLayer setTextColor:newColor];
        }
        
    }
    [self.previewView.titleLabel setTextColor:newColor];
    [self.previewView.descriptionLabel setTextColor:newColor];
}

#pragma mark •• bootstrap data, change here for base data layout.
- (MetadataPreviewView *)previewView
{
  if (!_previewView) {
  

      //NOTE: this is a bit of a hack im not sure why its necessary right now, apparently even a blank imagePath prevents
      //layout issues.
    _previewView = [[MetadataPreviewView alloc] initWithMetadata:@{@"imagePath": @""}];
        
    }
    return _previewView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [UIImageView newAutoLayoutView];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.image = [UIImage imageNamed:@"package"];
    }
    return _imageView;
}


@end


@interface SettingsViewController ()


@property (nonatomic, strong) UIView *tableWrapper;
@property (nonatomic, assign) BOOL didSetupConstraints;


@end

@implementation SettingsViewController

- (void)loadView
{
    self.view = [UIView new];
    
    [self.view addSubview:self.detailView];
    [self.view addSubview:self.tableWrapper];
    [self.view addSubview:self.titleView];
    
    //self.title = @"Settings";
    
    
    [self.view setNeedsUpdateConstraints]; // bootstrap Auto Layout
}

- (void)updateViewConstraints
{
    CGRect viewBounds = self.view.bounds;
    
    //use this variable to keep track of whether or not initial constraints were already set up
    //dont want to do it more than once
    if (!self.didSetupConstraints) {
        
        //half the size of our total view / pinned to the left
        [self.detailView autoSetDimensionsToSize:CGSizeMake(viewBounds.size.width/2, viewBounds.size.height)];
        [self.detailView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.view];
        
        //half the size of our total view / pinned to the right
        
        [self.tableWrapper autoSetDimensionsToSize:CGSizeMake(viewBounds.size.width/2, viewBounds.size.height)];
        [self.tableWrapper autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.view];
        
        //position the tableview inside its wrapper view
        
        [self.tableView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.tableWrapper withOffset:50];
        [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:80];
        [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.tableWrapper withOffset:180];
        [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:50];
        
        
        //set up our title view
        
        [self.titleView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:56];
        [self.titleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        
        self.didSetupConstraints = YES;
    }
    
    [super updateViewConstraints];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
   // [self.view observationInfo];
       @try {
           [self.view removeObserver:self forKeyPath:@"backgroundColor" context:NULL];
           [self removeObserver:self forKeyPath:@"titleColor" context:NULL];
           [self removeObserver:self forKeyPath:@"title" context:NULL];
       }
     @catch (NSException * __unused exception) {}
    _observersRegistered = false;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.titleView.text = _backingTitle;
    [self registerObservers];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   // NSString *recursiveDesc = [self.view performSelector:@selector(recursiveDescription)];
   // NSLog(@"%@", recursiveDesc);

}

//its necessary to create a title view in case you are the first view inside a navigation controller
//which doesnt show a title view for the root controller iirc
- (UILabel *)titleView
{
    if (!_titleView) {
        _titleView = [UILabel newAutoLayoutView];
        _titleView.font = [UIFont fontWithName:@".SFUIDisplay-Medium" size:57.00];
        _titleView.textColor = [UIColor grayColor];
    }
    return _titleView;
}

- (UIView *)tableWrapper;
{
    if (!_tableWrapper) {
        _tableWrapper = [UIView newAutoLayoutView];
        _tableWrapper.autoresizesSubviews = true;
        _tableView = [[UITableView alloc] initForAutoLayout];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [self.tableView registerClass:[SettingsTableViewCell class] forCellReuseIdentifier:@"SettingsCell"];
        _tableView.backgroundColor = self.view.backgroundColor;
        [_tableWrapper addSubview:_tableView];
        _tableWrapper.backgroundColor = self.view.backgroundColor;
    }
    return _tableWrapper;
}

- (UIView *)detailView
{
    if (!_detailView) {
        _detailView = [[DetailView alloc] initForAutoLayout];
        _detailView.backgroundColor = self.view.backgroundColor;
    }
    return _detailView;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    id newValue = change[@"new"];
    
    //a bit of a hack to hide the navigationItem title view when title is set
    //and to use our own titleView that can have different colors
    
    if ([keyPath isEqualToString:@"title"])
    {
        if (newValue != [NSNull null])
        {
            if ([newValue length] > 0)
            {
                //keep a backup copy of the title
                _backingTitle = newValue;
                //self.titleView.text = newValue;
                //self.title = @"";
            }
        }
    }
    
    //change subviews to have the same background color
    if ([keyPath isEqualToString:@"backgroundColor"])
    {
        self.detailView.backgroundColor = newValue;
        self.tableWrapper.backgroundColor = newValue;
        self.tableView.backgroundColor = newValue;
        [self.detailView updateMetaColor];
    }
    
    //change titleView to a different text color
    
    if ([keyPath isEqualToString:@"titleColor"])
    {
        self.titleView.textColor = newValue;
    }
    

}

- (void)registerObservers
{
    if (_observersRegistered == true) return;
    //use KVO to update subview backgroundColor to mimic the superview backgroundColor
    
    [self.view addObserver:self
                forKeyPath:@"backgroundColor"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];
    
    //use KVO to allow different colors for the title
    
    [self addObserver:self
           forKeyPath:@"titleColor"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    //use KVO to monitor changes to title, this is necessary to keep backing of title,
    //set to nil and then set the title of our titleView
    
    [self addObserver:self
           forKeyPath:@"title"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld
              context:NULL];
    
    _observersRegistered = true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerObservers];
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

//keep track of cells being focused so we can change the contents of the DetailView

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [self focusedCell:(SettingsTableViewCell*)context.nextFocusedView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.items.count;
}

- (void)focusedCell:(SettingsTableViewCell *)focusedCell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:focusedCell];

    MetaDataAsset *currentAsset = self.items[indexPath.row];

    if (currentAsset.imagePath.length == 0)
    {
        if (self.defaultImageName.length > 0)
        {
            currentAsset.imagePath = self.defaultImageName;
        }
    }
    
    self.detailView.previewView.imageView.image = [UIImage imageNamed:currentAsset.imagePath];
    
    [self.detailView.previewView updateAsset:currentAsset];

    if (![currentAsset.imagePath containsString:@"http"] )
    {
        self.detailView.previewView.imageView.image = [UIImage imageNamed:currentAsset.imagePath];
    } else {
        
        NSLog(@"imagePath: %@", currentAsset.imagePath);
        
        self.detailView.previewView.imageView.image = [UIImage imageNamed:self.defaultImageName];
        UIImage *currentImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:currentAsset.imagePath];
        if (currentImage == nil)
        {
            SDWebImageManager *shared = [SDWebImageManager sharedManager];
            [shared downloadImageWithURL:[NSURL URLWithString:currentAsset.imagePath] options:SDWebImageAllowInvalidSSLCertificates progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if (error == nil)
                {
                    [[SDImageCache sharedImageCache] storeImage:image forKey:currentAsset.imagePath];
                    self.detailView.previewView.imageView.image = image;
                }
                //
            }];
        } else {
            self.detailView.previewView.imageView.image = currentImage;
        }
       /*
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
            @autoreleasepool {
                
                NSData *scienceData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]];
                UIImage *theImage = [UIImage imageWithData:scienceData];
           
           
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    [UIView animateWithDuration:1.0 animations:^{
                        
                        self.detailView.previewView.imageView.image = theImage;
                        
                    }];
                    
                    
                });
                
            }
            
            
        });
        */

        //[self.detailView.previewView.imageView sd_setImageWithURL:[NSURL URLWithString:imagePath]];
        //[self.detailView.previewView.imageView sd_setImageWithURL:[NSURL URLWithString:imagePath] placeholderImage:[UIImage imageNamed:imageName] options:SDWebImageAllowInvalidSSLCertificates];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MetaDataAsset *currentAsset = self.items[indexPath.row];
    NSString *currentDetail = currentAsset.detail;
    if (currentDetail.length > 0)
    {
        if ([currentAsset detailOptions].count > 0)
        {
            NSInteger currentIndex = [[currentAsset detailOptions] indexOfObject:currentDetail];
            currentIndex++;
            if ([currentAsset detailOptions].count > currentIndex)
            {
                NSString *newDetail = currentAsset.detailOptions[currentIndex];
                currentAsset.detail = newDetail;
                [self.tableView reloadData];
            } else {
                NSString *newDetail = currentAsset.detailOptions[0];
                currentAsset.detail = newDetail;
                [self.tableView reloadData];
            }
        }

    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    // Configure the cell...
    MetaDataAsset *currentAsset = self.items[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = currentAsset.name;
    cell.detailTextLabel.text = currentAsset.detail;
    if (self.view.backgroundColor == [UIColor blackColor])
    {
        cell.textLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    /*
     
     This is a terrible hack, but without doing this I couldn't figure out a way to make the built in accessory
     types to play nicely with the unfocused background colors to mimic the settings table view style
     
     it also creates an issue where the size of the cell when focused is all out of whack. not really
     sure how to accomodate that...
     
     */
    
    UIView *accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 66)];
    accessoryView.opaque = false;
    accessoryView.backgroundColor = [UIColor clearColor];
    UIImageView *accessoryImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 16.5, 20, 33)];
    //UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 16.5, 20, 33)];
    accessoryImage.backgroundColor = [UIColor clearColor];
    accessoryImage.image = [UIImage imageNamed:@"image"];
    //[accessoryButton setImage:[UIImage imageNamed:@"image"] forState:UIControlStateNormal];
    [accessoryView addSubview:accessoryImage];
    cell.accessoryView = accessoryView;
    // cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    //cell.printRecursiveDescription;
    return cell;
}

@end
