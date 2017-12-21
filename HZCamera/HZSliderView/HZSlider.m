//
//  HZSlider.m
//  HZProgressView
//
//  Created by huangzhenyu on 15/7/22.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import "HZSlider.h"

@implementation HZSlider

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setThumbImage:[UIImage imageNamed:@"HZSliderViewBundle.bundle/camera_chrome_zoom_knob"] forState:UIControlStateNormal];
        self.minimumTrackTintColor = [UIColor whiteColor];
        self.maximumTrackTintColor = [UIColor whiteColor];
//        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    //解决左右两边突出的问题
    rect.origin.x = rect.origin.x - 2 ;
    rect.size.width = rect.size.width + 4;
    return CGRectInset ([super thumbRectForBounds:bounds trackRect:rect value:value], 10 , 10);
}

@end
