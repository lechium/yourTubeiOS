//
//  TYBaseGridViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/7/16.
//
//

#import "TYBaseGridViewController.h"
#import "TYAuthUserManager.h"
#import "KBYTGridChannelViewController.h"
#import "YTTVPlaylistViewController.h"
/*
 
 Tag offsets are used for both the collection views and their header views to be able to query them easily
 
 when creating the dynamic collection views below the "featured" one each view is tagged with its actual
 index + its respective offset value (everything being 0 indexed this is extremely helpful)
 
 then [x viewWithTag:index+tagOffets or headerTagOffset] can be used to find each collection view or each header view
 
 
 
 */

static int tagOffset = 60;
static int headerTagOffset = 70;

@interface KBCollectionView: UICollectionView

@end

@implementation KBCollectionView

/*
 -(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
 {
 for(NSInteger i=0 ; i < self.numberOfSections; i++) {
 for (NSInteger j=0 ; j < [self numberOfItemsInSection:i]; j++) {
 NSIndexPath* indexPath = [NSIndexPath indexPathForItem:j inSection:i];
 [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
 }
 }
 }
 
 */

@end

@implementation TYBaseGridCollectionHeaderView

//yeh KVO or even custom getters/setters could work, but so does this ;-P

- (void)updateTopOffset:(CGFloat)offset {
    self.topOffset = offset;
    [self.topConstraint setConstant:-offset];
    [self layoutIfNeeded];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.title = [[UILabel alloc] initForAutoLayout];
        [self addSubview:self.title];
        self.topOffset = self.topOffset;
        self.topOffset = -40; //the negative value thing is probably unnessesary..
        //create the top constraint whose constant we re-adjust as ncessary
        self.topConstraint = [self.title autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-self.topOffset];
        //100 seems to be a good sweet spot
        [self.title autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:100];
        self.title.textColor = [UIColor lightTextColor];
        self.title.font = [UIFont systemFontOfSize:40];
        
    }
    return self;
}


@end


@interface TYBaseGridViewController () {
    //CGFloat _totalHeight; //keep track of the total height of the scrollViews content view based on collection views
    NSInteger _focusedCollectionView;
}

@property (nonatomic, strong) YTKBPlayerViewController *playerView;
@property (nonatomic, strong) KBYTQueuePlayer *player;


@end

static NSString * const featuredReuseIdentifier = @"FeaturedCell";
static NSString * const standardReuseIdentifier = @"StandardCell";

@implementation TYBaseGridViewController

- (id)initWithSections:(NSArray *)sections {
    self = [super init];
    self.sectionLabels = sections;
    _backingSectionLabels = [sections mutableCopy];
 
    return self;
}

