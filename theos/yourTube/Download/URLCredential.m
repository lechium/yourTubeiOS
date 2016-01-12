//
//  Credentials.m
//  iOS-URLDownloader
//
//  Created by Kristijan Sedlak on 7/21/11.
//  Copyright 2011 AppStrides. All rights reserved.
//

#import "URLCredential.h"


#pragma mark -

@implementation URLCredential

@synthesize username;
@synthesize password;
@synthesize persistance;

#pragma mark General

- (void)dealloc 
{
	//[username release];
	//[password release];
    
    //[super dealloc];
}

- (id)initWithDefaults
{
	if(self == [super init])
	{
		self.username = nil;
		self.password = nil;
        self.persistance = NSURLCredentialPersistenceForSession;
	}
	
	return self;
}

+ (id)credentialWithUsername:(NSString *)user andPassword:(NSString *)pass
{
    URLCredential *credential = [[URLCredential alloc] initWithDefaults];
    credential.username = user;
    credential.password = pass;

    return credential;
}

@end
