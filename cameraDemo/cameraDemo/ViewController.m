//
//  ViewController.m
//  cameraDemo
//
//  Created by liuyankai on 16/3/14.
//  Copyright © 2016年 liuyankai. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LYKCameraViewController.h"
@interface ViewController () <LYKCameraViewControllerDelegate>

@property (nonatomic,strong) UIImageView *imageView;


@end



@implementation ViewController
#pragma mark  ---- Lazy Loading

- (UIImageView *)imageView {
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
        _imageView.hidden = YES;
        _imageView.frame = self.view.bounds;
        [self.view addSubview:_imageView];
    }
    return _imageView;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button  = [[UIButton alloc] init];
    button.frame = CGRectMake(self.view.frame.size.width / 2 - 100 , self.view.frame.size.height / 2 - 20, 200, 40);
    [button setTitle:@"打开相机控制器" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor lightGrayColor]];
    [button addTarget:self action:@selector(jump) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

}

- (void)getCameraImageSuccess:(UIImage *)image {
    self.imageView.hidden = NO;
    self.imageView.image = image;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.imageView.hidden = YES;
        self.imageView.image = nil;
    });
}
- (void)jump {
    LYKCameraViewController *vc = [[LYKCameraViewController alloc] init];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
    
}

@end