/*
 
 The fundamental way this view works is there is a list of sectionLabels that we cycle through for
 every view below the featured view to figure out how many collection views to add
 
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupViews];
    self.view.backgroundColor = [UIColor blackColor];
  
    //initially set up the views based on section labels
   
    // Do any additional setup after loading the view.
}

//use the tag offset for collectionViews to cycle through and reload them based on section count

- (void)reloadCollectionViews {
    NSInteger i = 0;
    for (i = 0; i < [_backingSectionLabels count]; i++) {
        UICollectionView *collectionView = (UICollectionView*)[self.view viewWithTag:tagOffset+i];
        // NSLog(@"collectionView: %@", collectionView);
        if ([collectionView isKindOfClass:[UICollectionView class]]) {
            [collectionView reloadData];
        }
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    
    
}

- (void)swipeMethod:(UISwipeGestureRecognizer *)gestureRecognizer {
    
    NSLog(@"direction: %lu", (unsigned long)gestureRecognizer.direction);
    CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view];
    NSLog(@"location: %@", NSStringFromCGPoint(location));
}

- (KBYTChannelHeaderView *)headerview {
    return nil;
}

- (void)setupViews {
    self.scrollView = [[UIScrollView alloc] initForAutoLayout];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = false;
    [self.view addSubview:self.scrollView];
    KBYTChannelHeaderView *headerView = [self headerview];
    if (headerView != nil) {
        [self.view addSubview:headerView];
        //[headerView autoPinToTopLayoutGuideOfViewController:self withInset:0];
        [headerView autoPinEdgeToSuperviewMargin:ALEdgeTop];
        //[headerView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:40];
        [headerView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [headerView autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [headerView setupView];
        [headerView autoSetDimension:ALDimensionHeight toSize:175];
        [self.scrollView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:headerView];
        //[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:0];
    } else {
        
        [self.scrollView autoPinToTopLayoutGuideOfViewController:self withInset:0];
    }
    
    //left here for posterity, this is why they were not working, do NOT pin the size of a UIScrollView, just
    //its edges!!!
    
    //[self.scrollView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
    //[self.scrollView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    
    [self.scrollView autoPinToBottomLayoutGuideOfViewController:self withInset:0];
    self.scrollView.userInteractionEnabled = true;
    self.scrollView.scrollEnabled = true;
    self.scrollView.directionalLockEnabled = false;
    
    CollectionViewLayout *layout = [CollectionViewLayout new];
    layout.minimumInteritemSpacing = 50;
    layout.sectionHeadersPinToVisibleBounds = true;
    layout.minimumLineSpacing = 50;
    layout.itemSize = CGSizeMake(640, 480);
    layout.sectionInset = UIEdgeInsetsMake(-5, 0, 0, 0);
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeMethod:)];
    UILongPressGestureRecognizer *longpress
    = [[UILongPressGestureRecognizer alloc]
       initWithTarget:self action:@selector(handleLongpressMethod:)];
    longpress.minimumPressDuration = .5; //seconds
    longpress.delegate = self;
    longpress.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    //[self.collectionView addGestureRecognizer: longpress];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //layout.sectionInset = UIEdgeInsetsZero;
    self.featuredVideosCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    [self.featuredVideosCollectionView addGestureRecognizer:longpress];
    [self.featuredVideosCollectionView addGestureRecognizer:swipeGesture];
    self.featuredVideosCollectionView.tag = 666; //give it a tag other than 0 just in case
    self.featuredVideosCollectionView.translatesAutoresizingMaskIntoConstraints = false;
    [self.featuredVideosCollectionView registerNib:[UINib nibWithNibName:@"YTTVFeaturedCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:featuredReuseIdentifier];
    
    [self.featuredVideosCollectionView registerClass:[TYBaseGridCollectionHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [self.featuredVideosCollectionView setDelegate:self];
    [self.featuredVideosCollectionView setDataSource:self];
    [self.scrollView addSubview:self.featuredVideosCollectionView];
    
    [self.featuredVideosCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.scrollView withOffset:50];
    //   [self.featuredVideosCollectionView autoPinToTopLayoutGuideOfViewController:self withInset:50];
    
    [self.featuredVideosCollectionView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.scrollView withOffset:20];
    
    [self.featuredVideosCollectionView autoPinEdge:ALEdgeRight toEdge:ALEdgeRight ofView:self.scrollView withOffset:20];
    
    self.featuredHeightConstraint =  [self.featuredVideosCollectionView autoSetDimension:ALDimensionHeight toSize:480];
    
    [self.featuredVideosCollectionView autoSetDimension:ALDimensionWidth toSize:1920];
    
    
    //now that the 'featured' collectionView at the top is set up, create all the ones below.
    
    
    NSInteger i = 0;
    _totalHeight = 0;
    for (i = 0; i < [_backingSectionLabels count]; i++) {
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
        collectionView.tag = tagOffset + i;
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
        _totalHeight+=520;
        
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

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    return true;
}

-(void) handleLongpressMethod:(UILongPressGestureRecognizer *)gestureRecognizer {
    LOG_SELF;
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (![[KBYourTube sharedInstance] isSignedIn]) {
        return;
    }

    KBYTSearchResult *searchResult = [self searchResultFromFocusedCell];
    
    NSLog(@"searchResult: %@", searchResult);
    
    switch (searchResult.resultType) {
        case kYTSearchResultTypeVideo:
            
            [self showPlaylistAlertForSearchResult:searchResult];
            break;
            
        case kYTSearchResultTypeChannel:
            
            [self showChannelAlertForSearchResult:searchResult];
            break;
            
        case kYTSearchResultTypePlaylist:
            
            break;
            
        case kYTSearchResultTypeUnknown:
            
            break;
    }

}

- (void)promptForNewPlaylistForVideo:(KBYTSearchResult *)searchResult {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"New Playlist"
                                          message: @"Enter the name for your new playlist"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        
        textField.placeholder = @"Playlist Name";
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.keyboardAppearance = UIKeyboardAppearanceDark;
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    UIAlertAction *createPrivatePlaylist = [UIAlertAction
                                            actionWithTitle:@"Create private playlist"
                                            style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action)
                                            {
                                                NSString *playlistName = alertController.textFields[0].text;
                                                KBYTSearchResult *playlistItem =  [[TYAuthUserManager sharedInstance] createPlaylistWithTitle:playlistName andPrivacyStatus:@"private"];
                                                NSLog(@"playlist created?: %@", playlistItem);
                                                
                                                /*
                                                 
                                                 etag = "\"m2yskBQFythfE4irbTIeOgYYfBU/vehTBMq9cEbTEevEChu3q4csUTk\"";
                                                 id = PLnkIRfHufru8pR4pG2nDy2nQSHNxU3WFw;
                                                 kind = "youtube#playlist";
                                                 snippet =     {
                                                 channelId = "UC-d63ZntP27p917VXU-VFiA";
                                                 channelTitle = "Kevin Bradley";
                                                 description = "";
                                                 localized =         {
                                                 description = "";
                                                 title = "test 2";
                                                 };
                                                 publishedAt = "2017-08-15T16:19:38.000Z";
                                                 thumbnails =         {
                                                 default =             {
                                                 height = 90;
                                                 url = "http://s.ytimg.com/yts/img/no_thumbnail-vfl4t3-4R.jpg";
                                                 width = 120;
                                                 };
                                                 high =             {
                                                 height = 360;
                                                 url = "http://s.ytimg.com/yts/img/no_thumbnail-vfl4t3-4R.jpg";
                                                 width = 480;
                                                 };
                                                 medium =             {
                                                 height = 180;
                                                 url = "http://s.ytimg.com/yts/img/no_thumbnail-vfl4t3-4R.jpg";
                                                 width = 320;
                                                 };
                                                 };
                                                 title = "test 2";
                                                 };
                                                 status =     {
                                                 privacyStatus = public;
                                                 };
                                                 
                                                 */
                                                
                                                NSString *plID = playlistItem.videoId;
                                                
                                                [self addVideo:searchResult toPlaylist:plID];
                                            }];
    
    
    UIAlertAction *createPublicPlaylist = [UIAlertAction
                                           actionWithTitle:@"Create public playlist"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
                                               NSString *playlistName = alertController.textFields[0].text;
                                               KBYTSearchResult *playlistItem =  [[TYAuthUserManager sharedInstance] createPlaylistWithTitle:playlistName andPrivacyStatus:@"public"];
                                               if (playlistItem != nil)
                                               {
                                                   NSLog(@"playlist created?: %@", playlistItem);
                                                   NSString *plID = playlistItem.videoId;
                                                   
                                                   [self addVideo:searchResult toPlaylist:plID];
                                               }
                                           }];
    
    
    [alertController addAction:createPrivatePlaylist];
    [alertController addAction:createPublicPlaylist];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)addVideo:(KBYTSearchResult *)video toPlaylist:(NSString *)playlist {
    DLog(@"add video: %@ to playlistID: %@", video, playlist);
    [[TYAuthUserManager sharedInstance] addVideo:video.videoId toPlaylistWithID:playlist];
}

