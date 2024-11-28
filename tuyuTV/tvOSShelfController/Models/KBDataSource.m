
#import "KBDataSource.h"

@implementation KBDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        id item = [self itemIdentifierForIndexPath:indexPath];
        NSDiffableDataSourceSnapshot *snapshot = self.snapshot;
        [snapshot deleteItemsWithIdentifiers:@[item]];
        [self applySnapshot:snapshot animatingDifferences:YES completion:^{
            //
        }];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end
