#import "KBContextMenuSection.h"

@implementation KBContextMenuSection

- (NSString *)description {
    NSString *sup = [super description];
    return [NSString stringWithFormat:@"%@ title: %@ items: %@", sup, _title, _items];
}

@end