- (void)showPlaylistAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Video Options"
                                          message: @"Choose playlist to add video to"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    NSArray *playlistArray = [[TYAuthUserManager sharedInstance] playlists];
    
    
    __weak typeof(self) weakSelf = self;
    self.alertHandler = ^(UIAlertAction *action) {
        NSString *playlistID = nil;
        
        for (KBYTSearchResult *result in playlistArray)
        {
            if ([result.title isEqualToString:action.title])
            {
                playlistID = result.videoId;
            }
        }
        
        [weakSelf addVideo:result toPlaylist:playlistID];
    };
    
    for (KBYTSearchResult *result in playlistArray) {
        UIAlertAction *plAction = [UIAlertAction actionWithTitle:result.title style:UIAlertActionStyleDefault handler:self.alertHandler];
        [alertController addAction:plAction];
    }
    
    UIAlertAction *newPlAction = [UIAlertAction actionWithTitle:@"Create new playlist" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self promptForNewPlaylistForVideo:result];
        
    }];
    [alertController addAction:newPlAction];
    
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    
    
    
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
    
}

- (void)showChannelAlertForSearchResult:(KBYTSearchResult *)result {
    DLOG_SELF;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Channel Options"
                                          message: @"Subscribe to this channel?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Subscribe" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[TYAuthUserManager sharedInstance] subscribeToChannel:result.videoId];
        });
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                   }];
    [alertController addAction:yesAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableview = nil;
    NSString *theTitle = nil;
    if (collectionView == self.featuredVideosCollectionView) {
        theTitle = @"Your Videos"; //was trying to set top header, doesnt actually work.
    } else {
        
        //we are any other collection view below the top 'featured' one, get our section
        //title
        
        NSInteger viewTag = collectionView.tag - tagOffset;
        theTitle = _backingSectionLabels[viewTag];
    }
    
    if (kind == UICollectionElementKindSectionHeader) { //safety...
        TYBaseGridCollectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        headerView.title.text = theTitle;
        reusableview = headerView;
        //use this tag later to re-adjust the top offset when we need to
        //i dont like this, but it works
        reusableview.tag = (collectionView.tag - tagOffset)+ headerTagOffset;
    }
    
    return reusableview;
}

