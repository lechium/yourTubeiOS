//
//  TYHomeViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//

#import "TYHomeViewController.h"

@interface TYHomeViewController ()

@end

@implementation TYHomeViewController

- (id)initWithSections:(NSArray *)sections andChannelIDs:(NSArray *)channelIds
{
    
    self = [super initWithSections:sections];
    self.channelIDs = channelIds;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshDataWithProgress:true];
    
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshDataWithProgress:false];
}


- (void)refreshDataWithProgress:(BOOL)progress
{
    if (progress == true)
    {
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    }
    //get the user details to populate these views with
    [self fetchChannelDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress == true)
            {      [SVProgressHUD dismiss]; }
            self.playlistDictionary = finishedDetails;
            [super reloadCollectionViews];
        });
        
    }];
}

//@"UCByOQJjav0CUDwxCk-jVNRQ"
- (void)fetchChannelDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock
{
    NSMutableDictionary *channels = [NSMutableDictionary new];
    [[KBYourTube sharedInstance] getChannelVideos:@"UCByOQJjav0CUDwxCk-jVNRQ" completionBlock:^(KBYTChannel *channel) {
        self.featuredVideos = channel.videos;
        [[self featuredVideosCollectionView] reloadData];
    } failureBlock:^(NSString *error) {
        
    }];
    /*
    [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
        
        self.featuredVideos = searchDetails[@"results"];
        [[self featuredVideosCollectionView] reloadData];
        
        
    } failureBlock:^(NSString *error) {
        
    }];*/
    //return;
    //NSArray *results = userDetails[@"results"];
    NSInteger channelCount = [self.sectionLabels count];
    
    //since blocks are being used to fetch the data need to keep track of indices so we know
    //when to call completionBlock
    
    __block NSInteger currentIndex = 0;
    for (NSString *result in self.channelIDs)
    {
        [[KBYourTube sharedInstance] getChannelVideosAlt:result completionBlock:^(KBYTChannel *searchDetails) {
            
            NSString *title = searchDetails.title ? searchDetails.title : self.sectionLabels[currentIndex];
            NSLog(@"[tuyu] searchDetails title: %@ details:%@", title, searchDetails);
            if (searchDetails.videos){
                channels[title] = searchDetails.videos;
            }
            currentIndex++;
            if (currentIndex >= channelCount)
            {
               completionBlock(channels);
            }
            //
        } failureBlock:^(NSString *error) {
            
            //
        }];
        
        
    }
    
    
    
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
