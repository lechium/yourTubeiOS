//
//  NSURLRequest+cURL.m
//
//  Created by Domagoj Tršan on 25/10/14.
//  Copyright (c) 2014 Domagoj Tršan. All rights reserved.
//  Licence: The MIT License (MIT)
//

#import "NSURLRequest+cURL.h"

@implementation NSMutableURLRequest (cURL)

/**
 *  Returns a cURL command for a request.
 *
 *  @return A NSString object that contains cURL command or nil if an URL is not
 *  properly initalized.
 */
- (NSString *)cURL
{
    if ([[self.URL absoluteString] length] == 0) {
        return nil;
    }

    NSMutableString *curlCommand = [NSMutableString stringWithString:@"curl"];

    // append URL
    [curlCommand appendFormat:@" '%@'", [self.URL absoluteString]];

    // append method if different from GET
    if(![@"GET" isEqualToString:self.HTTPMethod]) {
        [curlCommand appendFormat:@" -X %@", self.HTTPMethod];
    }

    // append headers
    NSArray *sortedHeadersKeys =
      [[self.allHTTPHeaderFields allKeys]
        sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    for (NSString *key in sortedHeadersKeys) {
        [curlCommand
           appendFormat:@" -H '%@: %@'", key, self.allHTTPHeaderFields[key]];
    }

    // append HTTP body
    if ([self.HTTPBody length]) {
        NSString *httpBody =
          [[NSString alloc] initWithData:self.HTTPBody
                                encoding:NSUTF8StringEncoding];
        NSString *escapedHttpBody =
          [NSURLRequest escapeAllSingleQuotes:httpBody];

        [curlCommand appendFormat:@" --data '%@'", escapedHttpBody];
    }

    return [curlCommand copy];
}

@end

@implementation NSURLRequest (cURL)

/**
 *  Returns a cURL command for a request.
 *
 *  @return A NSString object that contains cURL command or nil if an URL is not
 *  properly initalized.
 */
- (NSString *)cURL
{
    if ([[self.URL absoluteString] length] == 0) {
        return nil;
    }

    NSMutableString *curlCommand = [NSMutableString stringWithString:@"curl"];

    // append URL
    [curlCommand appendFormat:@" '%@'", [self.URL absoluteString]];

    // append method if different from GET
    if(![@"GET" isEqualToString:self.HTTPMethod]) {
        [curlCommand appendFormat:@" -X %@", self.HTTPMethod];
    }

    // append headers
    NSArray *sortedHeadersKeys =
      [[self.allHTTPHeaderFields allKeys]
        sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    for (NSString *key in sortedHeadersKeys) {
        [curlCommand
           appendFormat:@" -H '%@: %@'", key, self.allHTTPHeaderFields[key]];
    }

    // append HTTP body
    if ([self.HTTPBody length]) {
        NSString *httpBody =
          [[NSString alloc] initWithData:self.HTTPBody
                                encoding:NSUTF8StringEncoding];
        NSString *escapedHttpBody =
          [NSURLRequest escapeAllSingleQuotes:httpBody];

        [curlCommand appendFormat:@" --data '%@'", escapedHttpBody];
    }

    return [curlCommand copy];
}

/**
 *  Escapes all single quotes for shell from a given string.
 *
 *  @param value The value to escape.
 *
 *  @return An escaped value.
 */
+ (NSString *)escapeAllSingleQuotes:(NSString *)value
{
    return [value stringByReplacingOccurrencesOfString:@"'"
                                            withString:@"'\\''"];
}

@end
