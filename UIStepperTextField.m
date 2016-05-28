//
//  UIStepperTextField.m
//  NeteaseLottery
//
//  Created by wangchao on 13-9-9.
//  Copyright (c) 2013年 netease. All rights reserved.
//

#import "UIStepperTextField.h"

#define LDPMSeplineColor [UIColor colorWithRGB:0xdddddd]
#define LDPMBorderColor [UIColor colorWithRGB:0xbbbbbb]
#define LDPMPriceBlinkColor [UIColor colorWithRed:241./255. green:96./255. blue:96./255. alpha:1.]

typedef NS_ENUM(NSInteger, UIStepperWhichButton) {
    UIStepperWhichButtonLeft  = 0,          //minusButton
    UIStepperWhichButtonRight,          //plusButton
};

@interface UIStepperTextField ()

@property (nonatomic,strong) UIView *inputBackgroundView;
@property (nonatomic,strong) UIView *leftSepLine;
@property (nonatomic,strong) UIView *rightSepline;
@property (nonatomic,strong) UIImage *minusImage;
@property (nonatomic,strong) UIImage *plusImage;
@property (nonatomic,strong) UIImage *disabled_plusImage;
@property (nonatomic,strong) UIImage *disabled_minusImage;

@property (nonatomic, assign) CGFloat stepperValue;

@end

@implementation UIStepperTextField
{
    UIButton *addButton;
    UIButton *subButton;
    
    NSTimer *fastAddTimer;
    NSTimer *fastSubTimer;
    
    __weak id _target;
    SEL _action;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initContentWithbuySellType:UIStepperBuySellTypeDefault];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame buySellType:UIStepperBuySellTypeDefault];
}

- (instancetype)initWithFrame:(CGRect)frame buySellType:(UIStepperBuySellType)buySellType {
    self = [super initWithFrame:frame];
    if (self) {
        [self initContentWithbuySellType:buySellType];
    }
    return self;
}

- (void)initContentWithbuySellType:(UIStepperBuySellType)buySellType
{
    //isAutoHideKeyboard
    self.autoHideKeyboard = YES;
    
    //delegateInterceptor
    self.delegateInterceptor = [[LDProtocolInterceptor alloc]initWithInterceptedProtocol:@protocol(UITextFieldDelegate)];
    self.delegateInterceptor.middleMan = self;
    super.delegate = (id<UITextFieldDelegate>)self.delegateInterceptor;
    
    self.minValue = DBL_MIN;
    self.maxValue = DBL_MAX;
    self.maxLength = 10;
    self.stepperType = UIStepperContentTypeInteger;
    self.stepperValue = pow(0.1, self.accuracy);
    
    self.placeholder = @"不设定";
    self.layer.borderWidth = 0.5f;
    self.layer.cornerRadius = 3.0f;
    self.layer.borderColor = [LDPMBorderColor CGColor];
    self.backgroundColor = [UIColor whiteColor];
    
    addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton addTarget:self action:@selector(add:) forControlEvents:UIControlEventTouchUpInside];
    [addButton addTarget:self action:@selector(addButtonDown:) forControlEvents:UIControlEventTouchDown];
    [addButton addTarget:self action:@selector(addStop:) forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    self.rightView = addButton;
    
    subButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [subButton addTarget:self action:@selector(sub:) forControlEvents:UIControlEventTouchUpInside];
    [subButton addTarget:self action:@selector(subButtonDown:) forControlEvents:UIControlEventTouchDown];
    [subButton addTarget:self action:@selector(subStop:) forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    self.leftView = subButton;
    
    if (self.sideButtonType == 0) {
        self.rightViewMode = UITextFieldViewModeAlways;
        self.leftViewMode= UITextFieldViewModeAlways;
    }
    
    self.buySellType = buySellType;//设置位置后置, 必须放在leftView和rightView已经初始化之后, 否则这次设置失效.
    
    //背景闪烁View
    self.inputBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.leftView.bounds), 0, CGRectGetWidth(self.bounds)-CGRectGetWidth(self.leftView.bounds)*2, CGRectGetHeight(self.bounds))];
    self.inputBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.inputBackgroundView.backgroundColor = [UIColor whiteColor];
    self.inputBackgroundView.alpha = 0.0;
    [self addSubview:self.inputBackgroundView];
    [self sendSubviewToBack:self.inputBackgroundView];
    
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    self.leftSepLine = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.leftView.bounds), 0, 0.5, CGRectGetHeight(self.bounds))];
    self.leftSepLine.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
    [self.leftSepLine setBackgroundColor:LDPMSeplineColor];
    [self addSubview:self.leftSepLine];
    
    self.rightSepline = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds)-CGRectGetWidth(self.rightView.bounds), 0, 0.5, CGRectGetHeight(self.bounds))];
    self.rightSepline.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
    [self.rightSepline setBackgroundColor:LDPMSeplineColor];
    [self addSubview:self.rightSepline];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.inputBackgroundView.frame = CGRectMake(CGRectGetWidth(self.leftView.bounds), 0, CGRectGetWidth(self.bounds)-CGRectGetWidth(self.leftView.bounds)*2, CGRectGetHeight(self.bounds));
    self.leftSepLine.frame = CGRectMake(CGRectGetWidth(self.leftView.bounds), 0, 0.5, CGRectGetHeight(self.bounds));
    self.rightSepline.frame = CGRectMake(CGRectGetWidth(self.bounds)-CGRectGetWidth(self.rightView.bounds), 0, 0.5, CGRectGetHeight(self.bounds));
    if (self.sideButtonType == UIStepperFunctionTypeNoSideButton) {
        self.leftSepLine.hidden = YES;
        self.rightSepline.hidden = YES;
    }
}

