
#import "KBYTPreferences.h"

@implementation KBYTPreferences

+(KBYTPreferences *)preferences {
    static KBYTPreferences *_preferences = nil;
    
    if(!_preferences)
        _preferences = [[self alloc] initWithPersistentDomainName:@"com.nito.ytbrowser"];
    
    return _preferences;
}

-(id)initWithPersistentDomainName:(NSString *)domainName {
	if((self = [super init]))	{
		_applicationID = [domainName copy];
		_registrationDictionary = nil;		
	}
    
    return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	
}

-(id)valueForKey:(NSString *)key
{
    return [self objectForKey:key];
}

-(id)objectForKey:(NSString *)defaultName {
	id value = (id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)defaultName, (CFStringRef)_applicationID));
	if(value == nil)
		value = [_registrationDictionary objectForKey:defaultName];
	return value;
}

-(void)setObject:(id)value forKey:(NSString *)defaultName {
	CFPreferencesSetAppValue((CFStringRef)defaultName, (CFPropertyListRef)value, (CFStringRef)_applicationID);
    [self synchronize];
	
	
}

-(void)removeObjectForKey:(NSString *)defaultName {
	CFPreferencesSetAppValue((CFStringRef)defaultName, NULL, (CFStringRef)_applicationID);
    [self synchronize];
}
-(void)setBool:(BOOL)value forKey:(NSString *)defaultName
{
    CFPreferencesSetAppValue((CFStringRef)defaultName, (CFNumberRef)[NSNumber numberWithBool:value] , (CFStringRef)_applicationID);
    [self synchronize];
}
-(void)setInteger:(NSInteger)value forKey:(NSString *)defaultName
{
    CFPreferencesSetAppValue((CFStringRef)defaultName, (CFNumberRef)[NSNumber numberWithInteger:value], (CFStringRef)_applicationID);
    [self synchronize];
}
-(void)setDouble:(double)value forKey:(NSString *)defaultName
{
    CFPreferencesSetAppValue((CFStringRef)defaultName, (CFNumberRef)[NSNumber numberWithDouble:value], (CFStringRef)_applicationID);
    [self synchronize];
}
-(void)setFloat:(float)value forKey:(NSString *)defaultName
{
    CFPreferencesSetAppValue((CFStringRef)defaultName, (CFNumberRef)[NSNumber numberWithFloat:value], (CFStringRef)_applicationID);
    [self synchronize];
}
-(BOOL)boolForKey:(NSString *)defaultName
{
    id obj = [self objectForKey:defaultName];
    if(obj!=nil && [obj respondsToSelector:@selector(boolValue)])
        return [obj boolValue];
    return [[_registrationDictionary objectForKey:defaultName] boolValue];
}
-(NSInteger)integerForKey:(NSString *)defaultName
{
    id obj = [self objectForKey:defaultName];
    if(obj!=nil && [obj respondsToSelector:@selector(integerValue)])
        return [obj integerValue];
    return [[_registrationDictionary objectForKey:defaultName] integerValue];
}
-(double)doubleForKey:(NSString *)defaultName
{
    id obj = [self objectForKey:defaultName];
    if(obj!=nil && [obj respondsToSelector:@selector(doubleValue)])
        return [obj floatValue];
    return [[_registrationDictionary objectForKey:defaultName] doubleValue];
}
-(float)floatForKey:(NSString *)defaultName
{
    id obj = [self objectForKey:defaultName];
    if(obj!=nil && [obj respondsToSelector:@selector(floatValue)])
        return [obj floatValue];
    return [[_registrationDictionary objectForKey:defaultName] floatValue];
}

-(void)registerDefaults:(NSDictionary *)registrationDictionary {
	_registrationDictionary = registrationDictionary;
}

-(BOOL)synchronize {
	return CFPreferencesSynchronize((CFStringRef)_applicationID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
}


@end
