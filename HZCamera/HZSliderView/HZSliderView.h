//
//  HZSliderView.h
//  HZProgressView
//
//  Created by huangzhenyu on 15/7/22.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HZSliderView : UIView

@property (nonatomic,assign) CGFloat minValue;
@property (nonatomic,assign) CGFloat maxValue;
@property (nonatomic,assign) CGFloat value;
@property (nonatomic,strong) void(^valueChangedBlock)(CGFloat currentValue);
@end