//Disables magnifying glass     inherit from UIView
-(void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.isAutoHideKeyboard && [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        gestureRecognizer.enabled = NO;
    }
    
    [super addGestureRecognizer:gestureRecognizer];
}

#pragma mark - 检查是否需要置灰按钮
- (void)checkInputValid
{
    enum DOUBLE_COMPARE_RESULT result = DOUBLE_COMPARE_BASE(self.minValue, self.maxValue, self.accuracy + 1);
    if (result == DOUBLE_COMPARE_RESULT_GREATER) {
        NSLog(@"输入框极限值设置错误错误! \n@最小值为%f, 最大值为%f", self.minValue, self.maxValue);
        return;
    }

    NSNumber *addNum = [NSNumber numberWithFloat:self.text.doubleValue + self.stepperValue];
    NSNumber *maxNum = [NSNumber numberWithFloat:self.maxValue];
    NSComparisonResult addCompResult = [addNum compare:maxNum];
    if (addCompResult == NSOrderedDescending) {
        [self setWhichButton:UIStepperWhichButtonRight isEnabled:NO];
        if (self.text.doubleValue > self.maxValue && self.text.length > 0) {
            self.text = STRINGVALUE_ROUND(self.maxValue, self.accuracy);
        }
    } else {
        [self setWhichButton:UIStepperWhichButtonRight isEnabled:YES];
    }
    

    NSNumber *subNum = [NSNumber numberWithFloat:self.text.doubleValue - self.stepperValue];
    NSNumber *mimNum = [NSNumber numberWithFloat:self.minValue];
    NSComparisonResult subCompResult = [subNum compare:mimNum];
    if (subCompResult == NSOrderedAscending) {
        [self setWhichButton:UIStepperWhichButtonLeft isEnabled:NO];
        if (self.text.doubleValue < self.minValue && self.text.length > 0) {
            self.text = STRINGVALUE_ROUND(self.minValue, self.accuracy);
        }
    } else {
        [self setWhichButton:UIStepperWhichButtonLeft isEnabled:YES];
    }
}

- (void)setWhichButton:(UIStepperWhichButton)which isEnabled:(BOOL)isEnabled
{
    switch (which) {
        case UIStepperWhichButtonLeft:
            if (isEnabled) {
                if (!((UIButton *)self.leftView).isEnabled) {
                    ((UIButton *)self.leftView).enabled = YES;
                    [((UIButton *)self.leftView) setImage:self.minusImage forState:UIControlStateNormal];
                }
            } else {
                [(UIButton *)self.leftView setImage:self.disabled_minusImage forState:UIControlStateDisabled];
                ((UIButton *)self.leftView).enabled = NO;
            }
            break;
            
        case UIStepperWhichButtonRight:
            if (isEnabled) {
                if (!((UIButton *)self.rightView).isEnabled) {
                    ((UIButton *)self.rightView).enabled = YES;
                    [((UIButton *)self.rightView) setImage:self.plusImage forState:UIControlStateNormal];
                }
            } else {
                [(UIButton *)self.rightView setImage:self.disabled_plusImage forState:UIControlStateDisabled];
                ((UIButton *)self.rightView).enabled = NO;
            }
            break;
    }
}

#pragma mark - setter

