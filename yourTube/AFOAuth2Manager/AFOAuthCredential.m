// AFOAuthCredential.m
//
// Copyright (c) 2012-2014 AFNetworking (http://afnetworking.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE

#import "AFOAuthCredential.h"

NSString * const kAFOAuth2CredentialServiceName = @"AFOAuthCredentialService";

static NSDictionary *AFKeychainQueryDictionaryWithIdentifier(NSString *identifier, NSString *_Nullable accessGroup){
    NSCParameterAssert(identifier);
    
    NSMutableDictionary *dictionary = [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                         (__bridge id)kSecAttrService: kAFOAuth2CredentialServiceName,
                                         (__bridge id)kSecAttrAccount: identifier
                                         } mutableCopy];
    
    if (accessGroup) {
        dictionary[(__bridge id)kSecAttrAccessGroup] = accessGroup;
    }
    
    return [dictionary copy];
}

@interface AFOAuthCredential()
@property (readwrite, nonatomic, copy) NSString *accessToken;
@property (readwrite, nonatomic, copy) NSString *tokenType;
@property (readwrite, nonatomic, copy) NSString *refreshToken;
@property (readwrite, nonatomic, copy) NSDate *expiration;
@end


@implementation AFOAuthCredential
//@dynamic expired;

#pragma mark -

+ (instancetype)credentialWithOAuthToken:(NSString *)token
                               tokenType:(NSString *)type
{
    return [[self alloc] initWithOAuthToken:token tokenType:type];
}

+ (instancetype)credentialWithOAuthDictionary:(NSDictionary *)dict {
    AFOAuthCredential *cred = [[self alloc] init];
    if (!self) {
        return nil;
    }
    
    cred.accessToken = dict[@"access_token"];
    cred.tokenType = dict[@"token_type"];
    NSInteger expireTime = [dict[@"expires_in"]integerValue];
    cred.expiration = [[NSDate date] dateByAddingTimeInterval:expireTime];
    cred.refreshToken = dict[@"refresh_token"];
    return cred;
}

- (id)initWithOAuthToken:(NSString *)token
               tokenType:(NSString *)type
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.accessToken = token;
    self.tokenType = type;
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.accessToken=%@", self.accessToken];
    [description appendFormat:@", self.tokenType=%@", self.tokenType];
    [description appendFormat:@", self.refreshToken=%@", self.refreshToken];
    [description appendFormat:@", self.expired=%d", self.expired];
    [description appendFormat:@", self.expiration=%@", self.expiration];
    [description appendString:@">"];
    return description;
}

- (void)setRefreshToken:(NSString *)refreshToken
{
    _refreshToken = refreshToken;
}

- (void)setExpiration:(NSDate *)expiration
{
    _expiration = expiration;
}

- (void)setRefreshToken:(NSString *)refreshToken
             expiration:(NSDate *)expiration
{
    NSParameterAssert(refreshToken);
    NSParameterAssert(expiration);
    
    self.refreshToken = refreshToken;
    self.expiration = expiration;
}

- (BOOL)isExpired {
    if (self.expiration == nil) return TRUE;
    return [self.expiration compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark Keychain

+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
{
    return [self storeCredential:credential withIdentifier:identifier accessGroup:@"group.com.tuyu"];
}

+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
            accessGroup:(NSString *)accessGroup
{
    id securityAccessibility = nil;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 43000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
    if (&kSecAttrAccessibleWhenUnlocked != NULL) {
        securityAccessibility = (__bridge id)kSecAttrAccessibleWhenUnlocked;
    }
#pragma clang diagnostic pop
#endif
    
    return [[self class] storeCredential:credential withIdentifier:identifier withAccessibility:securityAccessibility accessGroup:accessGroup];
    
}
    
+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
      withAccessibility:(id)securityAccessibility
            accessGroup:(NSString *)accessGroup
    
{
    NSMutableDictionary *queryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier, accessGroup) mutableCopy];
    
    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
    updateDictionary[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:credential];
    
    if (securityAccessibility) {
        updateDictionary[(__bridge id)kSecAttrAccessible] = securityAccessibility;
    }
    
    OSStatus status;
    BOOL exists = ([self retrieveCredentialWithIdentifier:identifier accessGroup:accessGroup] != nil);
    
    if (exists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)queryDictionary, (__bridge CFDictionaryRef)updateDictionary);
    } else {
        [queryDictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)queryDictionary, NULL);
    }
    
    return (status == errSecSuccess);
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier
{
    return [self deleteCredentialWithIdentifier:identifier accessGroup:@"group.com.tuyu"];
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup  {
    NSMutableDictionary *queryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier, accessGroup) mutableCopy];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDictionary);
    
    return (status == errSecSuccess);
}

+ (AFOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier
{
    return [self retrieveCredentialWithIdentifier:identifier accessGroup:@"group.com.tuyu"];
}

+ (AFOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier accessGroup:(NSString *)accessGroup  {
    NSMutableDictionary *queryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier, accessGroup) mutableCopy];
    queryDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    queryDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&result);
    
    if (status != errSecSuccess) {
        return nil;
    }
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)result];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    self.accessToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(accessToken))];
    self.tokenType = [decoder decodeObjectForKey:NSStringFromSelector(@selector(tokenType))];
    self.refreshToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(refreshToken))];
    self.expiration = [decoder decodeObjectForKey:NSStringFromSelector(@selector(expiration))];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
    [encoder encodeObject:self.tokenType forKey:NSStringFromSelector(@selector(tokenType))];
    [encoder encodeObject:self.refreshToken forKey:NSStringFromSelector(@selector(refreshToken))];
    [encoder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
}

@end
