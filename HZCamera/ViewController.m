//
//  ViewController.m
//  HZCamera
//
//  Created by huangzhenyu on 15/7/20.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import "ViewController.h"
#import "HZCameraViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(100, 200, 100, 100);
    [button setTitle:@"拍照" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:25];
    [button addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)btnClick{
    HZCameraViewController *vc = [[HZCameraViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}
@end
