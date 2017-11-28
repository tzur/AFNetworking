// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

#import <ImageIO/ImageIO.h>
#import <LTKit/NSError+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface LTImage () {
  /// Image contents.
  cv::Mat _mat;

  /// Color space of this image.
  lt::Ref<CGColorSpaceRef> _colorSpace;
}
@end

@implementation LTImage

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithImage:(UIImage *)image {
  return [self initWithImage:image loadColorSpace:NO];
}

- (instancetype)initWithImage:(UIImage *)image loadColorSpace:(BOOL)loadColorSpace {
  auto colorSpace = CGImageGetColorSpace(image.CGImage);

  if (loadColorSpace) {
    return [self initWithImage:image targetColorSpace:colorSpace];
  } else {
    auto colorSpaceRef = [LTImage createBitmapColorSpaceFromColorSpace:colorSpace];
    return [self initWithImage:image targetColorSpace:colorSpaceRef.get()];
  }
}

- (instancetype)initWithImage:(UIImage *)image targetColorSpace:(CGColorSpaceRef)colorSpace {
  LTParameterAssert(image);
  cv::Mat mat = [LTImage allocateMatForImage:image];
  [LTImage loadImage:image toMat:&mat backgroundColor:nil colorSpace:colorSpace];
  return [self initWithMat:mat copy:NO colorSpace:colorSpace];
}

- (instancetype)initWithMat:(const cv::Mat &)mat copy:(BOOL)copy {
  return [self initWithMat:mat copy:copy colorSpace:NULL];
}

- (instancetype)initWithMat:(const cv::Mat &)mat copy:(BOOL)copy
                 colorSpace:(nullable CGColorSpaceRef)colorSpace {
  if (self = [super init]) {
    if (copy) {
      mat.copyTo(_mat);
    } else {
      _mat = mat;
    }
    _size = CGSizeMake(self.mat.cols, self.mat.rows);
    _colorSpace = lt::Ref<CGColorSpaceRef>(CGColorSpaceRetain(colorSpace));
  }
  return self;
}

+ (cv::Mat)allocateMatForImage:(UIImage *)image {
  CGSize size = [self imageSizeInPixels:image];
  return cv::Mat(size.height, size.width, [self matTypeForImage:image]);
}

+ (void)loadImage:(UIImage *)image toMat:(cv::Mat *)mat
  backgroundColor:(nullable UIColor *)backgroundColor {
  auto colorSpace = CGImageGetColorSpace(image.CGImage);
  lt::Ref<CGColorSpaceRef> colorSpaceRef([LTImage createBitmapColorSpaceFromColorSpace:colorSpace]);
  [self loadImage:image toMat:mat backgroundColor:backgroundColor colorSpace:colorSpaceRef.get()];
}

+ (void)loadImage:(UIImage *)image toMat:(cv::Mat *)mat
  backgroundColor:(nullable UIColor *)backgroundColor colorSpace:(CGColorSpaceRef)colorSpace {
  LTParameterAssert(CGSizeMake(mat->cols, mat->rows) == [self imageSizeInPixels:image]);
  LTParameterAssert(mat->type() == [[self class] matTypeForImage:image],
                    @"Invalid mat type given (%d vs. the required %d)",
                    [[self class] matTypeForImage:image], mat->type());

  size_t bitsPerComponent = mat->elemSize1() * CHAR_BIT;
  lt::Ref<CGContextRef> context(CGBitmapContextCreate(mat->data, mat->cols, mat->rows,
                                                      bitsPerComponent, mat->step[0], colorSpace,
                                                      [self bitmapFlagsForColorSpace:colorSpace]));
  LTAssert(context.get(), @"Failed to create bitmap context");

  CGContextTranslateCTM(context.get(), 0, mat->rows);
  CGContextScaleCTM(context.get(), 1.0, -1.0);

  UIGraphicsPushContext(context.get());
  CGRect rect = CGRectMake(0, 0, mat->cols, mat->rows);
  if (backgroundColor && [self hasAlpha:image]) {
    [backgroundColor setFill];
    UIRectFill(rect);
    [image drawInRect:rect];
  } else {
    // Use kCGBlendModeCopy to make sure the image overwrites the context buffer, which may be
    // uninitialized.
    [image drawInRect:rect blendMode:kCGBlendModeCopy alpha:1.0];
  }
  UIGraphicsPopContext();
}

