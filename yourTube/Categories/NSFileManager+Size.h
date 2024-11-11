@interface NSFileManager(Util)
+ (NSUInteger)sizeForFolderAtPath:(NSString *)source;
+ (CGFloat)availableSpaceForPath:(NSString *)source;
+ (void)ls:(const char *)name completion:(void(^)(NSInteger size, NSInteger count))block;
@end
