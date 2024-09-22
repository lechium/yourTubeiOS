//
//  TYHomeViewController.h
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/15/16.
//
//

#import "TYBaseGridViewController.h"

@interface TYHomeViewController : TYBaseGridViewController

@property (nonatomic, strong) NSArray *channelIDs;


- (id)initWithData:(NSDictionary *)data;
@end
