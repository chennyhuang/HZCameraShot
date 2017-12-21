//
//  UIImage+Custom.h
//
//  Created by ZQP on 14-7-17.
//

#import <UIKit/UIKit.h>

@interface UIImage (Custom)

//使用纯色生成图片
+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size;

//按照原图的长宽比缩小照片，使图片的长或宽都小于给出的尺寸的长宽
+ (UIImage *)manageImage:(UIImage *)image toFitSize:(CGSize)size;

//更改图片的分辨率高度，按照原图的长宽比缩小照片
+ (UIImage *)resizeImage:(UIImage *)image toHeight:(CGFloat)height;

//更改图片的分辨率宽度，按照原图的长宽比缩小照片
+ (UIImage *)resizeImage:(UIImage *)image toWidth:(CGFloat)width;

//更改图片的分辨率
+ (UIImage *)resizeImage:(UIImage*)image ToSize:(CGSize)size;

//使用纯色生成圆图
+ (UIImage *)circleImageWithColor:(UIColor*)color size:(CGSize)size;

//将图片切为圆图 inset为给圆图加的边框厚度 边框为红色
+ (UIImage*) circleImage:(UIImage*) image withParam:(CGFloat) inset;

//将图片切为圆图 非正方形先切最中间的一部分
+(UIImage*) circleImage:(UIImage*) image;

//裁剪照片中的一部分
- (UIImage*)crop:(CGRect)rect;

//按照给出的比例裁剪照片最中间的一部分
- (UIImage*)cropWithXscale:(float)xscale Yscale:(float)yscale;//截取中间一部分 scale为宽和长所占的比例

//按照角度旋转照片
//需引入Core Image和QuartzCore 框架
-(UIImage*)rotateImageWithValue:(float)value;

//按照角度旋转照片之后，再按照比例进行裁剪。
//需引入Core Image和QuartzCore 框架
-(UIImage*)rotateImageWithValue:(float)value xscale:(float)xScale yScale:(float)yScale;// scale为截取的比例 截取居中的一部分

//把照片按照长宽比放到一个正方形里 没有的地方放透明像素。
-(UIImage*)makeUpImageToSqureWithSqureSideLength:(float)length;

#pragma mark - 把图片按照长宽比放入大小为size的矩形内，空的地方放透明像素
/**
 *   把图片按照长宽比放入大小为size的矩形内，空的地方放透明像素
 */
-(UIImage*)makeUpImageToSize:(CGSize)size;

@end
