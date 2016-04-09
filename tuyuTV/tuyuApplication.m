//
//  tuyuApplication.m
//  yourTubeiOS
//
//  Created by Kevin Bradley on 4/5/16.
//
//

#import "tuyuApplication.h"

@implementation tuyuApplication

#define GSEVENT_TYPE 2
#define GSEVENT_FLAGS 12
#define GSEVENTKEY_KEYCODE 15
#define GSEVENT_TYPE_KEYUP 11

NSString *const GSEventKeyUpNotification = @"GSEventKeyUpHackNotification";




- (void)sendEvent:(UIEvent *)event
{
    LOG_SELF;
    [super sendEvent:event];
    
    if ([event respondsToSelector:@selector(_gsEvent)]) {
        
        // Key events come in form of UIInternalEvents.
        // They contain a GSEvent object which contains
        // a GSEventRecord among other things
        
        int *eventMem;
        
       // eventMem = (int *)[event valueForKey:@"_gsEvent"];
        (int *)[event performSelector:@selector(_gsEvent)];
        if (eventMem) {
            
            NSLog(@"got a gs event?");
            // So far we got a GSEvent :)
            
            int eventType = eventMem[GSEVENT_TYPE];
            if (eventType == GSEVENT_TYPE_KEYUP) {
                
                // Now we got a GSEventKey!
                
                // Read flags from GSEvent
                int eventFlags = eventMem[GSEVENT_FLAGS];
                if (eventFlags) {
                    
                    NSLog(@"event flags???");
                    
                    // This example post notifications only when
                    // pressed key has Shift, Ctrl, Cmd or Alt flags
                    
                    // Read keycode from GSEventKey
                    int tmp = eventMem[GSEVENTKEY_KEYCODE];
                    UniChar *keycode = (UniChar *)&tmp;
                    
                    // Post notification
                    NSDictionary *userInfo;
                    userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [NSNumber numberWithShort:keycode[0]],
                           @"keycode",
                           [NSNumber numberWithInt:eventFlags],
                           @"eventFlags",
                           nil];
                    NSLog(@"userInfo: %@", userInfo);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:GSEventKeyUpNotification
                     object:nil
                     userInfo:userInfo];
                }
            }
        }
    }
}

@end
