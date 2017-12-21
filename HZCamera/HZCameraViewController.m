//
//  HZCameraViewController.m
//  HZCamera
//
//  Created by huangzhenyu on 15/7/21.
//  Copyright (c) 2015年 eamon. All rights reserved.
//

#import "HZCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+Custom.h"
#import "HZSliderView.h"

#define kAppWidth [UIScreen mainScreen].bounds.size.width
#define kAppHeight [UIScreen mainScreen].bounds.size.height
#define kMaxFocusScale 5 //最大焦距
#define kMinFocusScale 1 //最小焦距(默认就是1，最好不要改)
typedef enum : NSInteger {
    hzcameraMode1to1,
    hzcameraMode3to4,
    hzcameraMode9to16
} hzcameraMode;

@interface HZCameraViewController ()
//负责把捕获的数据输出到输出设备中
@property (nonatomic,strong) AVCaptureSession *session;
//获得输入数据
@property (nonatomic,strong) AVCaptureDeviceInput *input;
//照片输出流
@property (nonatomic,strong) AVCaptureStillImageOutput *captureOutput;
//照相机拍摄预览层
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic,strong) UIImageView *focusCursor;
@property (nonatomic,strong) UIView *topBarView;
@property (nonatomic,strong) UIView *bottomBarView;
@property (nonatomic,strong) UIView *previewLayerView;
@property (nonatomic,strong) UIButton *flashButton;//闪光灯
@property (nonatomic,strong) HZSliderView *slider;
@property (nonatomic,strong) UIImageView *thumbnailImagePreview;//预览小图

@property hzcameraMode cameraMode;
@property (nonatomic,assign) CGFloat deviceScale;//记录当前摄像头的缩放系数
@property (nonatomic,strong) UIPinchGestureRecognizer *pinch;//捏合手势
@property (nonatomic,weak) NSTimer *sliderHiddenTimer;
@property (nonatomic,assign) NSInteger count;//计数器，控制slider显示与否

@end

@implementation HZCameraViewController

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_session stopRunning];
    //移除定时器
    if (self.sliderHiddenTimer) {
        [self.sliderHiddenTimer invalidate];
        self.sliderHiddenTimer = nil;
    }
}
- (void)dealloc
{
    NSLog(@"dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //添加程序进入后台的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    self.view.backgroundColor = [UIColor blackColor];
    _cameraMode = hzcameraMode3to4;//初始化
    self.deviceScale = kMinFocusScale;
    [self.view addSubview:self.previewLayerView];
    [self.view addSubview:self.topBarView];
    [self.view addSubview:self.bottomBarView];
    [self.previewLayerView addSubview:self.focusCursor];
    [self.previewLayerView addSubview:self.slider];
    
    //初始化会话
    _session = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [_session setSessionPreset:AVCaptureSessionPresetHigh];//设置最高分辨率
    }
    //获得输入设备
    AVCaptureDevice *device= [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    _input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //设置闪光灯的初始值默认是 AVCaptureFlashModeOff
    [self.input.device lockForConfiguration:nil];
    self.input.device.flashMode = AVCaptureFlashModeOff;
    [self.input.device unlockForConfiguration];
    //初始化设备输出对象，用于获得输出数据
    _captureOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [_captureOutput setOutputSettings:outputSettings];
    //将设备输入添加到会话
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    //将设备输出添加到会话
    if ([_session canAddOutput:_captureOutput]) {
        [_session addOutput:_captureOutput];
    }
    CALayer *layer = self.previewLayerView.layer;
    layer.masksToBounds = YES;
    //创建视频预览层
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.frame = layer.bounds;
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [layer insertSublayer:_previewLayer below:self.focusCursor.layer];
    [_session startRunning];
    
    //添加手势，单击或者捏合
    [self addGenstureRecognizer];
    
    //计数器，控制slider的显示与否
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(timerSchedule) userInfo:nil repeats:YES];
    self.sliderHiddenTimer = timer;
    [timer fire];
    //手动加入主循环
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGRect rect = self.previewLayerView.frame;
    CGFloat previewLayerViewH = rect.size.height;
    if (_cameraMode == hzcameraMode9to16) {
        previewLayerViewH = previewLayerViewH - 60;
    }
    self.slider.frame = CGRectMake(30, previewLayerViewH - 60, kAppWidth - 60, 0);
}

