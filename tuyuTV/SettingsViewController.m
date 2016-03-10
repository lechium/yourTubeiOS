//
//  SettingsViewController.m
//
//  RZSplitViewController Created by Joe Goullaud on 8/6/12.

//  Renamed and modified by Kevin Bradley 3/10/16 to create an easier settings view controller for ATV4

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

#import <QuartzCore/QuartzCore.h>
#import "SettingsViewController.h"

@implementation SettingsTableViewCell

@synthesize viewBackgroundColor, selectionColor;

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.selectionColor == nil)
        self.selectionColor = [UIColor whiteColor];
    
    if (self.viewBackgroundColor == nil)
        self.viewBackgroundColor = self.contentView.backgroundColor;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [super didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
    if (context.nextFocusedView == self)
    {
        [coordinator addCoordinatedAnimations:^{
            // self.backgroundColor = [UIColor darkGrayColor];
            self.contentView.backgroundColor = self.selectionColor;
            
            //NSLog(@"superview: %@",  self.superview.superview.superview.superview.superview.superview);
        } completion:^{
            //
        }];
        
    } else {
        [coordinator addCoordinatedAnimations:^{
            //self.backgroundColor = [UIColor blackColor];
            self.contentView.backgroundColor = self.viewBackgroundColor;
        } completion:^{
            //
        }];
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end

@interface DetailViewController ()

@end

@implementation DetailViewController

@synthesize imageNames;

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect selfFrame = [self.view frame];
    selfFrame.size.width = selfFrame.size.width / 2;
    CGRect imageRect = CGRectMake((selfFrame.size.width - 512)/2, (selfFrame.size.height - 382)/2, 512, 382);
    self.imageView = [[UIImageView alloc] initWithFrame:imageRect];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    if (imageNames.count > 0)
    {
         UIImage *theImage = [UIImage imageNamed:imageNames[0]];
        [self.imageView setImage:theImage];
    }
    [[self view]addSubview:self.imageView];

}

- (void)selectedItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.imageNames.count)
    {
        UIImage *theImage = [UIImage imageNamed:imageNames[indexPath.row]];
        [self.imageView setImage:theImage];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.contentInset = UIEdgeInsetsMake(30, 0, 20, 0);
    //self.view.backgroundColor = [UIColor blackColor];
    [self.tableView registerClass:[SettingsTableViewCell class] forCellReuseIdentifier:@"Science"];
    //self.tableView.maskView = nil;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectedItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(selectedItemAtIndexPath:)])
    {
        [self.delegate selectedItemAtIndexPath:indexPath];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}


- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
    [self focusedCell:(SettingsTableViewCell*)context.nextFocusedView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.itemNames.count;
}

- (void)focusedCell:(SettingsTableViewCell *)focusedCell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:focusedCell];
    [self.delegate selectedItemAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.selectionDelegate respondsToSelector:@selector(itemSelectedAtIndexPath:)])
    {
        [self.selectionDelegate itemSelectedAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Science"forIndexPath:indexPath];
    
    // Configure the cell...
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = self.itemNames[indexPath.row];
    cell.viewBackgroundColor = self.view.backgroundColor;
    if (self.view.backgroundColor == [UIColor blackColor])
    {
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionColor = [UIColor darkGrayColor];
    }
    
    return cell;
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end



#define kRZSplitViewMasterIndex 0
#define kRZSplitViewDetailIndex 1

@interface SettingsViewController () <UINavigationControllerDelegate>

@property (strong, nonatomic, readwrite) UIBarButtonItem *collapseBarButton;
@property (nonatomic, assign) BOOL usingCustomMasterWidth;

- (void)initializeSplitViewController;

- (void)layoutViewControllers;
- (void)layoutViewsForCollapsed:(BOOL)collapsed animated:(BOOL)animated;

- (void)configureCollapseButton:(UIBarButtonItem*)collapseButton forCollapsed:(BOOL)collapsed;

- (void)collapseBarButtonTapped:(id)sender;

@end

//changed master width to default to half of the screen width
#define RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH 960.0f
#define RZSPLITVIEWCONTROLLER_DEFAULT_CORNER_RADIUS 4.0f
//got rid of the border
#define RZSPLITVIEWCONTROLLER_DEFAULT_BORDER_WIDTH 0.0f

@implementation SettingsViewController
@synthesize viewControllers = _viewControllers;
@synthesize delegate = _delegate;
@synthesize collapseBarButtonImage = _collapseBarButtonImage;
@synthesize expandBarButtonImage = _expandBarButtonImage;
@synthesize collapseBarButton = _collapseBarButton;
@synthesize collapsed = _collapsed;
@synthesize viewBorderColor = _viewBorderColor;
@synthesize viewBorderWidth = _viewBorderWidth;
@synthesize viewCornerRadius = _viewCornerRadius;
@synthesize itemNames, imageNames;



+ (id)settingsViewControllerWithTitle:(NSString *)theTitle backgroundColor:(UIColor *)bgColor withItemNames:(NSArray *)names withImages:(NSArray *)images
{
    SettingsViewController *splitViewController = [SettingsViewController new];
    splitViewController.view.backgroundColor = bgColor;
    splitViewController.itemNames = names;
    splitViewController.imageNames = images;
    splitViewController.view.backgroundColor = bgColor;
    SettingsTableViewController *masterTableViewController = [[SettingsTableViewController alloc] init];
    masterTableViewController.itemNames = names;
    masterTableViewController.selectionDelegate = splitViewController;
    DetailViewController *detailViewController = [[DetailViewController alloc] init];
    detailViewController.view.backgroundColor = bgColor;
    detailViewController.imageNames = images;
    masterTableViewController.view.backgroundColor = bgColor;
    masterTableViewController.delegate = detailViewController;
    [splitViewController setViewControllers:@[detailViewController,masterTableViewController]];
    splitViewController.title = theTitle;
    [splitViewController setTitle:theTitle];
    return splitViewController;
}

- (void)itemSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.selectionDelegate respondsToSelector:@selector(itemSelectedAtIndexPath:fromNavigationController:)])
    {
        [self.selectionDelegate itemSelectedAtIndexPath:indexPath fromNavigationController:self.navigationController];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.usingCustomMasterWidth = NO;
        [self initializeSplitViewController];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initializeSplitViewController];
}

