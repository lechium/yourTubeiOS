

#define DLog(format, ...) CFShow((__bridge CFStringRef)[NSString stringWithFormat:format, ## __VA_ARGS__]);
#define TLog(format, ...) NSLog(@"[tuyu] %@", [NSString stringWithFormat:format, ## __VA_ARGS__]);
#define LOG_SELF        TLog(@"%@ %@", self, NSStringFromSelector(_cmd))
#define LOG_CMD         TLog(@"[%@ %@]",[self class], NSStringFromSelector(_cmd))

#import "KBYourTube.h"
