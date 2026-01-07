// Copyright (c) 2021 Tencent. All rights reserved.
// Author: eddardliu

#import "ReflectUtil.h"

@implementation ReflectUtil

+ (id)invokeMethod:(id) instance methodName:(NSString *)methodName withArguments:(NSArray *)arguments {
    NSLog(@"invokeMethod methodName:%@",methodName);
    
    SEL selector = NSSelectorFromString(methodName);
    if (instance == nil || ![instance respondsToSelector:selector]) {
        return nil;
    }
    
    NSMethodSignature *signature = [instance methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:instance];
    
    for (NSUInteger i = 0; i < arguments.count; i++) {
        id arg = arguments[i];
        NSUInteger argIndex = i + 2;
        const char *argType = [signature getArgumentTypeAtIndex:argIndex];
        if (strcmp(argType, @encode(id)) == 0) {
            [invocation setArgument:&arg atIndex:argIndex];
        } else if (strcmp(argType, @encode(int)) == 0) {
            int value = [arg intValue];
            [invocation setArgument:&value atIndex:argIndex];
        } else if (strcmp(argType, @encode(NSInteger)) == 0) {
            NSInteger value = [arg integerValue];
            [invocation setArgument:&value atIndex:argIndex];
        } else if (strcmp(argType, @encode(BOOL)) == 0) {
            BOOL value = [arg boolValue];
            [invocation setArgument:&value atIndex:argIndex];
        } else if (strcmp(argType, @encode(float)) == 0) {
            float value = [arg floatValue];
            [invocation setArgument:&value atIndex:argIndex];
        } else if (strcmp(argType, @encode(double)) == 0) {
            double value = [arg doubleValue];
            [invocation setArgument:&value atIndex:argIndex];
        } else if (strcmp(argType, @encode(CGFloat)) == 0) {
            CGFloat value = [arg doubleValue];
            [invocation setArgument:&value atIndex:argIndex];
        } else {
            [invocation setArgument:&arg atIndex:argIndex];
        }
    }
    [invocation invoke];

    if (signature.methodReturnLength > 0) {
        const char *returnType = signature.methodReturnType;
        if (strcmp(returnType, "@") == 0) {
            __unsafe_unretained id returnObj;
            [invocation getReturnValue:&returnObj];
            return returnObj;
        }else if (strcmp(returnType, @encode(int)) == 0) {
            int value;
            [invocation getReturnValue:&value];
            return @(value);
        }
        else if (strcmp(returnType, @encode(BOOL)) == 0) {
            BOOL value;
            [invocation getReturnValue:&value];
            return @(value);
        }
    }
    return nil;
}


+ (id)safeValueForProperty:(id) instance propertyName:(NSString *)propertyName {
    @try {
        if ([instance respondsToSelector:NSSelectorFromString(propertyName)]) {
            return [instance valueForKey:propertyName];
        }
        return nil;
    } @catch (NSException *exception) {
        NSLog(@"Failed to securely retrieve attributes: %@", exception);
        return nil;
    }
}

@end