#pragma mark slider控制器
- (void)timerSchedule{
    NSLog(@"self.count:%li",(long)self.count);
    self.count += 1;
    if (self.count > 5) {//大概5秒后让slider消失
        self.slider.hidden = YES;
    }
}

#pragma mark 顶部操作条
- (UIView *)topBarView
{
    if (!_topBarView) {
        CGFloat topViewH = 50;
        _topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kAppWidth, topViewH)];
        _topBarView.backgroundColor = [UIColor clearColor];
        
        AVCaptureDevice *captureDevice = [self.input device];
        AVCaptureFlashMode flashMode = captureDevice.flashMode;
        //闪光灯按钮
        UIButton *flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        flashBtn.frame = CGRectMake(20, (topViewH - 40)*0.5, 40, 40);
        [flashBtn setBackgroundImage:[self flashButtonImageWithFlashMode:flashMode] forState:UIControlStateNormal];
        [flashBtn addTarget:self action:@selector(flashClick:) forControlEvents:UIControlEventTouchUpInside];
        _flashButton = flashBtn;
        [_topBarView addSubview:flashBtn];
        
        //缩放按钮
        UIButton *scaleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        scaleBtn.center = _topBarView.center;
        scaleBtn.frame = CGRectMake((kAppWidth - 60)*0.5, (topViewH - 40)*0.5, 60, 40);
        [scaleBtn setTitle:[self scaleTitleWithMode:_cameraMode] forState:UIControlStateNormal];
        scaleBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        [scaleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [scaleBtn addTarget:self action:@selector(scaleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_topBarView addSubview:scaleBtn];
        
        //翻转按钮
        UIButton *flipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        flipBtn.frame = CGRectMake(kAppWidth - 80, (topViewH - 40)*0.5, 40, 40);
        [flipBtn setBackgroundImage:[UIImage imageNamed:@"icon_btn_video_flip_camera"] forState:UIControlStateNormal];
        [flipBtn addTarget:self action:@selector(flipClick) forControlEvents:UIControlEventTouchUpInside];
        [_topBarView addSubview:flipBtn];
    }
    return _topBarView;
}

- (UIImage *)flashButtonImageWithFlashMode:(AVCaptureFlashMode) mode{
    UIImage *image;
    if (mode == AVCaptureFlashModeOn) {
        image = [UIImage imageNamed:@"icon_btn_camera_flash_on"];
    } else if (mode == AVCaptureFlashModeAuto) {
        image = [UIImage imageNamed:@"icon_btn_camera_flash_auto"];
    } else if (mode == AVCaptureFlashModeOff) {
        image = [UIImage imageNamed:@"icon_btn_camera_flash_off"];
    }
    return image;
}

- (NSString *)scaleTitleWithMode:(hzcameraMode) mode{
    NSString *str;
    if (mode == hzcameraMode1to1) {
        str = @"1:1";
    } else if(mode == hzcameraMode3to4) {
        str = @"3:4";
    } else if (mode == hzcameraMode9to16) {
        str = @"9:16";
    }
    return str;
}

