//
//  TYManageFeaturedViewController.m
//  tuyuTV
//
//  Created by kevinbradley on 6/9/22.
//

#import "TYManageFeaturedViewController.h"
#import "KBYourTube.h"
#import "KBYTGridChannelViewController.h"
#import "TYChannelShelfViewController.h"

@interface TYManageFeaturedViewController ()

@end

@implementation TYManageFeaturedViewController

- (id)initWithNames:(NSArray *)names {
    self = [super init];
    self.items = names;
    return self;
}

- (void)refreshData {
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
    self.items = sections;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self tableView] reloadData];
    });
}

- (void)refreshDataold {
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
    self.items = sections;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self tableView] reloadData];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editSettings:)];
    // Do any additional setup after loading the view.
}

- (void)showRestoreDefaultWarningAlert {
    NSString *messageString = [NSString stringWithFormat:@"Are you sure you want to reset to the default settings? This cannot be undone."];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Reset to Defaults" message:messageString preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self restoreDefaultSettings];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    
    [ac addAction: cancel];
    [ac addAction:action];
    [self presentViewController:ac animated:TRUE completion:nil];
}

- (void)restoreDefaultSettings {
    [[KBYourTube sharedInstance] resetHomeScreenToDefaults];
    [self refreshData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self showRestoreDefaultWarningAlert];
    } else {
        MetaDataAsset *searchResult = self.items[indexPath.row];
        TYChannelShelfViewController *cv = [[TYChannelShelfViewController alloc] initWithChannelID:searchResult.uniqueID];
        [self presentViewController:cv animated:true completion:nil];
    }
}

- (void)editSettings:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:true];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self.tableView isEditing] || indexPath.section == 1){
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (void)deleteItem:(MetaDataAsset *)asset {
    TLog(@"delete item: %@ id: %@", asset.name, asset.uniqueID);
    NSMutableArray *newItems = [self.items mutableCopy];
    [newItems removeObject:asset];
    TLog(@"newItems: %@", newItems);
    self.items = newItems;
    [[KBYourTube sharedInstance] removeHomeSection:asset];
}

- (void)refreshList {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    MetaDataAsset  *mda = self.items[indexPath.row];
    NSString *messageString = [NSString stringWithFormat:@"Are you sure you want to delete '%@'? This is permanent and cannot be undone.", mda.name];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Delete Item?" message:messageString preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteItem:mda];
        [self refreshList];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
    
    [ac addAction: cancel];
    [ac addAction:action];
    [self presentViewController:ac animated:TRUE completion:nil];
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
