//
//  TYHomeShelfViewController.h
//  tuyuTV
//
//  Created by js on 9/22/24.
//

#import "KBShelfViewController.h"
#import "KBSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface TYHomeShelfViewController : KBShelfViewController

- (id)initWithSections:(NSArray <KBSectionProtocol>*)sections;

@end

NS_ASSUME_NONNULL_END
