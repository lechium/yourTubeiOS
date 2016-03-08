//
//  SignOutViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 3/8/16.
//
//

#import "SignOutViewController.h"
#import "KBYourTube+Categories.h"
#import "AppDelegate.h"

@interface SignOutViewController ()

@end

@implementation SignOutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    [self showSignOutAlert];
    // Do any additional setup after loading the view.
}

- (void)showSignOutAlert
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Sign Out"
                                          message: @"Are you sure you want to sign out?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction            = [UIAlertAction
                                           actionWithTitle:@"Yes"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
                                           
                                               [self signOut];
                                               
                                           }];
    [alertController addAction:yesAction];
    
    UIAlertAction *noAction         = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
       
        AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [ad.tabBar setSelectedIndex:2];
        
    }];
    [alertController addAction:noAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)signOut
{
    [self stringFromRequest:@"https://www.youtube.com/logout"];
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [ad updateForSignedOut];
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