- (void)setStepperType:(UIStepperContentType)stepperType
{
    _stepperType = stepperType;
    
    self.accuracy = (self.stepperType == UIStepperContentTypeInteger) ? 0 : 2;  //浮点型默认保存2位小数
}

- (void)setBuySellType:(UIStepperBuySellType)buySellType {
    _buySellType = buySellType;
    
    self.disabled_plusImage = [UIImage imageNamed:@"disabled_plus"];
    self.disabled_minusImage = [UIImage imageNamed:@"disabled_minus"];
    
    self.plusImage = [UIImage imageNamed:@"default_plus"];
    self.minusImage = [UIImage imageNamed:@"default_minus"];
    [(UIButton *)self.rightView setImage:self.plusImage forState:UIControlStateNormal];
    [(UIButton *)self.leftView setImage:self.minusImage forState:UIControlStateNormal];
}

- (void)setSideButtonType:(UIStepperSideButtonType)sideButtonType
{
    _sideButtonType = sideButtonType;
    if (_sideButtonType == UIStepperFunctionTypeNoSideButton) {
        self.leftViewMode = UITextFieldViewModeNever;
        self.rightViewMode = UITextFieldViewModeNever;
        self.leftSepLine.hidden = YES;
        self.rightSepline.hidden = YES;
    } else if (_sideButtonType == UIStepperFunctionTypeDefault) {
        if (_sideButtonType == UIStepperFunctionTypeNoSideButton) {
            self.leftViewMode = UITextFieldViewModeAlways;
            self.rightViewMode = UITextFieldViewModeAlways;
            self.leftSepLine.hidden = NO;
            self.rightSepline.hidden = NO;
        }
    }
}

- (void)setAccuracy:(int)accuracy
{
    _accuracy = accuracy;
    
    self.stepperValue = pow(0.1, accuracy);
    self.minValue = pow(0.1, accuracy);
}

- (void)setMaxValue:(double)maxValue
{
    _maxValue = maxValue;
    
    [self checkInputValid];
}

- (void)setMinValue:(double)minValue
{
    _minValue = minValue;
    
    [self checkInputValid];
}

#pragma mark - Overide Methods

//Override supper setter

-(id<UITextFieldDelegate>)delegate
{
    return self.delegateInterceptor.receiver;
}

-(void)setDelegate:(id<UITextFieldDelegate>)delegate
{
    super.delegate = nil;
    self.delegateInterceptor.receiver = delegate;
    super.delegate = (id<UITextFieldDelegate>)self.delegateInterceptor;
}

-(void)setText:(NSString *)text
{
    if ([text isEqualToString:@""]) {
        super.text = text;
        return;
    }
    
    if (![super.text isEqualToString:text]) {
        if (text.length > 0) {
            CGFloat value = [text floatValue];
            super.text = STRINGVALUE_ROUND(value, self.accuracy);
        } else {
            super.text = text;
        }
        
        [self checkInputValid];
    }
}

-(void)setEnabled:(BOOL)enabled
{
    if (super.enabled != enabled) {
        super.enabled = enabled;
        if (!enabled) {
            [(UIButton *)self.rightView setImage:self.disabled_plusImage forState:UIControlStateNormal];
            [(UIButton *)self.leftView setImage:self.disabled_minusImage forState:UIControlStateNormal];
            ((UIButton *)self.rightView).enabled = NO;
            ((UIButton *)self.leftView).enabled = NO;
        } else {
            [(UIButton *)self.rightView setImage:self.plusImage forState:UIControlStateNormal];
            [(UIButton *)self.leftView setImage:self.minusImage forState:UIControlStateNormal];
            ((UIButton *)self.rightView).enabled = YES;
            ((UIButton *)self.leftView).enabled = YES;
        }
    }
}

//Override Bounds Methods
- (CGRect)leftViewRectForBounds:(CGRect)bounds
{
    return CGRectMake(0, 0, bounds.size.height, bounds.size.height);
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    return CGRectMake(bounds.size.width - bounds.size.height, 0, bounds.size.height, bounds.size.height);
}

//hack:保存监听UIControlEventEditingChanged事件的target 和 action,限制: 只保存一个
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents
{
    if (controlEvents & UIControlEventEditingChanged) {
        _target = target;
        _action = action;
    }
    
    [super addTarget:target action:action forControlEvents:controlEvents];
}

#pragma mark - 手工数值改变

- (void)valueChanged
{
    //iOS6 以上，代码改变textFiled的值，不会触发editingchange事件  ，或者iOS5当前无焦点时
    if (([[UIDevice currentDevice].systemVersion integerValue] >= 6 || ![self isFirstResponder]) && _target) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_action withObject:self];