- (void)setMasterWidth:(CGFloat)masterWidth
{
    self.usingCustomMasterWidth = YES;
    _masterWidth = masterWidth;
}

- (void)initializeSplitViewController
{
    self.viewCornerRadius = RZSPLITVIEWCONTROLLER_DEFAULT_CORNER_RADIUS;
    self.viewBorderWidth = RZSPLITVIEWCONTROLLER_DEFAULT_BORDER_WIDTH;
    self.viewBorderColor = self.view.backgroundColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //self.view.backgroundColor = [UIColor blackColor];
    [self layoutViewControllers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self layoutViewsForCollapsed:self.collapsed animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Property Accessor Overrides

- (UIViewController*)masterViewController
{
    return [self.viewControllers objectAtIndex:kRZSplitViewMasterIndex];
}

- (UIViewController*)detailViewController
{
    return [self.viewControllers objectAtIndex:kRZSplitViewDetailIndex];
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    NSAssert(2 == [viewControllers count], @"You must have exactly 2 view controllers in the array. This array has %lu.", (long)[viewControllers count]);
    
    [_viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController*)obj;
        
        [vc willMoveToParentViewController:nil];
        [vc.view removeFromSuperview];
        [vc removeFromParentViewController];
    }];
    
    _viewControllers = [viewControllers copy];
    
    [_viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *vc = (UIViewController*)obj;
        
        [self addChildViewController:vc];
        [vc didMoveToParentViewController:self];
    }];
    
    [self layoutViewControllers];
}

- (void)setCollapseBarButtonImage:(UIImage *)collapseBarButtonImage
{
    _collapseBarButtonImage = collapseBarButtonImage;
    
    if (!self.collapsed)
    {
        [_collapseBarButton setImage:_collapseBarButtonImage];
    }
}

- (void)setExpandBarButtonImage:(UIImage *)expandBarButtonImage
{
    _expandBarButtonImage = expandBarButtonImage;
    
    if (self.collapsed)
    {
        [_collapseBarButton setImage:_expandBarButtonImage];
    }
}

- (void)setDetailViewController:(UIViewController*)detailVC
{
    NSAssert(detailVC != nil, @"The detail view controller must not be nil");
    
    if (detailVC)
    {
        NSMutableArray* updatedViewControllers = [[self viewControllers] mutableCopy];
        [updatedViewControllers setObject:detailVC atIndexedSubscript:kRZSplitViewDetailIndex];
        [self setViewControllers:updatedViewControllers];
    }
}

- (void)setMasterViewController:(UIViewController*)masterVC
{
    NSAssert(masterVC != nil, @"The master view controller must not be nil");
    
    if (masterVC)
    {
        NSMutableArray* updatedViewControllers = [[self viewControllers] mutableCopy];
        [updatedViewControllers setObject:masterVC atIndexedSubscript:kRZSplitViewMasterIndex];
        [self setViewControllers:updatedViewControllers];
    }
}

- (UIBarButtonItem*)collapseBarButton
{
    if (nil == _collapseBarButton)
    {
        _collapseBarButton = [[UIBarButtonItem alloc] initWithTitle:(self.collapsed ? @">>" : @"<<") style:UIBarButtonItemStylePlain target:self action:@selector(collapseBarButtonTapped:)];
        
        [self configureCollapseButton:_collapseBarButton forCollapsed:self.collapsed];
    }
    
    return _collapseBarButton;
}

- (void)setCollapsed:(BOOL)collapsed
{
    [self setCollapsed:collapsed animated:NO];
}

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated
{
    if (collapsed == _collapsed)
    {
        return;
    }
    
    _collapsed = collapsed;
    
    [self layoutViewsForCollapsed:collapsed animated:animated];
}

#pragma mark - Private Property Accessor Overrides

#pragma mark - View Controller Layout