//use that _totalHeight value to let the scrollView know its content size

- (void)viewDidLayoutSubviews {
    [[self scrollView] setContentSize:CGSizeMake(1920, _totalHeight)];
    
    // [self.view printRecursiveDescription];
    
}

//this is where the header offset magic happens

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    //we always shift the previous views header back down just in case, if needed it will
    //be shifted back up in the focusedCell call below.
    [self previouslyFocusedCell:(YTTVStandardCollectionViewCell*)context.previouslyFocusedView];
    [self focusedCell:(YTTVStandardCollectionViewCell*)context.nextFocusedView];
    self.focusedCollectionCell = (UICollectionViewCell *)context.nextFocusedView;
}

- (void)previouslyFocusedCell:(YTTVStandardCollectionViewCell *)focusedCell {
    UICollectionView *cv = (UICollectionView*)[focusedCell superview];
    //if it isnt a collectionView or it IS the top collection view we dont do any adjustments
    if (![cv isKindOfClass:[UICollectionView class]] || cv == self.featuredVideosCollectionView ) {
        return;
    }
    NSInteger headerTag = (cv.tag - tagOffset) + headerTagOffset;
    TYBaseGridCollectionHeaderView *header = [cv viewWithTag:headerTag];
    [header updateTopOffset:-40]; //always shift it back up
     [header.title setTextColor:[UIColor lightTextColor]];
}

