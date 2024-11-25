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
#import "AppDelegate.h"
#import "TYAuthUserManager.h"
#import "AuthViewController.h"
#import "TYManageFeaturedViewController.h"

@implementation TYSettingsViewController

- (BOOL)signedIn {
    return [[TYAuthUserManager sharedInstance] checkAndSetCredential];//[[KBYourTube sharedInstance] isSignedIn];
}

+ (id)settingsView {
    TYSettingsViewController *svc = [TYSettingsViewController new];
    NSDictionary *mainMenuItem = nil;
    svc.view.backgroundColor = [UIColor blackColor];
    
    
    if ([svc signedIn] == true) {
        mainMenuItem = @{@"name": @"Sign Out", @"imagePath": @"YTPlaceholder", @"detail": @"", @"detailOptions": @[],  @"description": @"Sign out of your YouTube account."};
    } else {
        mainMenuItem = @{@"name": @"Sign In", @"imagePath": @"YTPlaceholder", @"detail": @"", @"detailOptions": @[], @"description": @"Sign in to your YouTube account."};
    }
    
    NSString *filterType = [[KBYourTube sharedUserDefaults] valueForKey:@"filterType"];
    if (!filterType){
        filterType = @"All";
    }
    
    
    MetaDataAsset *asset = [[MetaDataAsset alloc] initWithDictionary:mainMenuItem];
    MetaDataAsset *manageFeaturedChannels = [MetaDataAsset new];
    manageFeaturedChannels.name = @"Manage Featured Channels";
    manageFeaturedChannels.imagePath = @"YTPlaceholder.png";
    manageFeaturedChannels.assetDescription = @"Manage the channels listed in the tuyu home view";
    
    MetaDataAsset *forceHomeReload = [MetaDataAsset new];
    forceHomeReload.name = @"Force Home Reload";
    forceHomeReload.imagePath = @"YTPlaceholder.png";
    forceHomeReload.assetDescription = @"Force the tuyu home view to reload its data.";
    
    MetaDataAsset *resetCacheFiles = [MetaDataAsset new];
    resetCacheFiles.name = @"Reset Cache Files";
    resetCacheFiles.imagePath = @"YTPlaceholder.png";
    resetCacheFiles.assetDescription = @"Delete all existing cache files, this will reset the Home view channels to default settings.";
    /*
    NSDictionary *searchSettings = @{@"name": @"Search Filter", @"imagePath": @"YTPlaceholder.png", @"detail": filterType, @"detailOptions": @[@"All", @"Playlists", @"Channels"],  @"description": @"Filter what results come back from searches."};
    
    MetaDataAsset *search = [[MetaDataAsset alloc] initWithDictionary:searchSettings];
    
     */
    svc.items = @[asset, manageFeaturedChannels, forceHomeReload, resetCacheFiles];
    svc.title = @"settings";
    return svc;
    //UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:svc];
    //return navController;
}

- (void)viewWillAppear:(BOOL)animated {
    //DLog(@"dt: %@", [[KBYourTube sharedInstance] userDetails]);
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
            AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [ad updateForSignedIn];
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
    TLog(@"ip: %@", indexPath);
    if (indexPath.section == 1){
        [self doScience];
        return;
    }
    switch (indexPath.row) {
        case 0:
            [self toggleSignedIn];
            break;
            
        case 1:
            [self showManageChannelsView];
            //[super tableView:tableView didSelectRowAtIndexPath:indexPath];
            //[self handleToggle];
            break;
            
        case 2:
            [[KBYourTube sharedInstance] postHomeDataChangedNotification];
            break;
            
        case 3:
            [self showResetCacheAlert];
            break;
        default:
            break;
    }
}

- (void)resetCache {
    
    NSArray *contents = [FM contentsOfDirectoryAtPath:[self appSupportFolder] error:nil];
    [contents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *fp = [[self appSupportFolder] stringByAppendingPathComponent:obj];
        TLog(@"delete file: %@", obj);
        [FM removeItemAtPath:fp error:nil];
    }];
}