- (void)layoutViewControllers
{
    UIViewController *masterVC = [self.viewControllers objectAtIndex:kRZSplitViewMasterIndex];
    UIViewController *detailVC = [self.viewControllers objectAtIndex:kRZSplitViewDetailIndex];
    
    UIViewAutoresizing masterAutoResizing = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    UIViewAutoresizing detailAutoResizing = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    masterVC.view.contentMode = UIViewContentModeScaleToFill;
    masterVC.view.autoresizingMask = masterAutoResizing;
    masterVC.view.autoresizesSubviews = YES;
    //masterVC.view.clipsToBounds = YES;
    
    masterVC.view.layer.borderWidth = self.viewBorderWidth;
    masterVC.view.layer.borderColor = [self.viewBorderColor CGColor];
    masterVC.view.layer.cornerRadius = self.viewCornerRadius;
    
    detailVC.view.contentMode = UIViewContentModeScaleToFill;
    detailVC.view.autoresizingMask = detailAutoResizing;
    detailVC.view.autoresizesSubviews = YES;
    //detailVC.view.clipsToBounds = YES;
    
    detailVC.view.layer.borderWidth = self.viewBorderWidth;
    detailVC.view.layer.borderColor = [self.viewBorderColor CGColor];
    detailVC.view.layer.cornerRadius = self.viewCornerRadius;
    
    [self.view addSubview:masterVC.view];
    [self.view addSubview:detailVC.view];
    
    [self layoutViewsForCollapsed:self.collapsed animated:NO];
}

- (void)layoutViewsForCollapsed:(BOOL)collapsed animated:(BOOL)animated
{
    void (^layoutBlock)(void);
    void (^completionBlock)(BOOL finished);
    
    UIViewController *masterVC = [self.viewControllers objectAtIndex:0];
    UIViewController *detailVC = [self.viewControllers objectAtIndex:1];
    
    CGRect viewBounds = self.view.bounds;
    CGFloat masterWidth = self.usingCustomMasterWidth ? self.masterWidth : RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH;
    
    if (collapsed)
    {
        layoutBlock = ^(void){
            CGRect masterFrame = CGRectMake(-masterWidth, 0, masterWidth+1.0, viewBounds.size.height);
            CGRect detailFrame = CGRectMake(0, 0, viewBounds.size.width, viewBounds.size.height);
            
            masterVC.view.frame = masterFrame;
            detailVC.view.frame = detailFrame;
        };
        
        completionBlock = ^(BOOL finished){
            [masterVC.view removeFromSuperview];
        };
    }
    else
    {
        if (masterVC.view.superview != self.view)
        {
            [self.view addSubview:masterVC.view];
        }
        masterVC.view.frame = CGRectMake(-RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH, 0, RZSPLITVIEWCONTROLLER_DEFAULT_MASTER_WIDTH+1.0, viewBounds.size.height);
        
        
        masterVC.view.frame = CGRectMake(-masterWidth, 0, masterWidth+1.0, viewBounds.size.height);
        
        
        layoutBlock = ^(void){
            CGRect masterFrame = CGRectMake(0, 0, masterWidth+1.0, viewBounds.size.height);
            
            //made some changes here because the table view was too high, too wide and getting cut off.
            CGRect detailFrame = CGRectMake(masterWidth+30, 180, viewBounds.size.width - (masterWidth )-80, viewBounds.size.height - 180);
            
            masterVC.view.frame = masterFrame;
            detailVC.view.frame = detailFrame;
        };
        
        completionBlock = ^(BOOL finished){
            
        };
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionLayoutSubviews
                         animations:layoutBlock
                         completion:completionBlock];
    }
    else
    {
        layoutBlock();
        completionBlock(YES);
    }
}

- (void)configureCollapseButton:(UIBarButtonItem*)collapseButton forCollapsed:(BOOL)collapsed
{
    if (collapsed)
    {
        if (self.expandBarButtonImage)
        {
            [collapseButton setImage:self.expandBarButtonImage];
        }
        else if (self.collapseBarButtonImage)
        {
            [collapseButton setImage:self.collapseBarButtonImage];
        }
        else
        {
            [collapseButton setTitle:@">>"];
        }
    }
    else
    {
        if (self.collapseBarButtonImage)
        {
            [collapseButton setImage:self.collapseBarButtonImage];
        }
        else
        {
            [collapseButton setTitle:@"<<"];
        }
    }
}

#pragma mark - Action Methods

- (void)collapseBarButtonTapped:(id)sender
{
    BOOL collapsed = !self.collapsed;
    
    UIBarButtonItem *buttonItem = (UIBarButtonItem*)sender;
    
    [self configureCollapseButton:buttonItem forCollapsed:collapsed];
    
    [self setCollapsed:collapsed animated:YES];
}

@end


@implementation UIViewController (RZSplitViewController)

- (SettingsViewController*)rzSplitViewController
{
    if (self.parentViewController)
    {
        if ([self.parentViewController isKindOfClass:[SettingsViewController class]])
        {
            return (SettingsViewController*)self.parentViewController;
        }
        else
        {
            return [self.parentViewController rzSplitViewController];
        }
    }

    return nil;
}

@end
