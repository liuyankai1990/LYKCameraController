//
//  LYKCameraViewController.h
//  cameraDemo
//
//  Created by liuyankai on 16/3/14.
//  Copyright © 2016年 liuyankai. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol LYKCameraViewControllerDelegate <NSObject>

@optional
- (void)getCameraImageSuccess:(UIImage *)image;
- (void)getCameraImageFailed:(NSError *)error;

@end

@interface LYKCameraViewController : UIViewController
@property (nonatomic,weak) id <LYKCameraViewControllerDelegate> delegate;
@end