- (void)focusedCell:(YTTVStandardCollectionViewCell *)focusedCell {
    //the superview of a CollectionViewCell is its respective collectionView
    UICollectionView *cv = (UICollectionView*)[focusedCell superview];
    //if it isnt a collectionView or it IS the top collection view we dont do any adjustments
    if (![cv isKindOfClass:[UICollectionView class]] || cv == self.featuredVideosCollectionView ) {
        return;
    }
    
    //get the indexPath for the row to make sure its row 0 to shift upwards
    NSIndexPath *indexPath = [cv indexPathForCell:focusedCell];
    //get our headerTag by re-adjusting the offsets from the collectionView tag
    NSInteger headerTag = (cv.tag - tagOffset) + headerTagOffset;
    _focusedCollectionView = cv.tag;
    //actually get the header
    TYBaseGridCollectionHeaderView *header = [cv viewWithTag:headerTag];
    //always changed the focused headers text color to white
    [header.title setTextColor:[UIColor whiteColor]];
    //if we are the first object we want to shift the header up to prevent overlapping
    if (indexPath.row == 0) {
        [header updateTopOffset:-20];
        
    } else {
        [header updateTopOffset:-40];
    }
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = 0;
    if (collectionView == self.featuredVideosCollectionView) {
        count = self.featuredVideos.count;
        
    } else {
        return [[self arrayForCollectionView:collectionView] count];
    }
    
    return count;
}

/*
 
 if the collectionView is empty we want the header to be invisible, not super elegant, but it works :)
 
 setting the colors here AND in the focusedCell stuff is obviously a bit redudant, this was 
 done afterwards as a defensive measure to make sure they are updated to the proper color once
 we have content.
 
 */

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(8_0); {
    if ([self arrayForCollectionView:collectionView] == 0) {
        [[(TYBaseGridCollectionHeaderView *)view title] setTextColor:self.view.backgroundColor];
    } else {
        if (_focusedCollectionView == collectionView.tag)
        {
            [[(TYBaseGridCollectionHeaderView *)view title] setTextColor:[UIColor whiteColor]];
        } else {
            
            [[(TYBaseGridCollectionHeaderView *)view title] setTextColor:[UIColor lightTextColor]];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    //cell for the top featured section
    if (collectionView == self.featuredVideosCollectionView) {
        
        YTTVFeaturedCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:featuredReuseIdentifier forIndexPath:indexPath];
        if ([self.featuredVideos count] > 0)
        {
            KBYTSearchResult *currentItem = [self.featuredVideos objectAtIndex:indexPath.row];
            NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
            UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
            [cell.featuredImage sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
            cell.featuredTitle.text = currentItem.title;
            [cell.featuredTitle shadowify];
        } else {
            cell.featuredImage.image = [UIImage imageNamed:@"YTPlaceholder"];
        }
        
        return cell;
    } else { //cell for any of the collection views below the top one.
        YTTVStandardCollectionViewCell  *cell = [collectionView dequeueReusableCellWithReuseIdentifier:standardReuseIdentifier forIndexPath:indexPath];
        
        NSArray *detailsArray = [self arrayForCollectionView:collectionView];
        
        KBYTSearchResult *currentItem = [detailsArray objectAtIndex:indexPath.row];
        NSURL *imageURL = [NSURL URLWithString:currentItem.imagePath];
        UIImage *theImage = [UIImage imageNamed:@"YTPlaceholder"];
        [cell.image sd_setImageWithURL:imageURL placeholderImage:theImage options:SDWebImageAllowInvalidSSLCertificates];
        cell.title.text = currentItem.title;
        cell.durationLabel.text = currentItem.duration;
        return cell;
    }
    
}

- (void)showPlaylist:(NSString *)videoID named:(NSString *)name {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getPlaylistVideos:videoID completionBlock:^(KBYTPlaylist *playlist) {
        
        [SVProgressHUD dismiss];
        
        //NSString *nextHREF = searchDetails[@"loadMoreREF"];
        YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerForPlaylist:playlist backgroundColor:[UIColor blackColor]];
        //YTTVPlaylistViewController *playlistViewController = [YTTVPlaylistViewController playlistViewControllerWithTitle:name backgroundColor:[UIColor blackColor] withPlaylistItems:playlist.videos];
        //playlistViewController.loadMoreHREF = nextHREF;
        [self presentViewController:playlistViewController animated:YES completion:nil];
        // [[self.presentingViewController navigationController] pushViewController:playlistViewController animated:true];
        
    } failureBlock:^(NSString *error) {
        //RDCLAK5uy_n4g8XbXdlPTtik7Fwl4RU3Gij-63HBsmo
    }];
}

