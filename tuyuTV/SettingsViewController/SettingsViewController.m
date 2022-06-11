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
#import "AppDelegate.h"
//#import "UIViewController+Additions.h"
#import "UIView+RecursiveFind.h"
//#import "NSObject+Additions.h"


@interface SFAirDropReceiverViewController: UIViewController
- (void)startAdvertising;
-(void)stopAdvertising;

-(void)setOverriddenInstructionsText:(NSString *)arg1 ;
@end;

@interface SFAirDropSharingViewControllerTV : UIViewController
-(id)initWithSharingItems:(id)arg1;
-(void)setCompletionHandler:(void (^)(NSError *error))arg1;
@end

@implementation SettingsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    unfocusedBackgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.accessoryView.backgroundColor = unfocusedBackgroundColor;
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
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

- (id)initForAutoLayout {
    self = [super initForAutoLayout];
    [self addSubview:self.previewView];
    //[self addSubview:self.imageView];
    return self;
}

- (void)updateConstraints{
    [self.previewView autoCenterInSuperview];
    [super updateConstraints];
}

- (void)updateMetaColor {
    UIColor *newColor = [UIColor blackColor];
    if ([self darkMode]) {
        newColor = [UIColor whiteColor];
    }
    for (MetadataLineView *lineView in self.previewView.linesView.subviews) {
        
        NSLog(@"lineView: %@", lineView);
        if ([lineView isKindOfClass:[MetadataLineView class]]) {
            [lineView.valueLayer setTextColor:newColor];
        }
    }
    [self.previewView.titleLabel setTextColor:newColor];
    [self.previewView.descriptionLabel setTextColor:newColor];
}

#pragma mark •• bootstrap data, change here for base data layout.
- (MetadataPreviewView *)previewView {
    if (!_previewView) {
        //NOTE: this is a bit of a hack im not sure why its necessary right now, apparently even a blank imagePath prevents
        //layout issues.
        _previewView = [[MetadataPreviewView alloc] initWithMetadata:@{@"imagePath": @""}];
        //_previewView.topOffset = self.metaTopOffset;
    }
    return _previewView;
}

- (UIImageView *)imageView {
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

- (void)performLongPressActionForSelectedRow {
    
}

- (void)loadView {
    self.view = [UIView new];
    self.topOffset = DEFAULT_TABLE_OFFSET;
    [self.view addSubview:self.detailView];
    [self.view addSubview:self.tableWrapper];
    [self.view addSubview:self.titleView];
    self.titleView.alpha = 0;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [self.tableView addGestureRecognizer:longPress];
    //self.title = @"Settings";
    [self.view setNeedsUpdateConstraints]; // bootstrap Auto Layout
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateBegan) {
    }
    else if ( gesture.state == UIGestureRecognizerStateEnded) {
        //NSLog(@"long press on cell: %@", gesture.view);
        [self performLongPressActionForSelectedRow];
    }
}

- (void)updateViewConstraints {
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
        [self.tableView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.tableWrapper withOffset:self.topOffset];
        [self.tableView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:50];
        
        //set up our title view
        [self.titleView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:56];
        [self.titleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        self.didSetupConstraints = YES;
    }
    [super updateViewConstraints];
}

- (void)viewWillDisappear:(BOOL)animated {
    @try {
        [self.view removeObserver:self forKeyPath:@"backgroundColor" context:NULL];
        [self removeObserver:self forKeyPath:@"titleColor" context:NULL];
        [self removeObserver:self forKeyPath:@"title" context:NULL];
    }
    @catch ( NSException *e ) {
          TLog(@"exception: %@", e);
    }
   
    _observersRegistered = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //self.titleView.text = _backingTitle;
    [self registerObservers];
    
    //[[self tableView]reloadData];
    // DLog(@"insets : %i", self.view.translatesAutoresizingMaskIntoConstraints);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.detailView updateMetaColor];
    // NSString *recursiveDesc = [self.view performSelector:@selector(recursiveDescription)];
    // NSLog(@"%@", recursiveDesc);
    
}

//its necessary to create a title view in case you are the first view inside a navigation controller
//which doesnt show a title view for the root controller iirc
- (UILabel *)titleView {
    if (!_titleView) {
        _titleView = [UILabel newAutoLayoutView];
        _titleView.font = [UIFont fontWithName:@".SFUIDisplay-Medium" size:57.00];
        _titleView.textColor = [UIColor grayColor];
    }
    return _titleView;
}

