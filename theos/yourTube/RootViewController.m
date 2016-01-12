#import "RootViewController.h"

@implementation RootViewController
- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view.backgroundColor = [UIColor redColor];
    
    NSLog(@"view: %@", self.view);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
}

@end