- (void)showResetCacheAlert {
    DLog(@"app support folder: %@", [self appSupportFolder]);
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Reset Cache"
                                          message: @"Are you sure you want to reset the cache?"
                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *yesAction            = [UIAlertAction
                                           actionWithTitle:@"Yes"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
        [self resetCache];
    }];
    [alertController addAction:yesAction];
    
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:noAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)doScience {
}

- (void)showManageChannelsView {
    NSArray <NSDictionary *>*savedSections = [NSArray arrayWithContentsOfFile:[[KBYourTube sharedInstance] newSectionsFile]];
    __block NSMutableArray *sections = [NSMutableArray new];
    [savedSections enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *assetDict = @{@"name": section[@"title"], @"imagePath": section[@"imagePath"],  @"uniqueID": section[@"uniqueId"], @"channel": section[@"uniqueId"]};
        NSString *objDesc = section[@"description"];
        if (objDesc != nil){
            assetDict = @{@"name": section[@"title"], @"imagePath": section[@"imagePath"],  @"uniqueID": section[@"uniqueId"], @"channel": section[@"uniqueId"], @"description": objDesc};
        }
        MetaDataAsset *asset = [[MetaDataAsset alloc] initWithDictionary:assetDict];
        [sections addObject:asset];
    }];
    TYManageFeaturedViewController *featuredVC = [[TYManageFeaturedViewController alloc] initWithNames:sections];
    featuredVC.defaultImageName = @"YTPlaceholder";
    NSDictionary *restoreDefaults = @{@"name": @"Restore default settings", @"imagePath": @"YTPlaceholder", @"detail": @"", @"detailOptions": @[],@"selectorName":@"restoreDefaultSettings",  @"description": @"This will reset the channel listing & settings in the Home (tuyu) section to its default settings."};
    MetaDataAsset *extraItemOne = [[MetaDataAsset alloc] initWithDictionary:restoreDefaults];
    extraItemOne.accessory = false;
    featuredVC.extraItems = @[extraItemOne];
    featuredVC.extraTitle = @"Maintenance";
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:featuredVC];
    [self presentViewController:navController animated:true completion:nil];
}

- (void)showManageChannelsViewold {
    
    NSDictionary *data =[NSDictionary dictionaryWithContentsOfFile:[[KBYourTube sharedInstance] sectionsFile]];
    __block NSMutableArray *sections = [NSMutableArray new];
    [data[@"sections"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDictionary *assetDict = @{@"name": obj[@"name"], @"imagePath": obj[@"imagePath"],  @"uniqueID": obj[@"channel"], @"channel": obj[@"channel"]};
        NSString *objDesc = obj[@"description"];
        if (objDesc != nil){
            assetDict = @{@"name": obj[@"name"], @"imagePath": obj[@"imagePath"],  @"uniqueID": obj[@"channel"], @"channel": obj[@"channel"], @"description": objDesc};
        }
        MetaDataAsset *asset = [[MetaDataAsset alloc] initWithDictionary:assetDict];
        [sections addObject:asset];
    }];
    TYManageFeaturedViewController *featuredVC = [[TYManageFeaturedViewController alloc] initWithNames:sections];
    featuredVC.defaultImageName = @"YTPlaceholder";
    NSDictionary *restoreDefaults = @{@"name": @"Restore default settings", @"imagePath": @"YTPlaceholder", @"detail": @"", @"detailOptions": @[],@"selectorName":@"restoreDefaultSettings",  @"description": @"This will reset the channel listing & settings in the Home (tuyu) section to its default settings."};
    MetaDataAsset *extraItemOne = [[MetaDataAsset alloc] initWithDictionary:restoreDefaults];
    extraItemOne.accessory = false;
    featuredVC.extraItems = @[extraItemOne];
    featuredVC.extraTitle = @"Maintenance";
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:featuredVC];
    [self presentViewController:navController animated:true completion:nil];
    
    //[self.navigationController pushViewController:featuredVC animated:true];
}

- (void)restoreDefaultSettings {
    LOG_CMD;
}

- (void)handleToggle {
    MetaDataAsset *asset = [self.items lastObject];
    NSString *detail = [asset detail];
    TLog(@"asset detail: %@", detail);
    [[KBYourTube sharedUserDefaults] setValue:detail forKey:@"filterType"];
}


@end
