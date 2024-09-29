//
//  TYUserShelfViewController.m
//  tuyuTV
//
//  Created by js on 9/28/24.
//

#import "TYUserShelfViewController.h"

@interface TYUserShelfViewController ()

@end

@implementation TYUserShelfViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (NSString *)cacheFile {
    return [[self appSupportFolder] stringByAppendingPathComponent:@"newUserShelf.plist"];
}

@end
