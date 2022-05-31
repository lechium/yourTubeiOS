//
//  KBYTGridChannelViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/26/17.
//
//

#import "KBYTGridChannelViewController.h"
#import "UIImageView+WebCache.h"

static NSString * const standardReuseIdentifier = @"StandardCell";

@interface KBYTGridChannelViewController ()
{
    KBYTChannelHeaderView *__headerView;
}
@end

@implementation KBYTGridChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshDataWithProgress:YES];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithChannelID:(NSString *)channelID
{
    self = [super init];
    _channelID = channelID;
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)initialSetup
{
    NSInteger i = 0;
    self.totalHeight = 0;
    self.featuredHeightConstraint.constant = 200;
    for (i = 0; i < [_backingSectionLabels count]; i++)
    {
        UILongPressGestureRecognizer *longpress
        = [[UILongPressGestureRecognizer alloc]
           initWithTarget:self action:@selector(handleLongpressMethod:)];
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeMethod:)];
        longpress.minimumPressDuration = .5; //seconds
        longpress.delegate = self;
        longpress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
        //it is INCREDIBLY important to create a new CollectionViewLayout individually for EVERY collection view
        //if you re-use them you will have crashes galore
        CollectionViewLayout *layoutTwo = [CollectionViewLayout new];
        layoutTwo.sectionHeadersPinToVisibleBounds = true;
        layoutTwo.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layoutTwo.minimumInteritemSpacing = 10;
        layoutTwo.minimumLineSpacing = 50;
        layoutTwo.itemSize = CGSizeMake(320, 340);
        layoutTwo.sectionInset = UIEdgeInsetsMake(35, 0, 20, 0);
        layoutTwo.headerReferenceSize = CGSizeMake(100, 150);
        UICollectionView *collectionView  = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layoutTwo];
        [collectionView addGestureRecognizer:longpress];
        [collectionView addGestureRecognizer:swipeGesture];
        //collectionView.scrollEnabled = true;
        collectionView.tag = 60 + i;
        collectionView.translatesAutoresizingMaskIntoConstraints = false;
        [collectionView registerNib:[UINib nibWithNibName:@"YTTVStandardCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:standardReuseIdentifier];
        [collectionView registerClass:[TYBaseGridCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
        [collectionView setDelegate:self];
        [collectionView setDataSource:self];
        
        //add the view before setting constraints
        [self.scrollView addSubview:collectionView];
        
        
        if (i == 0) //first one
        {
            //pin to the top collection view just for the first one
            [collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.featuredVideosCollectionView withOffset:30];
            //[collectionView setBackgroundColor:[UIColor redColor]];
        } else {
            
            //find the previous view using our tags to pin to -80 on the previous view
            //-80 because we make the views bigger than they need to be because of weird header sizing stuff
            UIView *previousView = [self.view viewWithTag:collectionView.tag-1];
            [collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousView withOffset:-80];
            
        }
        
        //if its not a big negative value their are inset way too far
        [collectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.scrollView withOffset:-50];
        [collectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.scrollView withOffset:0];
        
        //add the total height of a table view to the overall height so we can set the contentView height when
        //necessary
        self.totalHeight+=520;
        
        [collectionView autoSetDimension:ALDimensionHeight toSize:520];
        
        /*
         if (i == [_backingSectionLabels count]-1)
         {
         if ([[KBYourTube sharedInstance] userDetails][@"channels"] != nil)
         {
         //may need to adjust offset of header title cuz channel pics are bigger
         }
         
         }
         */
    }
}

- (void)refreshDataWithProgress:(BOOL)progress
{
    if (progress == true){
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    }
    
    [[KBYourTube sharedInstance] getChannelVideosAlt:self.channelID continuation:nil completionBlock:^(KBYTChannel *channel) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIImage *banner = [UIImage imageNamed:@"Banner"];
            NSURL *imageURL =  [NSURL URLWithString:channel.banner];
            [self.headerview.bannerImageView sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
            self.headerview.subscriberLabel.text = channel.subscribers;
            self.headerview.authorLabel.text = channel.title;
            _backingSectionLabels = [NSMutableArray new];
            __block NSMutableDictionary *plDict = [NSMutableDictionary new];
            [[channel sections] enumerateObjectsUsingBlock:^(KBYTSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [_backingSectionLabels addObject:obj.title];
                plDict[obj.title] = obj.content;
            }];
            self.playlistDictionary = plDict;
            if (progress == true){
                [SVProgressHUD dismiss];
                [self initialSetup];
                
            }
        });
    } failureBlock:^(NSString *error) {
        
    }];
    return;
    //get the user details to populate these views with
    [[KBYourTube sharedInstance] getOrganizedChannelData:self.channelID completionBlock:^(NSDictionary *searchDetails) {
        //
        UIImage *banner = [UIImage imageNamed:@"Banner"];
        NSURL *imageURL = [NSURL URLWithString:searchDetails[@"banner"]];
        [self.headerview.bannerImageView sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
        self.headerview.subscriberLabel.text = searchDetails[@"subscribers"];
        self.headerview.authorLabel.text = searchDetails[@"name"];
        self.playlistDictionary = searchDetails;
        [self.headerview.subscriberLabel shadowify];
        [self.headerview.authorLabel shadowify];
        _backingSectionLabels = [NSMutableArray new];
        [_backingSectionLabels addObjectsFromArray:searchDetails[@"sections"]];
        
        DLog(@"bsl: %@", _backingSectionLabels);
        
        if (progress == true){
            [SVProgressHUD dismiss];
            [self initialSetup];
        }
        
        /*
         
         banner = "https://yt3.ggpht.com/xL-ZdgLMLqbeN9G5JW1HVLz7UMlHg_wHxGwZynC8Yh02XeiGbgyImUmqg3F2PvqsHUUUQJ0a=w1060-fcrop64=1,00005a57ffffa5a8-nd-c0xffffffff-rj-k-no";
         channelID = UC1vTH0ByVIcIOB83FbvHP7Q;
         description = "Anti-neocons videos basically.";
         keywords = "Ryan Dawson";
         name = "Ryan Dawson";
         sections =     (
         "What to watch next",
         "Popular uploads",
         Uploads,
         911
         );
         subscribers = "28,691 subscribers";
         thumbnail = "https://yt3.ggpht.com/-d8ZQDAP-yS0/AAAAAAAAAAI/AAAAAAAAAAA/9VvIT5rmU3A/s100-c-k-no-mo-rj-c0xffffff/photo.jpg";
         
         
         */
        
        [super reloadCollectionViews];
        
        
    } failureBlock:^(NSString *error) {
        //
    }];
}

- (void)viewDidLayoutSubviews
{
    [[self scrollView] setContentSize:CGSizeMake(1920, self.totalHeight)];
    
    // [self.view printRecursiveDescription];
    
}

- (NSArray *)arrayForCollectionView:(UICollectionView *)theView;
{
    NSInteger section = theView.tag - 60;
    NSArray *theArray = self.playlistDictionary[[self titleForSection:section]];
    return theArray;
}

- (KBYTChannelHeaderView *)headerview
{
    if (__headerView != nil) return __headerView;
    
    __headerView = [[KBYTChannelHeaderView alloc] initForAutoLayout];
    return __headerView;
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
