//
//  ServiceProvider.m
//  tuyuShelf
//
//  Created by Kevin Bradley on 2/11/17.
//
//

#import "ServiceProvider.h"

@interface ServiceProvider ()


@property (nonatomic, strong) NSMutableArray *menuItems;
@end

@implementation ServiceProvider


- (instancetype)init {
    self = [super init];
    if (self) {
        //[self testGetYTScience];
        self.menuItems = [NSMutableArray new];
        [self testGetYTScience];
    }
    return self;
}

#pragma mark - TVTopShelfProvider protocol

- (TVTopShelfContentStyle)topShelfStyle {
    // Return desired Top Shelf style.
    return TVTopShelfContentStyleSectioned;
}

- (void)testGetYTScience
{
    
    [[KBYourTube sharedInstance] getFeaturedVideosWithCompletionBlock:^(NSDictionary *searchDetails) {
        
        //DLog(@"searchDeets: %@", searchDetails);
        self.menuItems = searchDetails[@"results"];
        [[NSNotificationCenter defaultCenter] postNotificationName:TVTopShelfItemsDidChangeNotification object:nil];
        
    } failureBlock:^(NSString *error) {
        
        DLog(@"error: %@", error);
    }];
}

/*

private func urlForIdentifier(identifier: String) -> NSURL {
    let components = NSURLComponents()
    components.scheme = "newsapp"
    components.queryItems = [NSURLQueryItem(name: "identifier",
                                            value: identifier)] return components.URL!
}*/

- (NSURL *)urlForIdentifier:(NSString*)identifier
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"tuyu://%@", identifier]];
}


- (NSArray *)topShelfItems {
    // Create an array of TVContentItems.
    
    if (self.menuItems.count == 0)
    {
        [self testGetYTScience];
    }
   // [self testGetYTScience];
    TVContentIdentifier *section = [[TVContentIdentifier alloc] initWithIdentifier:@"science" container:nil];
    TVContentItem * sectionItem = [[TVContentItem alloc] initWithContentIdentifier:section];
    sectionItem.title = @"Suggestions";
    
    __block NSMutableArray *finalItems = [NSMutableArray new];
    [self.menuItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        KBYTSearchResult *result = (KBYTSearchResult *)obj;
        TVContentIdentifier *cid = [[TVContentIdentifier alloc] initWithIdentifier:result.videoId container:nil];
        TVContentItem * ci = [[TVContentItem alloc] initWithContentIdentifier:cid];
        ci.title = result.title;
        ci.imageURL = [NSURL URLWithString:result.imagePath];
        ci.displayURL = [self urlForIdentifier:result.videoId];
        [finalItems addObject:ci];
        
    }];

    
    sectionItem.topShelfItems = finalItems;
    return @[sectionItem];
}

@end