//used to show a channel instead if a channel was selected

- (void)showChannel:(KBYTSearchResult *)searchResult {
    
    KBYTGridChannelViewController *cv = [[KBYTGridChannelViewController alloc] initWithChannelID:searchResult.videoId];
    [self presentViewController:cv animated:true completion:nil];
}

//datasoure method that will return a title for the respective section

- (NSString *)titleForSection:(NSInteger)section {
    return [_backingSectionLabels objectAtIndex:section];
}

//datasource method to return the collection based on the view

- (UICollectionView *)collectionViewFromCell:(UICollectionViewCell *)cell {
    NSInteger sectionCount = [_backingSectionLabels count];
    UICollectionView *cv = nil;
    for (NSInteger i = 0; i < sectionCount; i++) {
        cv = [self.view viewWithTag:60 + i];
        if ([[cv subviews] containsObject:cell]){
            return cv;
        }
    }
    return nil;
}

- (NSArray *)arrayForCollectionView:(UICollectionView *)theView {
    KBYTChannel *channel = [self channelForCollectionView:theView];
    //TLog(@"channel: %@", channel);
    if ([channel isKindOfClass:KBYTChannel.class]){
        return channel.allSectionItems;
    } else if ([channel isKindOfClass:KBYTPlaylist.class]) {
        return [(KBYTPlaylist *)channel videos];
    } else {
        return (NSArray *)channel;
    }
}

- (KBYTChannel *)channelForCollectionView:(UICollectionView *)theView {
    NSInteger section = theView.tag - tagOffset;
    return self.playlistDictionary[[self titleForSection:section]];
}

- (KBYTSearchResult *)searchResultFromFocusedCell {
    if (self.focusedCollectionCell != nil) {
        UICollectionView *cv = (UICollectionView *)[self.focusedCollectionCell superview];
        NSIndexPath *indexPath = [cv indexPathForCell:self.focusedCollectionCell];
        
        if (cv == self.featuredVideosCollectionView) {
            KBYTSearchResult *currentItem = [self.featuredVideos objectAtIndex:indexPath.row];
            return currentItem;
        }
        
       
        NSArray *theArray = [self arrayForCollectionView:cv];
        //TLog(@"cv: %@ indexPath row: %lu arrayCount: %lu", cv, indexPath.row,theArray.count);
        if (indexPath.row > theArray.count){
            TLog(@"bail!!");
            return nil;
        }
        KBYTSearchResult *searchResult = [theArray objectAtIndex:indexPath.row];
        return searchResult;
    }
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == self.featuredVideosCollectionView) {
        //KBYTSearchResult *currentItem = [self.featuredVideos objectAtIndex:indexPath.row];
        KBYTSearchResult *selectedItem = [self.featuredVideos objectAtIndex:indexPath.row];
        //if its a channel then show a channel instead of trying to playback a playlist
        if (selectedItem.resultType == kYTSearchResultTypeChannel) {
            [self showChannel:selectedItem];
            return;
        } else if (selectedItem.resultType == kYTSearchResultTypePlaylist) {
            [self showPlaylist:selectedItem.videoId named:selectedItem.title];
            return;
        }
        NSArray *subarray = [self.featuredVideos subarrayWithRange:NSMakeRange(indexPath.row, self.featuredVideos.count - indexPath.row)];
        [self playAllSearchResults:subarray];
        //[self playFirstStreamForResult:currentItem];
    } else {
        
        //get our detail array based on collectionView
        NSArray *detailsArray = [self arrayForCollectionView:collectionView];
        KBYTSearchResult *selectedItem = [detailsArray objectAtIndex:indexPath.row];
        //if its a channel then show a channel instead of trying to playback a playlist
        if (selectedItem.resultType == kYTSearchResultTypeChannel) {
            [self showChannel:selectedItem];
            return;
        } else if (selectedItem.resultType == kYTSearchResultTypePlaylist) {
            [self showPlaylist:selectedItem.videoId named:selectedItem.title];
            return;
        }
        
        //create a subarray starting at the index selected of the respective playlist to play all of the tracks
        //in that range
        NSArray *subarray = [detailsArray subarrayWithRange:NSMakeRange(indexPath.row, detailsArray.count - indexPath.row)];
        [self playAllSearchResults:subarray];
    }
}

