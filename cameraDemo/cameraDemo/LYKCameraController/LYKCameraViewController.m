//
//  LYKCameraViewController.m
//  cameraDemo
//
//  Created by liuyankai on 16/3/14.
//  Copyright © 2016年 liuyankai. All rights reserved.
//

typedef enum{
    LYKCameraFlashTypeNone = 1,
    LYKCameraFlashTypeOpen = 2,
    LYKCameraFlashTypeAuto = 3
}LYKCameraFlashType;

#define kTopBarHeight 64
#define kBottomBarHeight 49
#define kFlashKey @"LYKFlashKey"
#define kAutoTitle @"自动"
#define kOffTitle @"关闭"
#define kOpenTitle @"打开"

#import "LYKCameraViewController.h"
#import "LYKCustomButton.h"
#import <AVFoundation/AVFoundation.h>
@interface LYKCameraViewController () <UIGestureRecognizerDelegate>
/** session 用于数据传递*/
@property (nonatomic,strong) AVCaptureSession *session;
/**输入设备*/
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;
/**照片输出流*/
@property (nonatomic,strong) AVCaptureStillImageOutput *imageOutPut;
@property (nonatomic,strong) UIView *previewView;
/**预览图层*/
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
/**拍照后显示图片的View*/
@property (nonatomic,strong) UIImageView *imageView;

/**重拍按钮*/
@property (nonatomic,weak) UIButton *reTakeButton;
/**取消按钮*/
@property (nonatomic,weak) UIButton *cancleButton;
/**确定按钮*/
@property (nonatomic,weak) UIButton *confirmButton;
/**拍照按钮*/
@property (nonatomic,weak) UIButton *takeButton;
/**开始的缩放比例*/
@property (nonatomic,assign) CGFloat beginGestureScale;
/**最后的缩放比例*/
@property (nonatomic,assign) CGFloat effectiveScale;
/**闪光灯类型*/
@property (nonatomic,assign) LYKCameraFlashType flashType;
/**选择闪光灯类型Menu*/
@property (nonatomic,strong) UIMenuController *menuController;
/**闪光灯按钮*/
@property (nonatomic,strong) LYKCustomButton *flashButton;
/**系统闪光灯类型*/
@property (nonatomic,assign) AVCaptureFlashMode flashMode;
/**聚焦小框*/
@property (nonatomic,weak) UIImageView *focusView;


@end

@implementation LYKCameraViewController

