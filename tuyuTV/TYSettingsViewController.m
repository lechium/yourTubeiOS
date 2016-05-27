//
//  TYSettingsViewController.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 5/26/16.
//
//

#import "TYSettingsViewController.h"
#import "KBYourTube.h"
#import "KBYourTube+Categories.h"
#import "WebViewController.h"
#import "AppDelegate.h"
#import "TYAuthUserManager.h"

@implementation TYSettingsViewController

- (BOOL)signedIn
{
    return [[KBYourTube sharedInstance] isSignedIn];
}

+ (id)settingsView
{
  
    TYSettingsViewController *svc = [TYSettingsViewController new];
    NSDictionary *mainMenuItem = nil;
    svc.view.backgroundColor = [UIColor blackColor];
    if ([svc signedIn] == true)
    {
        mainMenuItem = @{@"name": @"Sign Out", @"imagePath": @"YTPlaceholder.png", @"detail": @"", @"detailOptions": @[],  @"description": @"Sign out of your YouTube account."};
    } else {
        mainMenuItem = @{@"name": @"Sign In", @"imagePath": @"YTPlaceholder.png", @"detail": @"", @"detailOptions": @[], @"description": @"Sign in to your YouTube account."};
    }
    MetaDataAsset *asset = [[MetaDataAsset alloc] initWithDictionary:mainMenuItem];
    svc.items = @[asset];
    svc.title = @"settings";
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:svc];
    return navController;
}

- (void)viewWillAppear:(BOOL)animated
{
    MetaDataAsset *theAsset = self.items[0];
    if ([self signedIn] == true)
    {
        theAsset.name = @"Sign Out";
        theAsset.assetDescription = @"Sign out of your YouTube account.";
    } else {
        theAsset.name = @"Sign In";
        theAsset.assetDescription = @"Sign in to your YouTube account.";
    }
    [self.tableView reloadData];
}

- (void)toggleSignedIn
{
    if ([self signedIn] == true)
    {
        [self showSignOutAlert];
    } else {
        WebViewController *wvc = [TYAuthUserManager OAuthWebViewController];
        [self.navigationController pushViewController:wvc animated:true];
    }
}

- (void)signOut
{
    [self stringFromRequest:@"https://www.youtube.com/logout"];
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [ad updateForSignedOut];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    LOG_SELF;
    switch (indexPath.row) {
        case 0:
            
            [self toggleSignedIn];
            
            
            break;
            
        default:
            break;
    }
}

@end
