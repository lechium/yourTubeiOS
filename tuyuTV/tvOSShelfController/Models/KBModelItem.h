//
//  KBModelItem.h
//  tvOSGridTest
//
//  Created by Kevin Bradley on 4/16/23.
//

#import <Foundation/Foundation.h>
#import "KBProtocols.h"
NS_ASSUME_NONNULL_BEGIN
@interface KBModelItem : NSObject <KBCollectionItemProtocol>

@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *banner;
@property (nonatomic, strong) NSString *secondaryTitle;
@property (nonatomic, strong) NSString *details;
@property (nonatomic, strong) NSNumber *resultType;
@property (nonatomic, strong) NSString *uniqueID;

-(instancetype)initWithTitle:(NSString *)title imagePath:(NSString *)path uniqueID:(NSString *)unique;

@end

NS_ASSUME_NONNULL_END