#pragma mark 底部操作条
- (UIView *)bottomBarView
{
    if (!_bottomBarView) {
        CGFloat bottomViewH = 90;
        _bottomBarView = [[UIView alloc] initWithFrame:CGRectMake(0, kAppHeight - bottomViewH, kAppWidth, bottomViewH)];
        _bottomBarView.backgroundColor = [UIColor clearColor];
        //停止拍摄按钮
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(20, (bottomViewH - 40)*0.5, 40, 40);
        [cancelBtn setBackgroundImage:[UIImage imageNamed:@"btn_cancel_a"] forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(cancelClick) forControlEvents:UIControlEventTouchUpInside];
        [_bottomBarView addSubview:cancelBtn];
        
        //拍照按钮
        UIButton *takePhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        takePhotoBtn.frame = CGRectMake((kAppWidth - 60)*0.5, (bottomViewH - 60)*0.5, 60, 60);
        [takePhotoBtn setBackgroundImage:[UIImage imageNamed:@"paizhao"] forState:UIControlStateNormal];
        [takePhotoBtn addTarget:self action:@selector(takePictureClick) forControlEvents:UIControlEventTouchUpInside];
        [_bottomBarView addSubview:takePhotoBtn];
        
        //预览图
        UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(kAppWidth - 20 - 60, (bottomViewH - 60)*0.5, 60, 60)];
        self.thumbnailImagePreview = imageview;
        imageview.contentMode = UIViewContentModeScaleAspectFill;
        imageview.clipsToBounds = YES;
        imageview.userInteractionEnabled = YES;
        UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thumbnailImageTap)];
        [imageview addGestureRecognizer:imageTap];
        [_bottomBarView addSubview:imageview];
    }
    return _bottomBarView;
}

- (void)thumbnailImageTap{
    NSLog(@"thumbnailImageTap");
}

#pragma mark 中间预览层
- (UIView *)previewLayerView
{
    if (!_previewLayerView) {
        _previewLayerView = [[UIView alloc] initWithFrame:[self previewFramewithMode:_cameraMode]];
        _previewLayerView.backgroundColor = [UIColor clearColor];
       
    }
    return _previewLayerView;
}

- (CGRect)previewFramewithMode:(hzcameraMode) mode
{
    CGRect rect;
    if (mode == hzcameraMode1to1) {
        rect = CGRectMake(0, (kAppHeight - kAppWidth)*0.5, kAppWidth, kAppWidth);
    } else if (mode == hzcameraMode3to4) {
        rect = CGRectMake(0, (kAppHeight - (kAppWidth * 4)/3) * 0.5, kAppWidth, (kAppWidth * 4)/3);
    } else if (mode == hzcameraMode9to16) {
        rect = CGRectMake(0, 0, kAppWidth, kAppHeight);
    }
    return rect;
}

#pragma mark 焦距设置slider
- (HZSliderView *)slider{
    if (!_slider) {
        _slider = [[HZSliderView alloc] initWithFrame:CGRectMake(30, 200, kAppWidth - 60, 0)];
        _slider.hidden = YES;
        _slider.minValue = kMinFocusScale;
        _slider.maxValue = kMaxFocusScale;
        __weak typeof(self) weakSelf = self;
        _slider.valueChangedBlock = ^(CGFloat value){
            [weakSelf setDevice:weakSelf.input.device videoZoomFactor:value];
             weakSelf.deviceScale = value;
            weakSelf.slider.hidden = NO;

            weakSelf.count = 0;//计数器清零
        };
    }
    return _slider;
}

#pragma mark 聚焦图片框
- (UIImageView *)focusCursor
{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _focusCursor.image = [UIImage imageNamed:@"camera_aperture"];
        _focusCursor.alpha = 0;
    }
    return _focusCursor;
}

#pragma mark 闪光灯点击
- (void)flashClick:(UIButton *)button
{
    AVCaptureDevice *captureDevice = [self.input device];
    AVCaptureFlashMode flashMode = captureDevice.flashMode;
    [captureDevice lockForConfiguration:nil];
    //三种闪光模式循环切换
    if ([captureDevice isFlashAvailable]) {
        if (flashMode == AVCaptureFlashModeOff) {
            [captureDevice setFlashMode:AVCaptureFlashModeOn];
            [button setBackgroundImage:[UIImage imageNamed:@"icon_btn_camera_flash_on"] forState:UIControlStateNormal];
        } else if (flashMode == AVCaptureFlashModeOn) {
            [captureDevice setFlashMode:AVCaptureFlashModeAuto];
            [button setBackgroundImage:[UIImage imageNamed:@"icon_btn_camera_flash_auto"] forState:UIControlStateNormal];
        } else if (flashMode == AVCaptureFlashModeAuto) {
            [captureDevice setFlashMode:AVCaptureFlashModeOff];
            [button setBackgroundImage:[UIImage imageNamed:@"icon_btn_camera_flash_off"] forState:UIControlStateNormal];
        }
    }
    [captureDevice unlockForConfiguration];
}