#pragma mark  ---- Lazy Loading
/**会话*/
- (AVCaptureSession *)session {
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}
- (AVCaptureDeviceInput *)videoInput {
    if (_videoInput == nil) {
        _videoInput = [[AVCaptureDeviceInput alloc] init];
    }
    return _videoInput;
}
- (AVCaptureStillImageOutput *)imageOutPut {
    if (_imageOutPut == nil) {
        _imageOutPut = [[AVCaptureStillImageOutput alloc] init];
    }
    return _imageOutPut;
}
- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
        _imageView.hidden = YES;
        _imageView.frame = CGRectMake(0, kTopBarHeight, self.view.bounds.size.width, self.view.bounds.size.height - kTopBarHeight - kBottomBarHeight);
        [self.view addSubview:_imageView];
    }
    return _imageView;
}
- (UIMenuController *)menuController {
    if (_menuController == nil) {
        _menuController = [[UIMenuController alloc] init];
        UIMenuItem *autoItem = [[UIMenuItem alloc] initWithTitle:kAutoTitle action:@selector(selectedAutoFlash)];
        UIMenuItem *noneItem = [[UIMenuItem alloc] initWithTitle:kOffTitle action:@selector(selectedNoneFlash)];
        UIMenuItem *openItem = [[UIMenuItem alloc] initWithTitle:kOpenTitle action:@selector(selectedOpenFlash)];
        [_menuController setMenuItems:@[autoItem,noneItem,openItem]];
    }
    return _menuController;
}
- (void)setFlashType:(LYKCameraFlashType)flashType {
    _flashType = flashType;
    
    if (flashType == LYKCameraFlashTypeAuto) {
        self.flashMode = AVCaptureFlashModeAuto;
    }else if (flashType == LYKCameraFlashTypeOpen) {
        self.flashMode = AVCaptureFlashModeOn;
    }else if (flashType == LYKCameraFlashTypeNone) {
        self.flashMode = AVCaptureFlashModeOff;
    }
}
#pragma mark -----  初始化
- (void)viewDidLoad {
    [super viewDidLoad];
    self.effectiveScale = self.beginGestureScale = 1.0f;
    [self setTabBarView];
    [self setupTopBar];
    [self setupDevice];
    [self setupFocusView];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.session) {
        [self.session startRunning];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.session) {
        [self.session stopRunning];
    }
}
#pragma mark -----  初始化SubViews
/**初始化顶部View*/
- (void)setupTopBar {
    
    UIView *topBackView = [[UIView alloc] init];
    topBackView.frame = CGRectMake(0, 0, self.view.bounds.size.width, kTopBarHeight);
    topBackView.backgroundColor = [UIColor darkTextColor];
    [self.view addSubview:topBackView];
    
    NSInteger flashType = [[NSUserDefaults standardUserDefaults] integerForKey:kFlashKey];
    NSString *flashTitle;
    if (flashType) {
        if (flashType == LYKCameraFlashTypeAuto) {
            self.flashType = LYKCameraFlashTypeAuto;
            flashTitle = kAutoTitle;
        }else if (flashType == LYKCameraFlashTypeNone) {
            self.flashType = LYKCameraFlashTypeNone;
            flashTitle = kOffTitle;
        }else if (flashType == LYKCameraFlashTypeOpen) {
            self.flashType = LYKCameraFlashTypeOpen;
            flashTitle = kOpenTitle;
        }
    }else {
        self.flashType = LYKCameraFlashTypeAuto;
        flashTitle = kAutoTitle;
    }
    CGFloat margin = 20;
    CGFloat buttonW = 60;
    
    LYKCustomButton *flashBtn = [LYKCustomButton buttonWithType:UIButtonTypeCustom];
    flashBtn.frame = CGRectMake(margin, 0, buttonW, kTopBarHeight);
    [flashBtn setTitle:flashTitle forState:UIControlStateNormal];
    [flashBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [flashBtn addTarget:self action:@selector(flashTypeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [topBackView addSubview:flashBtn];
    self.flashButton = flashBtn;
    
    UIButton *directionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    directionBtn.frame = CGRectMake(topBackView.frame.size.width - margin - buttonW, 0, buttonW, kTopBarHeight);
    [directionBtn setTitle:@"后置" forState:UIControlStateNormal];
    [directionBtn setTitle:@"前置" forState:UIControlStateSelected];
    [directionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [directionBtn addTarget:self action:@selector(directionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [topBackView addSubview:directionBtn];
}
/**初始化底部View*/
- (void)setTabBarView {
    
    //tabBarView
    UIView *tabBackView = [[UIView alloc] init];
    tabBackView.frame = CGRectMake(0, self.view.bounds.size.height - kBottomBarHeight, self.view.bounds.size.width, kBottomBarHeight);
    tabBackView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:tabBackView];
    
    CGFloat buttonWidth = self.view.bounds.size.width / 3;
    CGFloat buttonHeight = kBottomBarHeight;
    //重拍按钮
    UIButton *reTakeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    reTakeBtn.frame = CGRectMake(0, 0, buttonWidth, buttonHeight);
    reTakeBtn.hidden = YES;
    [reTakeBtn setTitle:@"重拍" forState:UIControlStateNormal];
    [reTakeBtn addTarget:self action:@selector(reTakeClick) forControlEvents:UIControlEventTouchUpInside];
    [tabBackView addSubview:reTakeBtn];
    self.reTakeButton = reTakeBtn;
    
    //取消按钮
    UIButton *cancleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancleBtn.frame = reTakeBtn.bounds;
    [cancleBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancleBtn addTarget:self action:@selector(cancle) forControlEvents:UIControlEventTouchUpInside];
    [tabBackView addSubview:cancleBtn];
    self.cancleButton = cancleBtn;
   
    //拍照按钮
    UIButton *takeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    takeBtn.frame = CGRectMake(buttonWidth, 0, buttonWidth, buttonHeight);
    [takeBtn setTitle:@"拍照" forState:UIControlStateNormal];
    [takeBtn addTarget:self action:@selector(takePhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [tabBackView addSubview:takeBtn];
    self.takeButton = takeBtn;
    
    
     //确定按钮
    UIButton *confirm = [UIButton buttonWithType:UIButtonTypeCustom];
    confirm.hidden = YES;
    confirm.frame = CGRectMake(buttonWidth * 2, 0, buttonWidth, buttonHeight);
    [confirm setTitle:@"确定" forState:UIControlStateNormal];
    [confirm addTarget:self action:@selector(confirmBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [tabBackView addSubview:confirm];
    self.confirmButton = confirm;
    
    
}
/**初始化设备*/
- (void)setupDevice {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //先锁定。防止其他线程修改
    [device lockForConfiguration:nil];
    [device setFlashMode:self.flashMode];
    [device unlockForConfiguration];
    NSError *error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    NSDictionary *outputSetting = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.imageOutPut setOutputSettings:outputSetting];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.imageOutPut]) {
        [self.session addOutput:self.imageOutPut];
    }
    
    
    UIView *previewView = [[UIView alloc] init];
    previewView.frame = CGRectMake(0, kTopBarHeight, self.view.bounds.size.width, self.view.bounds.size.height - kTopBarHeight - kTopBarHeight);
    previewView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:previewView];
    self.previewView = previewView;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [tap addTarget:self action:@selector(focusGesture:)];
    [previewView addGestureRecognizer:tap];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [previewView addGestureRecognizer:pinch];
    
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = previewView.bounds;
//    self.view.layer.masksToBounds = YES;
    [previewView.layer addSublayer:self.previewLayer];
    
}
/**初始化聚焦View*/
- (void)setupFocusView {
    //点击频幕聚焦时闪烁的View
    /*这里也可以使用一个自定义的View,通过drawRect画边框来实现*/
    UIImageView *focusView = [[UIImageView alloc] init];
    focusView.frame = CGRectMake(0, 0, 50, 50);
    focusView.hidden = YES;
    focusView.alpha = 0.0;
    focusView.image = [UIImage imageNamed:@"focus_icon"];
    [self.previewView addSubview:focusView];
    self.focusView = focusView;
}
/**拍照按钮点击*/
- (void)takePhotoButtonClick:(UIButton *)sender {
    AVCaptureConnection *stillImageConnection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureorientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureorientation];
    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
    [self.imageOutPut captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!error) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [UIImage imageWithData:imageData];
            self.imageView.hidden = NO;
            self.reTakeButton.hidden = NO;
            self.confirmButton.hidden = NO;
            self.takeButton.hidden = YES;
            self.cancleButton.hidden = YES;
            self.imageView.image = image;
            [self.session stopRunning];
        }else {
            if ([_delegate respondsToSelector:@selector(getCameraImageFailed:)]) {
                [_delegate getCameraImageFailed:error];
            }
        }
    }];
}
/**改变焦距手势*/
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {
    BOOL allTouchesAreThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches];
    for (int i = 0; i<numTouches; ++i) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.previewView];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if (![self.previewLayer containsPoint:convertedLocation]) {
            allTouchesAreThePreviewLayer = NO;
            break;
        }
    }
    
    if (allTouchesAreThePreviewLayer) {
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0) {
            self.effectiveScale = 1.0;
        }
        
        CGFloat maxScaleAndFactor = [[self.imageOutPut connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        if (self.effectiveScale > maxScaleAndFactor) {
            self.effectiveScale = maxScaleAndFactor;
        }
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
}

-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}
/**重拍*/
- (void)reTakeClick {
    self.imageView.hidden = YES;
    self.reTakeButton.hidden = YES;
    self.confirmButton.hidden = YES;
    self.takeButton.hidden = NO;
    self.cancleButton.hidden = NO;
    self.imageView.image = nil;
    self.navigationItem.leftBarButtonItem = nil;
    [self.session startRunning];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}
