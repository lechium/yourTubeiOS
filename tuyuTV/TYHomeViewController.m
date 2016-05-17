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
    [self refreshData];
    
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshData];
}


- (void)refreshData
{
    [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
    [SVProgressHUD show];
    
    //get the user details to populate these views with
    [self fetchChannelDetailsWithCompletionBlock:^(NSDictionary *finishedDetails) {
        
        [SVProgressHUD dismiss];
        self.playlistDictionary = finishedDetails;
        [super reloadCollectionViews];
    }];
}


- (void)fetchChannelDetailsWithCompletionBlock:(void(^)(NSDictionary *finishedDetails))completionBlock
{
    NSMutableDictionary *channels = [NSMutableDictionary new];
    [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
        
        self.featuredVideos = searchDetails[@"results"];
        [[self featuredVideosCollectionView] reloadData];
        
        
    } failureBlock:^(NSString *error) {
        
    }];
    
    //NSArray *results = userDetails[@"results"];
    NSInteger channelCount = [self.sectionLabels count];
    
    //since blocks are being used to fetch the data need to keep track of indices so we know
    //when to call completionBlock
    
    __block NSInteger currentIndex = 0;
    for (NSString *result in self.channelIDs)
    {
        [[KBYourTube sharedInstance] getChannelVideos:result completionBlock:^(NSDictionary *searchDetails) {
            
            channels[searchDetails[@"name"]] = searchDetails[@"results"];
            currentIndex++;
            if (currentIndex == channelCount)
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