- (void)playAllSearchResults:(NSArray *)searchResults {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:@[[searchResults firstObject]] completionBlock:^(NSArray *videoArray) {
        
        [SVProgressHUD dismiss];
        self.playerView = [[YTKBPlayerViewController alloc] initWithFrame:self.view.frame usingStreamingMediaArray:searchResults];
        [self.playerView addObjectsToPlayerQueue:videoArray];
        [self presentViewController:self.playerView animated:YES completion:nil];
        [[self.playerView player] play];
        NSArray *subarray = [searchResults subarrayWithRange:NSMakeRange(1, searchResults.count-1)];
        
        NSDate *myStart = [NSDate date];
        [[KBYourTube sharedInstance] getVideoDetailsForSearchResults:subarray completionBlock:^(NSArray *videoArray) {
            
            //TLog(@"video details fetched in %@", [myStart timeStringFromCurrentDate]);
            //TLog(@"first object: %@", subarray.firstObject);
            [self.playerView addObjectsToPlayerQueue:videoArray];
            
        } failureBlock:^(NSString *error) {
            
            [SVProgressHUD dismiss];
            DLog(@"failed?");
            [self showFailureAlert:error];
        }];
        
        
    } failureBlock:^(NSString *error) {
        [SVProgressHUD dismiss];
         DLog(@"failed?");
        [self showFailureAlert:error];
    }];
}

- (void)showFailureAlert:(NSString *)error {
    UIAlertController *alertCon = [UIAlertController alertControllerWithTitle:@"An error occured" message:error preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"D'oh" style:UIAlertActionStyleCancel handler:nil];
    [alertCon addAction:okAction];
    [self presentViewController:alertCon animated:YES completion:nil];
    
}

- (void)playFirstStreamForResult:(KBYTSearchResult *)searchResult {
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    [[KBYourTube sharedInstance] getVideoDetailsForID:searchResult.videoId completionBlock:^(KBYTMedia *videoDetails) {
        
        [SVProgressHUD dismiss];
        //NSLog(@"videoDetails: %@", videoDetails);
        [[TYTVHistoryManager sharedInstance] addVideoToHistory:[videoDetails dictionaryRepresentation]];
        
        NSURL *playURL = [[videoDetails.streams firstObject] url];
        AVPlayerViewController *playerView = [[AVPlayerViewController alloc] init];
        AVPlayerItem *singleItem = [AVPlayerItem playerItemWithURL:playURL];
        
        playerView.player = [AVQueuePlayer playerWithPlayerItem:singleItem];
        [self presentViewController:playerView animated:YES completion:nil];
        [playerView.player play];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:singleItem];
        
    } failureBlock:^(NSString *error) {
        
        [SVProgressHUD dismiss];
        [self showFailureAlert:error];
        
    }];
    
}

- (void)itemDidFinishPlaying:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:n.object];
    [self dismissViewControllerAnimated:true completion:nil];
}


@end
