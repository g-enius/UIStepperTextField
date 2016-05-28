//
//  LDProtocolInterceptor.m
//  PreciousMetals
//
//  Created by wangchao on 10/14/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import "LDProtocolInterceptor.h"
#import <objc/runtime.h>

static inline BOOL selector_belongsToProtocol(SEL selector, Protocol * protocol);

@implementation LDProtocolInterceptor
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if ([self.middleMan respondsToSelector:aSelector] &&
        [self isSelectorContainedInInterceptedProtocols:aSelector])
        return self.middleMan;
    
    if ([self.receiver respondsToSelector:aSelector])
        return self.receiver;
    
    return [super forwardingTargetForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self.middleMan respondsToSelector:aSelector] &&
        [self isSelectorContainedInInterceptedProtocols:aSelector])
        return YES;
    
    if ([self.receiver respondsToSelector:aSelector])
        return YES;
    
    return [super respondsToSelector:aSelector];
}

- (instancetype)initWithInterceptedProtocol:(Protocol *)interceptedProtocol
{
    self = [super init];
    if (self) {
        _interceptedProtocols = @[interceptedProtocol];
    }
    return self;
}

- (instancetype)initWithInterceptedProtocols:(Protocol *)firstInterceptedProtocol, ...;
{
    self = [super init];
    if (self) {
        NSMutableArray * mutableProtocols = [NSMutableArray array];
        Protocol * eachInterceptedProtocol;
        va_list argumentList;
        if (firstInterceptedProtocol)
        {
            [mutableProtocols addObject:firstInterceptedProtocol];
            va_start(argumentList, firstInterceptedProtocol);
            while ((eachInterceptedProtocol = va_arg(argumentList, id))) {
                [mutableProtocols addObject:eachInterceptedProtocol];
            }
            va_end(argumentList);
        }
        _interceptedProtocols = [mutableProtocols copy];
    }
    return self;
}

- (instancetype)initWithArrayOfInterceptedProtocols:(NSArray *)arrayOfInterceptedProtocols
{
    self = [super init];
    if (self) {
        _interceptedProtocols = [arrayOfInterceptedProtocols copy];
    }
    return self;
}

- (void)dealloc
{
    _interceptedProtocols = nil;
}

- (BOOL)isSelectorContainedInInterceptedProtocols:(SEL)aSelector
{
    __block BOOL isSelectorContainedInInterceptedProtocols = NO;
    [self.interceptedProtocols enumerateObjectsUsingBlock:^(Protocol * protocol, NSUInteger idx, BOOL *stop) {
        isSelectorContainedInInterceptedProtocols = selector_belongsToProtocol(aSelector, protocol);
        * stop = isSelectorContainedInInterceptedProtocols;
    }];
    return isSelectorContainedInInterceptedProtocols;
}

@end

/**
 * `selector_belongsToProtocol` solves a common problem in proxy objects for delegates where selectors that are not part of the protocol may be unintentionally forwarded to the actual delegate.
 */
BOOL selector_belongsToProtocol(SEL selector, Protocol * protocol)
{
    // Reference: https://gist.github.com/numist/3838169
    for (int optionbits = 0; optionbits < (1 << 2); optionbits++) {
        BOOL required = optionbits & 1;
        BOOL instance = !(optionbits & (1 << 1));
        
        struct objc_method_description hasMethod = protocol_getMethodDescription(protocol, selector, required, instance);
        if (hasMethod.name || hasMethod.types) {
            return YES;
        }
    }
    
    return NO;
}