#pragma mark 摄像头翻转按钮点击
- (void)flipClick
{
    [UIView transitionWithView:self.previewLayerView duration:0.5f options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        self.previewLayerView.alpha = 0.5;
    } completion:^(BOOL finished) {
        self.previewLayerView.alpha = 1.0;
    }];
    
    NSArray *inputs = self.session.inputs;
    for ( AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront){//切换到后摄像头
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
                _flashButton.hidden = NO;
                self.deviceScale = kMinFocusScale;
                self.slider.hidden = YES;
                [self setDevice:self.input.device videoZoomFactor:1.0];
                if (![self.previewLayerView.gestureRecognizers containsObject:self.pinch]) {
                    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
                        [self.previewLayerView addGestureRecognizer:self.pinch];
                    }
                }
            } else {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
                _flashButton.hidden = YES;
                self.slider.hidden = YES;
                self.deviceScale = kMinFocusScale;
                [self setDevice:self.input.device videoZoomFactor:1.0];
                if ([self.previewLayerView.gestureRecognizers containsObject:self.pinch]) {
                    [self.previewLayerView removeGestureRecognizer:self.pinch];
                }
            }
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            [self.session commitConfiguration];
            break;
        }
    }
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

#pragma mark 画幅比例
- (void)scaleButtonClick:(UIButton *)button
{
    if ([button.titleLabel.text isEqualToString:@"1:1"]) {
        [button setTitle:@"3:4" forState:UIControlStateNormal];
        _previewLayerView.frame = [self previewFramewithMode:hzcameraMode3to4];
        _cameraMode = hzcameraMode3to4;
    } else if ([button.titleLabel.text isEqualToString:@"3:4"]) {
        [button setTitle:@"9:16" forState:UIControlStateNormal];
        _previewLayerView.frame = [self previewFramewithMode:hzcameraMode9to16];
        _cameraMode = hzcameraMode9to16;
    } else if ([button.titleLabel.text isEqualToString:@"9:16"]) {
        [button setTitle:@"1:1" forState:UIControlStateNormal];
        _previewLayerView.frame = [self previewFramewithMode:hzcameraMode1to1];
        _cameraMode = hzcameraMode1to1;
    }
     _previewLayer.frame = _previewLayerView.bounds;
}

#pragma mark 取消按钮
- (void)cancelClick{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark 拍照拍照拍照
- (void)takePictureClick{
    //获取相机的连接
    AVCaptureConnection *connection = nil;
    for (AVCaptureConnection *tempConnection in self.captureOutput.connections) {
        for (AVCaptureInputPort *port in [tempConnection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                connection = tempConnection;
                break;
            }
        }
        if (connection) {
            break;
        }
    }
    
    //保存图片
    [self.captureOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        NSLog(@"%f -- %f",image.size.width,image.size.height);
        NSLog(@"%ld",(long)image.imageOrientation);
        UIImage *newImage = [self cutImageWithImage:image mode:_cameraMode];
        
        //图片旋转
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        UIImage *flipImage;
        if (orientation == UIDeviceOrientationLandscapeLeft) {//屏幕左
           flipImage = [UIImage imageWithCGImage:newImage.CGImage scale:1 orientation:UIImageOrientationUp];
//            filpImage = [newImage rotateImageWithValue:-0.5];
        } else if (orientation == UIDeviceOrientationLandscapeRight) {//屏幕右
            flipImage = [UIImage imageWithCGImage:newImage.CGImage scale:1 orientation:UIImageOrientationDown];
//            filpImage = [newImage rotateImageWithValue:0.5];
        } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {//下
            flipImage = [UIImage imageWithCGImage:newImage.CGImage scale:1 orientation:UIImageOrientationLeft];
//            filpImage = [newImage rotateImageWithValue:1];
        } else {
           flipImage = newImage;
        }
        if (flipImage) {
            self.thumbnailImagePreview.image = flipImage;
        }
//        UIImageWriteToSavedPhotosAlbum(filpImage, nil, nil, nil);
    }];
    
}

