#import <Foundation/Foundation.h>

@interface KBContextMenuSection: NSObject
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *title;
@property (readwrite, assign) BOOL singleSelection;
@end
