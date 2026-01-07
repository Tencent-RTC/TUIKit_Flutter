// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

NS_ASSUME_NONNULL_BEGIN

@interface ReflectUtil : NSObject
+ (id)safeValueForProperty:(id) instance propertyName:(NSString *)propertyName;
+ (id)invokeMethod:(id) instance methodName:(NSString *)methodName withArguments:(NSArray *)arguments;
@end

NS_ASSUME_NONNULL_END