/**确定按钮*/
- (void)confirmBtnClick {
    
    if ([_delegate respondsToSelector:@selector(getCameraImageSuccess:)]) {
        [_delegate getCameraImageSuccess:self.imageView.image];
    }
    [self cancle];
}
/**取消*/
- (void)cancle {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.session) {
            [self.session stopRunning];
            self.session = nil;
        }
    }];
}
/**前后摄像头切换*/
- (void)directionBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    AVCaptureDevicePosition desirePosition;
    if (sender.selected) {
        desirePosition = AVCaptureDevicePositionFront;
    }else {
        desirePosition = AVCaptureDevicePositionBack;
    }
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desirePosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:NULL];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            if ([d position] == AVCaptureDevicePositionFront ) {
                self.flashButton.hidden = YES;
            }else if ([d position] == AVCaptureDevicePositionBack) {
                self.flashButton.hidden = NO;
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
}
- (void)flashTypeButtonClick:(UIButton *)sender {
    [sender becomeFirstResponder];
    
    [self.menuController setTargetRect:self.flashButton.frame inView:self.flashButton];
    [self.menuController setMenuVisible:YES animated:YES];
    
    
}
- (void)selectedAutoFlash {
    [self setFlashTypeWithType:LYKCameraFlashTypeAuto];
}
- (void)selectedNoneFlash {
    [self setFlashTypeWithType:LYKCameraFlashTypeNone];
}
- (void)selectedOpenFlash {
    [self setFlashTypeWithType:LYKCameraFlashTypeOpen];
}
- (void)setFlashTypeWithType:(LYKCameraFlashType)type {
    
    if (type == self.flashType) return;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //必须要先锁定
    [device lockForConfiguration:NULL];
    
    if ([device hasFlash]) {
        if (type == LYKCameraFlashTypeAuto) {
            device.flashMode = AVCaptureFlashModeAuto;
            [self.flashButton setTitle:kAutoTitle forState:UIControlStateNormal];
        }else if (type == LYKCameraFlashTypeNone) {
            device.flashMode = AVCaptureFlashModeOff;
            [self.flashButton setTitle:kOffTitle forState:UIControlStateNormal];
        }else if (type == LYKCameraFlashTypeOpen) {
            device.flashMode = AVCaptureFlashModeOn;
            [self.flashButton setTitle:kOpenTitle forState:UIControlStateNormal];
        }
        self.flashType = type;
        [[NSUserDefaults standardUserDefaults] setInteger:type forKey:kFlashKey];
        
    }else {
        NSLog(@"木有闪光灯");
    }
    [device unlockForConfiguration];
    
    
}
- (void)focusGesture:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [recognizer locationInView:recognizer.view];
        
        [self focusAtPoint:location completionHandler:^{
            [self animateFocusReticuleToPoint:location];
        }];
    }
}
/**聚焦*/
- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];;
    CGPoint pointOfInterest = CGPointZero;
    CGSize frameSize = self.previewView.bounds.size;
    pointOfInterest = CGPointMake(point.y / frameSize.height, 1.0f - (point.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        //Lock camera for configuration if possible
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            
            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
            
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }
            
            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [device unlockForConfiguration];
            
            completionHandler();
        }
    }else {
        completionHandler();
    }
}
/**聚焦动画*/
- (void)animateFocusReticuleToPoint:(CGPoint)targetPoint
{
     self.focusView.alpha = 0.0;
    self.focusView.hidden = NO;
    [self.focusView setCenter:targetPoint];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.focusView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:0.6 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.focusView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.focusView.hidden = YES;
        }];
    }];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}
@end
