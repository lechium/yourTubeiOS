//
//  NSURLRequest+cURL.h
//
//  Created by Domagoj Tršan on 25/10/14.
//  Copyright (c) 2014 Domagoj Tršan. All rights reserved.
//  Licence: The MIT License (MIT)
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (cURL)

- (NSString *)cURL;

@end

@interface NSURLRequest (cURL)

- (NSString *)cURL;
+ (NSString *)escapeAllSingleQuotes:(NSString *)value;
@end
