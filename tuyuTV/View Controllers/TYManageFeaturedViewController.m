//
//  TYManageFeaturedViewController.m
//  tuyuTV
//
//  Created by kevinbradley on 6/9/22.
//

#import "TYManageFeaturedViewController.h"

@interface TYManageFeaturedViewController ()

@end

@implementation TYManageFeaturedViewController

- (id)initWithNames:(NSArray *)names {
    self = [super init];
    self.items = names;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editSettings:)];
    // Do any additional setup after loading the view.
}

- (void)editSettings:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:true];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self.tableView isEditing]){
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (void)refreshList {
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    MetaDataAsset  *mda = self.items[indexPath.row];
    NSString *messageString = [NSString stringWithFormat:@"Are you sure you want to delete '%@'? This is permanent and cannot be undone.", mda.name];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Delete Item?" message:messageString preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        [self refreshList];
        //DLog(@"do it");
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
