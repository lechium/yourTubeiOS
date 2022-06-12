//
//  NSString+Truncate.h
//  EMLabel
//
//  Created by Mona Zhang on 3/31/15.
//  Updated by Kevin Bradley on 11/12/18
//  Copyright (c) 2015 Mona Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NSString (Truncate)

- (BOOL)willFitToSize:(CGSize)size
       ellipsesString:(NSString*)ellipsesString
       trailingString:(NSString *)trailingString
           attributes:(NSDictionary *)attributes;

- (NSAttributedString *)attributedStringByTruncatingToSize:(CGSize)size
                                            ellipsesString:(NSString *)ellipsesString
                                            trailingString:(NSString *)trailingString
                                                attributes:(NSDictionary *)attributes
                                  trailingStringAttributes:(NSDictionary *)trailingStringAttributes;


@end
