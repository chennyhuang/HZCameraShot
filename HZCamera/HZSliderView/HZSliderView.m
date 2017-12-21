//
//  HZSliderView.m
//  HZProgressView
//
//  Created by huangzhenyu on 15/7/22.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import "HZSliderView.h"
#import "HZSlider.h"

@interface HZSliderView()
@property (nonatomic,strong)  UIButton *minusBtn;
@property (nonatomic,strong)  UIButton *plusBtn;
@property (nonatomic,strong) HZSlider *slider;
@property (nonatomic,strong) NSTimer *minusTimer;
@property (nonatomic,strong) NSTimer *plusTimer;
@end
@implementation HZSliderView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
//        self.backgroundColor = [UIColor blueColor];
        if (self.maxValue == 0) {
            self.maxValue = 1;
        }
        //默认取值范围是 0 - 1
        HZSlider *slider = [[HZSlider alloc] init];
        slider.minimumValue = self.minValue;
        slider.maximumValue = self.maxValue;
        
        self.slider = slider;
        [slider addTarget:self action:@selector(sliderValueChange:) forControlEvents:UIControlEventValueChanged];
//        [slider addTarget:self action:@selector(sliderEditionEnd:) forControlEvents:UIControlEventEditingDidEnd];
        [self addSubview:slider];
        //添加减号
        UIButton *minusBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.minusBtn = minusBtn;
        [minusBtn setBackgroundImage:[UIImage imageNamed:@"HZSliderViewBundle.bundle/camera_chrome_zoom_minus_button"]
                            forState:UIControlStateNormal];
        [minusBtn addTarget:self action:@selector(minusClickTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
        [minusBtn addTarget:self action:@selector(minusClickTouchDown) forControlEvents:UIControlEventTouchDown];
        
        [self addSubview:minusBtn];
        
        //添加加号
        UIButton *plusBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.plusBtn = plusBtn;
        [plusBtn setBackgroundImage:[UIImage imageNamed:@"HZSliderViewBundle.bundle/camera_chrome_zoom_plus_button"] forState:UIControlStateNormal];
        [plusBtn addTarget:self action:@selector(plusClickTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
        [plusBtn addTarget:self action:@selector(plusClickTouchDown) forControlEvents:UIControlEventTouchDown];
        [self addSubview:plusBtn];
        
    }
    return self;
}

- (void)minusClickTouchDown{
    if (self.slider.minimumValue == self.slider.value) {
        return;
    }
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.02f target:self selector:@selector(minus) userInfo:nil repeats:YES];
    self.minusTimer = timer;
    [timer fire];
    //手动加入主循环
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)minusClickTouchUpInside{
    if (self.minusTimer) {
        [self.minusTimer invalidate];
        self.minusTimer = nil;
    }
}

- (void)minus{
    CGFloat minValue = self.slider.minimumValue;
    CGFloat maxValue = self.slider.maximumValue;
    CGFloat delt = (maxValue - minValue)/60;

    CGFloat tempValue = self.slider.value;
    tempValue -= delt;
    if (tempValue <= minValue) {
        self.slider.value = minValue;
        [self sliderValueChange:self.slider];

        return;
    } else {
        self.slider.value = tempValue;
        [self sliderValueChange:self.slider];
    }

}

- (void)plusClickTouchDown{
    if (self.slider.maximumValue == self.slider.value) {
        return;
    }
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.02f target:self selector:@selector(plus) userInfo:nil repeats:YES];
    self.plusTimer = timer;
    [timer fire];
    //手动加入主循环
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)plusClickTouchUpInside{
    if (self.plusTimer) {
        [self.plusTimer invalidate];
        self.plusTimer = nil;
    }
}

- (void)plus{
    CGFloat minValue = self.slider.minimumValue;
    CGFloat maxValue = self.slider.maximumValue;
    CGFloat delt = (maxValue - minValue)/60;
    
    CGFloat tempValue = self.slider.value;
    tempValue += delt;
    if (tempValue >= maxValue) {
        self.slider.value = maxValue;
        [self sliderValueChange:self.slider];
        return;
    } else {
        self.slider.value = tempValue;
        [self sliderValueChange:self.slider];
    }

}

- (void)setFrame:(CGRect)frame
{
    frame.size.height = 30;
    [super setFrame:frame];
}

- (void)setValue:(CGFloat)value
{
    CGFloat minValue = self.slider.minimumValue;
    CGFloat maxValue = self.slider.maximumValue;
    if (value > maxValue) {
        self.slider.value = maxValue;
    }
    if (value < minValue) {
        self.slider.value = minValue;
    }
    self.slider.value = value;
}

- (void)setMaxValue:(CGFloat)maxValue{
    self.slider.maximumValue = maxValue;
}

- (void)setMinValue:(CGFloat)minValue{
    self.slider.minimumValue = minValue;
    self.slider.value = self.slider.minimumValue;//默认在最左边
}

- (void)sliderValueChange:(UISlider *)slider{
//    NSLog(@"sliderValueChange -- %f",self.slider.value);
    if (self.valueChangedBlock) {
        self.valueChangedBlock(slider.value);
    }
}

//- (void)sliderEditionEnd:(UISlider *)slider{
//    NSLog(@"sliderEditionEndsliderEditionEndsliderEditionEnd");
//}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    CGFloat sepereta = 2;
    CGFloat buttonW = 30;
    CGFloat buttonH = 20;
    self.minusBtn.frame = CGRectMake(sepereta, (H - buttonH)*0.5, buttonW, buttonH);
    self.plusBtn.frame = CGRectMake(W  - buttonW - sepereta, (H - buttonH)*0.5, buttonW, buttonH);
    self.slider.frame = CGRectMake(2*sepereta+buttonW, 0, W - 4*sepereta - buttonW*2, H);
}
@end
