//
//  UIStepperTextField.h
//  NeteaseLottery
//
//  Created by wangchao on 13-9-9.
//  Copyright (c) 2013年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LDProtocolInterceptor.h"

typedef NS_ENUM(NSInteger, UIStepperContentType) {
    UIStepperContentTypeInteger  = 1 << 0,          //内容类型为整型
    UIStepperContentTypeDouble   = 1 << 1,          //内容类型为浮点型   两位小数结尾
};

typedef NS_ENUM(NSInteger, UIStepperBuySellType) {
    UIStepperBuySellTypeBuy    = 0,          //样式类型为买
    UIStepperBuySellTypeSell   ,          //样式类型为卖
    UIStepperBuySellTypeDefault,          //增加默认类型, 按钮为黄色
};

typedef NS_ENUM(NSInteger, UIStepperSideButtonType) {
    UIStepperFunctionTypeDefault    = 0,          //默认带加减按钮，有加减功能
    UIStepperFunctionTypeNoSideButton             //没有加减按钮
};

@interface UIStepperTextField : UITextField

@property (nonatomic,assign) double minValue;  //默认DBL_MIN
@property (nonatomic,assign) double maxValue;  //默认DBL_MAX
@property (nonatomic, assign) int accuracy;    //精确度（小数点后面的位数，整型为0）
@property (nonatomic,assign) int maxLength; //最大输入位数
@property (nonatomic,assign) UIStepperContentType stepperType; //默认UIStepperContentTypeInteger
@property (nonatomic,assign) UIStepperBuySellType buySellType; //默认UIStepperBuySellTypeBuy
@property (nonatomic,assign) UIStepperSideButtonType sideButtonType;//是否有加减按钮。
@property (nonatomic,strong) LDProtocolInterceptor *delegateInterceptor;//代理中转
@property (nonatomic,assign, getter = isAutoHideKeyboard) BOOL autoHideKeyboard; //按加减号时,自动隐藏键盘, 如果不隐藏,则需要禁掉长按手势,否则会激活magnifying class

- (instancetype)initWithFrame:(CGRect)frame buySellType:(UIStepperBuySellType)buySellType;

//背景闪烁
- (void)backgroundBlinkWithColor:(UIColor*)color;
//检查是否需要置灰按钮
- (void)checkInputValid;

@end
