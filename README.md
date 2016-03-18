### 这是一个自定义的拍照控制器。
####  解决了iOS自带拍照控制器的内存问题

===========
##### 使用方法
######1.创建控制器：LYKCameraViewController *vc = [[LYKCameraViewController alloc] init];
######2.设置代理：vc.delegate = self;
######3.modal出控制器：[self presentViewController:vc animated:YES completion:nil];

##### 成功的回调
###### 实现代理方法：- (void)getCameraImageSuccess:(UIImage *)image; 获取到拍摄到的图片。

==============
##### 可以根据自己的需求修改UI的哦。