+ (BOOL)hasAlpha:(UIImage *)image {
  static const std::set<CGImageAlphaInfo> kAlphaInfoWithAlpha = {
    kCGImageAlphaPremultipliedLast,
    kCGImageAlphaPremultipliedFirst,
    kCGImageAlphaLast,
    kCGImageAlphaFirst,
    kCGImageAlphaOnly
  };

  auto alphaInfo = CGImageGetAlphaInfo(image.CGImage);
  return kAlphaInfoWithAlpha.find(alphaInfo) != kAlphaInfoWithAlpha.cend();
}

+ (lt::Ref<CGColorSpaceRef>)createBitmapColorSpaceFromColorSpace:(CGColorSpaceRef)colorSpace {
  switch (CGColorSpaceGetModel(colorSpace)) {
    case kCGColorSpaceModelMonochrome:
      return lt::Ref<CGColorSpaceRef>(CGColorSpaceCreateDeviceGray());
    case kCGColorSpaceModelRGB:
    case kCGColorSpaceModelIndexed:
    case kCGColorSpaceModelCMYK:
      return lt::Ref<CGColorSpaceRef>(CGColorSpaceCreateDeviceRGB());
    default:
      LTAssert(NO, @"Invalid color space model given: %d", CGColorSpaceGetModel(colorSpace));
  }
}

+ (int)matTypeForImage:(UIImage *)image {
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  LTAssert(colorSpace, @"Received an invalid colorspace");
  return [self matTypeForColorSpace:colorSpace];
}

+ (int)matTypeForColorSpace:(CGColorSpaceRef)colorSpace {
  switch (CGColorSpaceGetModel(colorSpace)) {
    case kCGColorSpaceModelMonochrome:
      return CV_8UC1;
    case kCGColorSpaceModelRGB:
    case kCGColorSpaceModelIndexed:
    case kCGColorSpaceModelCMYK:
      return CV_8UC4;
    default:
      LTAssert(NO, @"Invalid color space model given: %d", CGColorSpaceGetModel(colorSpace));
  }
}

+ (CGBitmapInfo)bitmapFlagsForColorSpace:(CGColorSpaceRef)colorSpace {
  switch (CGColorSpaceGetModel(colorSpace)) {
    case kCGColorSpaceModelMonochrome:
      return kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    case kCGColorSpaceModelRGB:
    case kCGColorSpaceModelIndexed:
      return kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
    default:
      LTAssert(NO, @"Invalid color space model given: %d", CGColorSpaceGetModel(colorSpace));
  }
}

/// Returns the actual size (in pixels) of the image. This is calculated by
/// @code round(image.size * image.scale) @endcode \c round is used instead of \c floor/ceil to
/// prevent a scenario where due to floating precision the result size will be different from the
/// size of the underlying buffer of the \c UIImage, which must be of integer size.
+ (CGSize)imageSizeInPixels:(UIImage *)image {
  return std::round(CGSizeMake(image.size.width * image.scale, image.size.height * image.scale));
}

#pragma mark -
#pragma mark Format conversion
#pragma mark -

- (UIImage *)UIImage {
  return [self UIImageWithScale:1 copyData:YES];
}

- (UIImage *)UIImageWithScale:(CGFloat)scale copyData:(BOOL)copyData {
  NSData *data = [self dataFromMatWithCopying:copyData];

  __block UIImage *image;

  lt::Ref<CGDataProviderRef> provider(CGDataProviderCreateWithCFData((__bridge CFDataRef)data));
  [self createImageWithDataProvider:provider.get() andDo:^(CGImageRef imageRef) {
    image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
  }];

  return image;
}

typedef void (^LTImageCGImageBlock)(CGImageRef imageRef);

