//
//  LDProtocolInterceptor.h
//  PreciousMetals
//
//  Created by wangchao on 10/14/15.
//  Copyright © 2015 NetEase. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDProtocolInterceptor : NSObject
@property (nonatomic, readonly, copy) NSArray * interceptedProtocols;
@property (nonatomic, weak) id receiver;//用来保存外部代理
@property (nonatomic, weak) id middleMan;//中转站, 要设成自己

//以下几个初始化方法的Protocol 用来解决键盘依赖的控件(TextField/TextView),在发送的selector (e.g keyboardInputChangedSelection: & keyboardInputChanged:) 不包含在protocol(s)时,在respondsToSelector方法中, 应该让父类来处理. 否则像原来那样直接返回YES, 系统会再调forwardingTargetForSelector返回middleMan 而middleMan没有实现该方法,系统加又开始调respondsToSelector导致无限死循环.
- (instancetype)initWithInterceptedProtocol:(Protocol *)interceptedProtocol;
- (instancetype)initWithInterceptedProtocols:(Protocol *)firstInterceptedProtocol, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithArrayOfInterceptedProtocols:(NSArray *)arrayOfInterceptedProtocols;
@end
