
#import <Foundation/Foundation.h>

@interface KBYTPreferences : NSUserDefaults {
	NSString * _applicationID;
	NSDictionary * _registrationDictionary;
}

-(id)initWithPersistentDomainName:(NSString *)domainName;
+(KBYTPreferences *)preferences;
@end