- (void)createImageWithDataProvider:(CGDataProviderRef)dataProvider
                              andDo:(NS_NOESCAPE LTImageCGImageBlock)block {
  size_t bitsPerComponent = self.mat.elemSize1() * 8;
  size_t bitsPerPixel = self.mat.elemSize() * 8;
  auto colorSpace = _colorSpace ? lt::Ref<CGColorSpaceRef>(CGColorSpaceRetain(_colorSpace.get())) :
      [self createColorSpaceForImage];
  auto bitmapInfo = [LTImage bitmapFlagsForColorSpace:colorSpace.get()];

  lt::Ref<CGImageRef> imageRef(CGImageCreate(self.mat.cols, self.mat.rows, bitsPerComponent,
                                             bitsPerPixel, self.mat.step[0], colorSpace.get(),
                                             bitmapInfo, dataProvider, NULL, false,
                                             kCGRenderingIntentDefault));
  LTAssert(imageRef, @"Failed to create CGImage from LTImage");

  if (block) {
    block(imageRef.get());
  }
}

- (NSData *)dataFromMatWithCopying:(BOOL)copyData {
  // Note that the length is not `_mat.total() * _mat.elemSize()`, as this is not true for
  // non-continuous matrices. See http://goo.gl/Lmccbg. Additionally, calculating the `length` as
  // `_mat.rows * _mat.step[0]` may cause out-of-bound access since the last row of the matrix
  // contains only `_mat.cols` elements, who's size in bytes is less than or equal to `step[0]`.
  NSUInteger length = (_mat.rows - 1) * _mat.step[0] + _mat.cols * _mat.elemSize();
  if (copyData) {
    return [NSData dataWithBytes:_mat.data length:length];
  } else {
    return [NSData dataWithBytesNoCopy:_mat.data length:length freeWhenDone:NO];
  }
}

- (lt::Ref<CGColorSpaceRef>)createColorSpaceForImage {
  switch (self.mat.channels()) {
    case 1:
      return lt::Ref<CGColorSpaceRef>(CGColorSpaceCreateDeviceGray());
    case 4:
      return lt::Ref<CGColorSpaceRef>(CGColorSpaceCreateDeviceRGB());
    default:
      LTAssert(NO, @"Invalid number of image channels: %d", self.mat.channels());
  }
}

- (BOOL)writeToPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  auto provider = [self createDataProvider];
  if (!provider) {
    if (error) {
      *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                             description:@"Failed creating data provider"];
    }
    return NO;
  }

  __block BOOL imageWritten = NO;
  [self createImageWithDataProvider:provider.get() andDo:^(CGImageRef imageRef) {
    NSURL *url = [NSURL fileURLWithPath:path];
    lt::Ref<CGImageDestinationRef> destination([self newImageDestinationWithURL:url]);
    if (!destination) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeObjectCreationFailed
                               description:@"Failed creating image destination"];
      }
      return;
    }

    NSDictionary *properties = @{
      (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @1
    };
    CGImageDestinationAddImage(destination.get(), imageRef, (__bridge CFDictionaryRef)properties);

    BOOL writtenSuccessfully = CGImageDestinationFinalize(destination.get());
    if (!writtenSuccessfully) {
      if (error) {
        *error = [NSError lt_errorWithCode:LTErrorCodeFileWriteFailed path:path];
      }
      return;
    }

    if (error) {
      *error = nil;
    }

    imageWritten = YES;
  }];

  return imageWritten;
}

- (lt::Ref<CGDataProviderRef>)createDataProvider {
  auto data = [self dataFromMatWithCopying:NO];
  return lt::Ref<CGDataProviderRef>(CGDataProviderCreateWithCFData((__bridge CFDataRef)data));
}

- (CGImageDestinationRef)newImageDestinationWithURL:(NSURL *)url {
  return CGImageDestinationCreateWithURL((__bridge CFURLRef)url, kUTTypeJPEG, 1, NULL);
}

#pragma mark -
#pragma mark Image properties
#pragma mark -

- (nullable CGColorSpaceRef)colorSpace {
  return _colorSpace.get();
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (id)debugQuickLookObject {
  return [self UIImage];
}

@end

NS_ASSUME_NONNULL_END
