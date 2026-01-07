// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

NS_ASSUME_NONNULL_BEGIN

@interface VideoRecorderReflectUtil : NSObject
+ (id) createClassInstance:(NSString *)className;
+ (id) invokeStaticMethod:(NSString *)className methodName:(NSString *)methodName
            withArguments:(NSArray *)arguments;
+ (id) safeValueForProperty:(id) instance propertyName:(NSString *)propertyName;
+ (id) invokeMethod:(id) instance methodName:(NSString *)methodName withArguments:(NSArray *)arguments;
@end

NS_ASSUME_NONNULL_END