#pragma mark 添加手势
- (void)addGenstureRecognizer{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen:)];
        [self.previewLayerView addGestureRecognizer:tapGesture];
        if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0) {
            [self.previewLayerView addGestureRecognizer:self.pinch];
        }
}

- (UIPinchGestureRecognizer *)pinch{
    if (!_pinch) {
        _pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    }
    return _pinch;
}

#pragma mark 单击聚焦
- (void)tapScreen:(UITapGestureRecognizer *)tap{
    CGPoint point = [tap locationInView:self.previewLayerView];
    [self addFocusCursorWithPoint:point];
    //UI坐标转摄像头坐标
    CGPoint cameraPoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    AVCaptureDevice *captureDevice = [self.input device];
    [captureDevice lockForConfiguration:nil];
    [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
    [captureDevice setFocusPointOfInterest:cameraPoint];
    [captureDevice unlockForConfiguration];
}

-(void)addFocusCursorWithPoint:(CGPoint)point{
    if (self.focusCursor.alpha == 0) {
        self.focusCursor.center=point;
        self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
        self.focusCursor.alpha=1.0;
        [UIView animateWithDuration:0.5f animations:^{
            self.focusCursor.transform=CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            self.focusCursor.alpha=0;
        }];
    }
}

#pragma mark 捏合调整摄像头焦距
- (void)pinch:(UIPinchGestureRecognizer *)pinch{
    
    CGFloat scale = self.deviceScale + (pinch.scale - 1);
    if (scale > kMaxFocusScale) scale = kMaxFocusScale;   // 最大5倍焦距
    if (scale < kMinFocusScale) scale = kMinFocusScale;   // 最小1倍焦距
//    NSLog(@"pinch:%f -- deviceScale:%f -- scale:%f",pinch.scale,self.deviceScale,scale);
    [self setDevice:self.input.device videoZoomFactor:scale];
    self.slider.value = scale;
    
    self.slider.hidden = NO;
    self.count = 0; //计数器清零
    
    // 缩放结束时记录当前倍焦
    if (pinch.state == UIGestureRecognizerStateEnded) {
        NSLog(@"缩放结束");
        self.deviceScale = scale;
    }
}

#pragma mark 设置缩放系数
- (void)setDevice:(AVCaptureDevice *)device videoZoomFactor:(CGFloat)scale
{
    [device lockForConfiguration:nil];
    device.videoZoomFactor = scale;
    [device unlockForConfiguration];
}


#pragma mark 图片裁剪
- (UIImage *)cutImageWithImage:(UIImage *)origionImage mode:(hzcameraMode) mode{
    CGSize newSize;
    if (mode == hzcameraMode1to1) {
        newSize = CGSizeMake(origionImage.size.width, origionImage.size.width);
    } else if (mode == hzcameraMode3to4) {
        newSize = CGSizeMake(origionImage.size.width, origionImage.size.width * 4/3);
    } else if (mode == hzcameraMode9to16) {
        newSize = origionImage.size;
    }
//    NSLog(@"newSize --  %@,%f",NSStringFromCGSize(newSize),origionImage.scale);
    CGRect rect = CGRectMake(origionImage.scale * (origionImage.size.height - newSize.height )*0.5,
                             origionImage.scale * (origionImage.size.width - newSize.width)*0.5,
                             origionImage.scale * newSize.height,
                             origionImage.scale * newSize.width);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(origionImage.CGImage, rect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:origionImage.scale orientation:origionImage.imageOrientation];
    
    CGImageRelease(imageRef);
    return newImage;
}

#pragma mark 程序退到后台的处理
- (void)applicationEnterBackground{
    NSLog(@"applicationEnterBackground");
    self.deviceScale = kMinFocusScale;
    [self setDevice:self.input.device videoZoomFactor:1.0];
    self.slider.hidden = YES;
    self.slider.value = kMinFocusScale;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
