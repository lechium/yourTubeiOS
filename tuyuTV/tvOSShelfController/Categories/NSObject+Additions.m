//#import "Defines.h"
#import "NSObject+Additions.h"
#import "UIWindow+Additions.h"
#ifndef SHELF_EXT
#import "SVProgressHUD.h"
#endif
@implementation UICollectionView (section)

- (NSInteger)section {
    return [objc_getAssociatedObject(self, @selector(section)) integerValue];
}

- (void)setSection:(NSInteger)section {
    objc_setAssociatedObject(self, @selector(section), @(section), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UILabel (shadow)

- (void)shadowify {
    if (!self.text) {
        //TLog(@"no text for you!");
        return;
    }
    NSShadow* shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor blackColor];
    shadow.shadowOffset = CGSizeMake(1.0f, 1.0f);
    shadow.shadowBlurRadius = 4;
    NSDictionary *attrs = @{NSFontAttributeName: self.font, NSForegroundColorAttributeName: self.textColor, NSShadowAttributeName: shadow};
    NSAttributedString *theString = [[NSAttributedString alloc] initWithString:self.text attributes:attrs];
    
    self.attributedText = theString;
}

@end

@implementation NSObject (Additions)
/*
- (BOOL)darkMode {
    
    if ([self topViewController].view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark){
        return TRUE;
    }
    return FALSE;
}
*/
- (BOOL)alertShowing {
    UIViewController *pres = [[self topViewController] presentingViewController];
    if (pres){
        return [pres isKindOfClass:UIAlertController.class];
    }
    return false;
}

- (UIViewController *)topViewController {
#ifndef SHELF_EXT
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [[[UIApplication sharedApplication] keyWindow] visibleViewController];
#pragma clang diagnostic pop
#else
    return nil;
#endif
}

#if TARGET_OS_TV

- (BOOL)darkMode {
    
    if ([self topViewController].view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark){
        return TRUE;
    }
    return FALSE;
}

#endif

- (NSArray *)propertiesForClass:(Class)clazz {
    u_int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++) {
        const char* propertyName = property_getName(properties[i]);
        NSString *propName = [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        char *selectorName = property_copyAttributeValue(properties[i], "S");
        NSString* selectorString;
        if (selectorName == NULL) {
            char firstChar = (char)toupper(propertyName[0]);
            NSString* capitalLetter = [NSString stringWithFormat:@"%c", firstChar];
            NSString* reminder      = [NSString stringWithCString: propertyName+1
                                                         encoding: NSASCIIStringEncoding];
            selectorString = [@[@"set", capitalLetter, reminder, @":"] componentsJoinedByString:@""];
            if (class_respondsToSelector(clazz, NSSelectorFromString(selectorString))) {
                //DLog(@"class: %@ %@ setting selector: %@", clazz, propName, selectorString);
                [propArray addObject:propName];
            } else {
                //DLog(@"class: %@ %@ bad selector: %@", clazz, propName, selectorString);
            }
        } else {
            selectorString = [NSString stringWithCString:selectorName encoding:NSASCIIStringEncoding];
            //DLog(@"%@ setting selector proper: %@", propName, selectorString);
            [propArray addObject:propName];
        }
    }
    free(properties);
    return propArray;
}

- (NSArray *)methods {
    u_int count;
    Method* methods = class_copyMethodList(self.class, &count);
    NSMutableArray* methodArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++) {
        SEL selector = method_getName(methods[i]);
        const char* methodName = sel_getName(selector);
        [methodArray addObject:[NSString  stringWithCString:methodName encoding:NSUTF8StringEncoding]];
    }
    free(methods);
    return methodArray;
}
/*
- (NSArray *)properties {
    u_int count;
    objc_property_t* properties = class_copyPropertyList(self.class, &count);
    NSMutableArray* propArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        NSString *propName = [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        [propArray addObject:propName];
    }
    free(properties);
    Class sup = [self superclass];
    while (sup != nil){
        NSArray *a = [sup propertiesForClass:sup];
        [propArray addObjectsFromArray:a];
        sup = [sup superclass];
    }
    return propArray;
}
*/

- (NSArray *)ivarsForClass:(Class)clazz {

    u_int count;
    Ivar* ivars = class_copyIvarList(clazz, &count);
    NSMutableArray* ivarArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* ivarName = ivar_getName(ivars[i]);
        [ivarArray addObject:[NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]];
    }
    free(ivars);
    return ivarArray;
}

