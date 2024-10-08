//
//  KBYTGridChannelViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 2/26/17.
//
//

#import "KBYTGridChannelViewController.h"
#import "UIImageView+WebCache.h"
#import "TYTVHistoryManager.h"

static NSString * const standardReuseIdentifier = @"StandardCell";

@interface KBYTGridChannelViewController () {
    KBYTChannelHeaderView *__headerView;
}
@end

@implementation KBYTGridChannelViewController

- (void)viewDidLoad {
    LOG_CMD;
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithChannelID:(NSString *)channelID {
    self = [super init];
    _channelID = channelID;
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self refreshDataWithProgress:YES];
    [super viewWillAppear:animated];
}

- (void)initialSetup {
    NSInteger i = 0;
    self.totalHeight = 0;
    self.featuredHeightConstraint.constant = 0;
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
        UIView *existingView = [[self view] viewWithTag:60+i];
        if (existingView){
            [existingView removeFromSuperview]; //reset
        }
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

- (void)refreshDataWithProgress:(BOOL)progress {
    if (progress == true){
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    }
    TLog(@"channelID: -%@-", self.channelID);
    [[KBYourTube sharedInstance] getChannelVideosAlt:self.channelID continuation:nil completionBlock:^(KBYTChannel *channel) {
        
        TLog(@"channelData: %@", channel);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UIImage *banner = [UIImage imageNamed:@"Banner"];
            NSURL *imageURL =  [NSURL URLWithString:channel.banner];
            [self.headerview.bannerImageView sd_setImageWithURL:imageURL placeholderImage:banner options:SDWebImageAllowInvalidSSLCertificates];
            self.headerview.subscriberLabel.text = channel.subscribers;
            //self.headerview.subscriberLabel.text = channel.subscribers ? channel.subscribers : channel.subtitle;
            self.headerview.authorLabel.text = channel.title;
            _backingSectionLabels = [NSMutableArray new];
            __block NSMutableDictionary *plDict = [NSMutableDictionary new];
            [[channel sections] enumerateObjectsUsingBlock:^(KBYTSection * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.title == nil){
                    obj.title = [NSString stringWithFormat:@"%lu", idx];
                }
                [_backingSectionLabels addObject:obj.title];
                plDict[obj.title] = obj.content;
            }];
            self.playlistDictionary = plDict;
            if (progress == true){
                [SVProgressHUD dismiss];
                [[TYTVHistoryManager sharedInstance] addChannelToHistory:[channel dictionaryRepresentation]];
                [self initialSetup];
                
            }
        });
    } failureBlock:^(NSString *error) {
        
    }];
}

- (void)viewDidLayoutSubviews {
    [[self scrollView] setContentSize:CGSizeMake(1920, self.totalHeight)];
    
    // [self.view printRecursiveDescription];
    
}

- (NSArray *)arrayForCollectionView:(UICollectionView *)theView; {
    NSInteger section = theView.tag - 60;
    NSArray *theArray = self.playlistDictionary[[self titleForSection:section]];
    return theArray;
}

- (KBYTChannelHeaderView *)headerview {
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
