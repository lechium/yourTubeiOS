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
#import "AuthViewController.h"

@implementation TYSettingsViewController

- (BOOL)signedIn {
    return [[TYAuthUserManager sharedInstance] checkAndSetCredential];//[[KBYourTube sharedInstance] isSignedIn];
}

+ (id)settingsView {
    TYSettingsViewController *svc = [TYSettingsViewController new];
    NSDictionary *mainMenuItem = nil;
    svc.view.backgroundColor = [UIColor blackColor];
    
    
    if ([svc signedIn] == true) {
        mainMenuItem = @{@"name": @"Sign Out", @"imagePath": @"YTPlaceholder.png", @"detail": @"", @"detailOptions": @[],  @"description": @"Sign out of your YouTube account."};
    } else {
        mainMenuItem = @{@"name": @"Sign In", @"imagePath": @"YTPlaceholder.png", @"detail": @"", @"detailOptions": @[], @"description": @"Sign in to your YouTube account."};
    }
    
    NSString *filterType = [UD valueForKey:@"filterType"];
    if (!filterType){
        filterType = @"All";
    }
    
    NSDictionary *searchSettings = @{@"name": @"Search Filter", @"imagePath": @"YTPlaceholder.png", @"detail": filterType, @"detailOptions": @[@"All", @"Playlists", @"Channels"],  @"description": @"Filter what results come back from searches."};
    
    MetaDataAsset *asset = [[MetaDataAsset alloc] initWithDictionary:mainMenuItem];
    MetaDataAsset *search = [[MetaDataAsset alloc] initWithDictionary:searchSettings];
    /*
    MetaDataAsset *updatePermissions = [MetaDataAsset new];
    updatePermissions.name = @"Update permissions";
    updatePermissions.imagePath = @"YTPlaceholder.png";
    updatePermissions.assetDescription = @"Update authentication permissions so it's possible to add videos to playlists and subscribe to channels";
     */
    svc.items = @[asset, search];
    svc.title = @"settings";
    return svc;
    //UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:svc];
    //return navController;
}

- (void)viewWillAppear:(BOOL)animated {
    DLog(@"dt: %@", [[KBYourTube sharedInstance] userDetails]);
    MetaDataAsset *theAsset = self.items[0];
    if ([self signedIn] == true) {
        NSString *ourProfileImage = [[KBYourTube sharedInstance]userDetails][@"profileImage"];
        if (ourProfileImage != nil) {
            theAsset.imagePath = ourProfileImage;
        }
        theAsset.name = @"Sign Out";
        theAsset.assetDescription = @"Sign out of your YouTube account.";
    } else {
        theAsset.name = @"Sign In";
        theAsset.assetDescription = @"Sign in to your YouTube account.";
    }
    [self.tableView reloadData];
}

- (void)toggleSignedIn {
    if ([self signedIn] == true) {
        [self showSignOutAlert];
    } else {
        [self storeAuth];
        //WebViewController *wvc = [TYAuthUserManager OAuthWebViewController];
        //[self.navigationController pushViewController:wvc animated:true];
    }
}

- (void)storeAuth {
    TYAuthUserManager *shared = [TYAuthUserManager sharedInstance];
    [shared startAuthAndGetUserCodeDetails:^(NSDictionary *deviceCodeDict) {
        AuthViewController *avc = [[AuthViewController alloc] initWithUserCodeDetails:deviceCodeDict];
        [self presentViewController:avc animated:true completion:nil];
    } completion:^(NSDictionary *tokenDict, NSError *error) {
        NSLog(@"inside here???");
        if ([[tokenDict allKeys] containsObject:@"access_token"]){
            NSLog(@"we good: %@", tokenDict );
            [self dismissViewControllerAnimated:true completion:nil];
        } else {
            NSLog(@"show error alert here");
            [self dismissViewControllerAnimated:true completion:nil];
        }
    }];
}
- (void)signOut {
    [self stringFromRequest:@"https://www.youtube.com/logout"];
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [ad updateForSignedOut];
    [[TYAuthUserManager sharedInstance] signOut];
}

- (void)showSignOutAlert {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Sign Out"
                                          message: @"Are you sure you want to sign out?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction            = [UIAlertAction
                                           actionWithTitle:@"Yes"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LOG_SELF;
    switch (indexPath.row) {
        case 0:
            [self toggleSignedIn];
            break;
            
        case 1:
            //[self updatePermissions];
            [super tableView:tableView didSelectRowAtIndexPath:indexPath];
            [self handleToggle];
            break;
        default:
            break;
    }
}

- (void)handleToggle {
    MetaDataAsset *asset = [self.items lastObject];
    NSString *detail = [asset detail];
    NSLog(@"[tuyu] asset detail: %@", detail);
    [UD setValue:detail forKey:@"filterType"];
}

- (void)updatePermissions {
    WebViewController *wvc = [TYAuthUserManager OAuthWebViewController];
    [self.navigationController pushViewController:wvc animated:true];
}

@end