-(NSArray *)ivars {
    Class clazz = [self class];
    u_int count;
    Ivar* ivars = class_copyIvarList(clazz, &count);
    NSMutableArray* ivarArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++)
    {
        const char* ivarName = ivar_getName(ivars[i]);
        [ivarArray addObject:[NSString  stringWithCString:ivarName encoding:NSUTF8StringEncoding]];
    }
    free(ivars);
    Class sup = [self superclass];
    while (sup != nil){
        NSArray *a = [sup ivarsForClass:sup];
        [ivarArray addObjectsFromArray:a];
        sup = [sup superclass];
    }
    return ivarArray;
}


- (void)clearAllProperties {
    u_int count;
    objc_property_t* properties = class_copyPropertyList(self.class, &count);
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        NSString *propName = [NSString  stringWithCString:propertyName encoding:NSUTF8StringEncoding];
        [self setValue:nil forKey:propName];
    }
    free(properties);
}

- (id)safeObjectAtIndex:(NSInteger)index {
    return [self safeObjectAtIndex:index withOptions:0];
}

- (id)safeObjectAtIndex:(NSInteger)index withOptions:(NSInteger)opts {
    if ([self respondsToSelector:@selector(objectAtIndex:)] && [self respondsToSelector:@selector(count)]){
        NSInteger count = [(NSArray*)self count];
        if (index >= count) {
            //DLog(@"index: %lu >= count: %lu", index, count);
            return (opts == 1) ? nil : [NSNull null];
        } else {
            return [(NSArray*)self objectAtIndex:index];
        }
    } else {
        __block id attempt = (opts == 1) ? nil : [NSNull null];
        NSArray *methods = [self methods];
        [methods enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj containsString:@"AtIndex"]) {
                if ([self respondsToSelector:@selector(count)]) {
                    NSInteger count = [(NSArray *)self count];
                    if (index >= count) {
                        //DLog(@"index: %lu >= count: %lu", index, count);
                        *stop = true;
                        return;
                    }
                }
                SEL theSelector = NSSelectorFromString(obj);
                NSMethodSignature *methodSig = [[self class] instanceMethodSignatureForSelector:theSelector];
                NSInvocation *invok = [NSInvocation invocationWithMethodSignature:methodSig];
                [invok setSelector:theSelector];
                [invok setTarget:self];
                [invok setArgument:(void*)&index atIndex:2];
                [invok invoke];
                __unsafe_unretained id att;
                [invok getReturnValue:&att];
                attempt = att;
            }
        }];
        return attempt;
    }
}

- (id)objectForKeyedSubscript:(id)key {
    if ([key respondsToSelector:@selector(rangeOfCharacterFromSet:)]){
        NSRange range = [key rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
        if (range.location != NSNotFound){
            NSString *sub = [key substringWithRange:range];
            if ([sub isEqualToString:@"n"]){
                return [self safeObjectAtIndex:[key integerValue] withOptions:1];
            }
            DLog(@"%@: letterCharacterSet range: %@", sub, NSStringFromRange(range));
        }
    }
    return [self safeObjectAtIndex:[key integerValue]];
}

- (id)objectAtIndexedSubscript:(NSInteger)idx {
    return [self safeObjectAtIndex:idx];
}
- (void)setObject:(id)obj atIndexedSubscript:(NSInteger)idx {
    DLog(@"setObject: %@ atIndexedSubscript: %lu", obj, idx);
}
/*
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    DLog(@"in setValue: %@ for undefined key: %@", value, key);
} */
/*
- (id)valueForUndefinedKey:(NSString *)key {
    DLog(@"in value for undefined key: %@", key);
    return nil;
}
*/

- (void)dismissHUD {
#ifndef SHELF_EXT
    if (![SVProgressHUD isVisible]) return;
    if ([[NSThread currentThread] isMainThread]){
        [SVProgressHUD dismiss];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
        });
    }
#endif
}

- (void)showHUD {
#ifndef SHELF_EXT
    if ([SVProgressHUD isVisible]){
        return;
    }
    if ([[NSThread currentThread] isMainThread]){
        [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
        [SVProgressHUD show];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD setBackgroundColor:[UIColor clearColor]];
            [SVProgressHUD show];
            
        });
    }
#endif
}

- (NSArray *)customFontFamily {
    return nil;
}

- (id)safeObjectForKey:(id)key {
    
    if ([self respondsToSelector:NSSelectorFromString(key)]){
        return [self valueForKey:key];
    }
    DLog(@"%@ does not respond to selector: %@", self, key );
    return nil;
}

