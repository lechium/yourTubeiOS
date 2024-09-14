
#import "NSURLRequest+IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
   
    // TODO:0 RIP THIS OUT FOR RELEASE
    
    return true;
}

@end