#pragma clang diagnostic pop
    }
}

#pragma mark 递增，递减

- (void)add:(id)sender
{
    if (self.isAutoHideKeyboard) {
        [self resignFirstResponder];
    }
    
    if (fastSubTimer) {
        [fastSubTimer invalidate];
        fastSubTimer = nil;
    }
    
    if (fastAddTimer) {
        [fastAddTimer invalidate];
        fastAddTimer = nil;
    }
    
    [self addText];
}

//长按加按钮
- (void)addButtonDown:(id)sender
{
    if (self.isAutoHideKeyboard) {
        [self resignFirstResponder];
    }
    
    if (fastSubTimer) {
        [fastSubTimer invalidate];
        fastSubTimer = nil;
    }
    
    if (fastAddTimer) {
        [fastAddTimer invalidate];
        fastAddTimer = nil;
    }
    
    if (!fastAddTimer) {
        fastAddTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(addText) userInfo:nil repeats:YES];
    }
}

- (void)addStop:(id)sender
{
    if (fastAddTimer) {
        [fastAddTimer invalidate];
        fastAddTimer = nil;
    }
}

- (void)sub:(id)sender
{
    if (self.isAutoHideKeyboard) {
        [self resignFirstResponder];
    }
    
    if (fastSubTimer) {
        [fastSubTimer invalidate];
        fastSubTimer = nil;
    }
    
    if (fastAddTimer) {
        [fastAddTimer invalidate];
        fastAddTimer = nil;
    }
    
    [self subText];
}

//长按减按钮
- (void)subButtonDown:(id)sender
{
    if (self.isAutoHideKeyboard) {
        [self resignFirstResponder];
    }
    
    if (fastAddTimer) {
        [fastAddTimer invalidate];
        fastAddTimer = nil;
    }
    
    if (fastSubTimer) {
        [fastSubTimer invalidate];
        fastSubTimer = nil;
    }
    
    if (!fastSubTimer) {
        fastSubTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(subText) userInfo:nil repeats:YES];
    }
}

- (void)subStop:(id)sender
{
    if (fastSubTimer) {
        [fastSubTimer invalidate];
        fastSubTimer = nil;
    }
}

- (void)addText
{
    double value = [self.text doubleValue];
    if (value < self.maxValue) {
        self.text = STRINGVALUE_ROUND(value + self.stepperValue, self.accuracy);
        
        [self checkInputValid];
        [self valueChanged];
    }
}

- (void)subText
{
    double value = [self.text doubleValue];
    if (value > self.minValue) {
        self.text = STRINGVALUE_ROUND(value - self.stepperValue, self.accuracy);
        
        [self checkInputValid];
        [self valueChanged];
    }
}


#pragma mark - 背景闪动效果

-(void)backgroundBlinkWithColor:(UIColor *)color
{
    self.inputBackgroundView.backgroundColor = color;
    [UIView animateWithDuration:0.5 animations:^{
        self.inputBackgroundView.alpha = 0.3;
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.5 animations:^{
                self.inputBackgroundView.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.inputBackgroundView.alpha = 0.0;
            }];
        } else {
            self.inputBackgroundView.alpha = 0.0;
        }
    }];
}

#pragma mark - 禁止粘贴

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:)) {
        return NO;
    }
    
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - UITextFieldDelegate

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        return [self.delegate textFieldDidBeginEditing:textField];
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [self checkInputValid];
    
    if (textField.text.length > 0) {
        textField.text = STRINGVALUE_ROUND(textField.text.doubleValue, self.accuracy);
    }
    
    if ([self.delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
        return [self.delegate textFieldDidEndEditing:textField];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{    
    NSString *replaceStr = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (replaceStr.length > self.maxLength) {
        return NO;
    }
    
    //判断小数点的位数,超过位数不能再进行输入
    NSRange ran = [replaceStr rangeOfString:@"."];
    if (ran.location != NSNotFound) {
        NSInteger tt = replaceStr.length - ran.location - 1;
        if (tt > self.accuracy) {
            return NO;
        }
    }
    
    BOOL flag = YES;
    if (string.length > 0) {
        NSString *floatExp = @"^([1-9]\\d*|0)\\.\\d*$|^[1-9]\\d*$|^0$";
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", floatExp];
        flag = [predicate evaluateWithObject:replaceStr];
    }
    
    if (flag) {
        if ([self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            return [self.delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
        }
    }
    
    return flag;
}

@end