+ (id)objectFromDictionary:(NSDictionary *)dictionary usingClass:(Class)cls {
    if (!cls) {
        NSString *className = dictionary[@"___className"];
        if (!className) {
            className = [self valueForKey:@"className"];
        }
        cls = NSClassFromString(className);
    }
    id object = [cls new];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([object respondsToSelector:NSSelectorFromString(key)]){
            if ([obj isKindOfClass:NSArray.class]) {
                NSMutableArray *newArray = [NSMutableArray new];
                [obj enumerateObjectsUsingBlock:^(id  _Nonnull arrayObj, NSUInteger arrayIdx, BOOL * _Nonnull arrayStop) {
                    if ([arrayObj isKindOfClass:NSDictionary.class]){
                        id newObj = [self objectFromDictionary:arrayObj];
                        [newArray addObject:newObj];
                    }
                }];
                @try {
                    [object setValue:newArray forKey:key];
                } @catch (NSException *exception) {
                    DLog(@"setKey: %@ exception: %@", key , exception);
                }
            } else if ([obj isKindOfClass:NSDictionary.class]){
                id newObject = [self objectFromDictionary:obj];
                @try {
                    [object setValue:newObject forKey:key];
                } @catch (NSException *exception) {
                    DLog(@"setKey: %@ exception: %@", key , exception);
                }
            } else {
                @try {
                    [object setValue:obj forKey:key];
                } @catch (NSException *exception) {
                    DLog(@"setKey: %@ exception: %@", key , exception);
                }
            }
        } else {
            //TLog(@"object does NOT respond to: %@", key);
        }
    }];
    return object;
}

+ (id)objectFromDictionary:(NSDictionary *)dictionary {
    return [self objectFromDictionary:dictionary usingClass:nil];
}

//we'll never care about an items delegate details when saving a dict rep, this prevents an inifinite loop/crash on some classes.
- (NSDictionary *)dictionaryRepresentation {
    return [self dictionaryRepresentationExcludingProperties:@[@"delegate", @"superclass", @"hash", @"debugDescription", @"description"]];
}

- (NSDictionary *)dictionaryRepresentationExcludingProperties:(NSArray *)excluding {
    __block NSMutableDictionary *dict = [NSMutableDictionary new];
    Class cls = NSClassFromString([self valueForKey:@"className"]); //this is how we hone in our the properties /just/ for our specific class rather than NSObject's properties.
    NSArray *props = [self propertiesForClass:cls];
    //DLog(@"props: %@ for class: %@", props, cls);
    dict[@"___className"] = [self valueForKey:@"className"];
    [props enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //get the value of the particular property
        id val = [self valueForKey:obj];
        if ([val isKindOfClass:NSString.class] || [val isKindOfClass:NSNumber.class] && !([excluding containsObject:obj])) { //add numbers and strings as is
            [dict setValue:val forKey:obj];
        } else { //not a string or a number
            if ([val isKindOfClass:NSArray.class]) {
                //TLog(@"processing: %@ for %@", obj, [self valueForKey:@"className"]);
                __block NSMutableArray *_newArray = [NSMutableArray new]; //new array will hold the dictionary reps of each item inside said array.
                [val enumerateObjectsUsingBlock:^(id  _Nonnull arrayObj, NSUInteger arrayIdx, BOOL * _Nonnull arrayStop) {
                    [_newArray addObject:[arrayObj dictionaryRepresentation]]; //call ourselves again, but with the current subarray object.
                }];
                [dict setValue:_newArray forKey:obj];
            } else if ([val isKindOfClass:NSDictionary.class]) {
                [dict setValue:val forKey:obj];
            } else { //not an NSString, NSNumber of NSArray, try setting its dict rep for the key.
                //NSString* class = NSStringFromClass(self.class);
                if (val && ![[self valueForKey:@"className"] isEqualToString:@"NSObject"] && !([excluding containsObject:obj])) {
                    //DLog(@"processing: %@ for %@ class: %@", val, obj, [val class]);
                    if ([obj respondsToSelector:@selector(isEqualToString:)]){
                        if ([obj isEqualToString:@"superclass"]) {//}[val isMemberOfClass:NSObject.class]){
                            DLog(@"skip NSObject");
                        } else {
                            [dict setValue:[val dictionaryRepresentation] forKey:obj];
                        }
                    } else {
                        [dict setValue:[val dictionaryRepresentation] forKey:obj];
                    }
                    
                }
            }
        }
    }];
    return dict;
}

+ (NSString *)documentsFolder {
     NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     return [paths objectAtIndex:0];
}


@end