- (UIView *)tableWrapper; {
    if (!_tableWrapper) {
        _tableWrapper = [UIView newAutoLayoutView];
        _tableWrapper.autoresizesSubviews = true;
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        [_tableView configureForAutoLayout];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        [self.tableView registerClass:[SettingsTableViewCell class] forCellReuseIdentifier:@"SettingsCell"];
        _tableView.backgroundColor = self.view.backgroundColor;
        [_tableWrapper addSubview:_tableView];
        _tableWrapper.backgroundColor = self.view.backgroundColor;
    }
    return _tableWrapper;
}

- (UIView *)detailView {
    if (!_detailView) {
        _detailView = [[DetailView alloc] initForAutoLayout];
        _detailView.backgroundColor = self.view.backgroundColor;
    }
    return _detailView;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    id newValue = change[@"new"];
    
    //a bit of a hack to hide the navigationItem title view when title is set
    //and to use our own titleView that can have different colors
    if ([keyPath isEqualToString:@"title"]) {
        if (newValue != [NSNull null]) {
            if ([newValue length] > 0) {
                //keep a backup copy of the title
                _backingTitle = newValue;
                self.titleView.text = newValue;
                //self.title = @"";
            }
        }
    }
    //change subviews to have the same background color
    if ([keyPath isEqualToString:@"backgroundColor"]) {
        self.detailView.backgroundColor = newValue;
        self.tableWrapper.backgroundColor = newValue;
        self.tableView.backgroundColor = newValue;
        [self.detailView updateMetaColor];
    }
    
    //change titleView to a different text color
    
    if ([keyPath isEqualToString:@"titleColor"]) {
        self.titleView.textColor = newValue;
    }
    
}

- (void)registerObservers {
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
    self.defaultImageName = @"YTPlaceholder";
    //self.tableView.remembersLastFocusedIndexPath = true;
    [self registerObservers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_extraItems.count > 0) {
        return 2;
    }
    return 1;
}

//keep track of cells being focused so we can change the contents of the DetailView

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [self focusedCell:(SettingsTableViewCell*)context.nextFocusedView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0){
        return self.items.count;
    } else if (section == 1) {
        return self.extraItems.count;
    }
    return 0;
}

- (void)focusedCell:(SettingsTableViewCell *)focusedCell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:focusedCell];
    self.focusedIndexPath = indexPath;
    MetaDataAsset *currentAsset = self.items[indexPath.row];
    //NSLog(@"currentAsset image: %@", currentAsset.imagePath);
    if (currentAsset.imagePath.length == 0) {
        if (self.defaultImageName.length > 0) {
            currentAsset.imagePath = self.defaultImageName;
        }
    }
    self.detailView.previewView.imageView.image = [UIImage imageNamed:currentAsset.imagePath];
    [self.detailView.previewView updateAsset:currentAsset];
}

- (nullable NSIndexPath *)indexPathForPreferredFocusedViewInTableView:(UITableView *)tableView {
    
    if (self.savedIndexPath != nil) {
        return self.savedIndexPath;
    }
    return self.focusedIndexPath;
}

- (void)safeReloadData {
    
    [[self tableView]reloadData];
    self.savedIndexPath = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.savedIndexPath = indexPath;
    MetaDataAsset *currentAsset = nil;
    if (indexPath.row == 0){
        currentAsset = self.items[indexPath.row];
    } else {
        currentAsset = self.extraItems[indexPath.row];
    }
    SEL assetSelector = [currentAsset ourSelector];
    
    if ([self respondsToSelector:assetSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        //-Warc-performSelector-leaks
        [self performSelector:assetSelector];
#pragma clang diagnostic pop
    } else {
        TLog(@"%@ %@ doesnt respond to selector: %@", self, currentAsset, currentAsset.selectorName);
    }
    
    
    NSString *currentDetail = currentAsset.detail;
    if (currentDetail.length > 0) {
        if ([currentAsset detailOptions].count > 0) {
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
    
    MetaDataAsset *currentAsset = nil;
    if (indexPath.section == 1) {
        TLog(@"extra items instead!");
        currentAsset = self.extraItems[indexPath.row];
    } else {
        currentAsset = self.items[indexPath.row];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = currentAsset.name;
    cell.detailTextLabel.text = currentAsset.detail;
    
    if (currentAsset.accessory){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

@end
