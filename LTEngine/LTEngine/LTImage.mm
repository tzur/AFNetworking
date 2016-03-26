// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

#import <ImageIO/ImageIO.h>
#import <LTKit/NSError+LTKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface LTImage () {
  /// Image contents.
  cv::Mat _mat;
}

/// Size of the image.
@property (readwrite, nonatomic) CGSize size;

@end

@implementation LTImage

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithImage:(UIImage *)image {
  LTParameterAssert(image);
  cv::Mat mat = [[self class] allocateMatForImage:image];
  [[self class] loadImage:image toMat:&mat];
  return [self initWithMat:mat copy:NO];
}

- (instancetype)initWithMat:(const cv::Mat &)mat copy:(BOOL)copy {
  if (self = [super init]) {
    if (copy) {
      mat.copyTo(_mat);
    } else {
      _mat = mat;
    }
    self.size = CGSizeMake(self.mat.cols, self.mat.rows);
  }
  return self;
}

+ (cv::Mat)allocateMatForImage:(UIImage *)image {
  CGSize size = [self imageSizeInPixels:image];
  return cv::Mat(size.height, size.width, [self matTypeForImage:image]);
}

+ (void)loadImage:(UIImage *)image toMat:(cv::Mat *)mat {
  LTParameterAssert(CGSizeMake(mat->cols, mat->rows) == [self imageSizeInPixels:image]);
  LTParameterAssert(mat->type() == [[self class] matTypeForImage:image],
                    @"Invalid mat type given (%d vs. the required %d)",
                    [[self class] matTypeForImage:image], mat->type());

  size_t bitsPerComponent = CGImageGetBitsPerComponent(image.CGImage);
  CGColorSpaceRef colorSpace =
      [self newBitmapColorSpaceFromColorSpace:CGImageGetColorSpace(image.CGImage)];
  CGContextRef context = CGBitmapContextCreate(mat->data, mat->cols, mat->rows,
                                               bitsPerComponent, mat->step[0], colorSpace,
                                               [self bitmapFlagsForColorSpace:colorSpace]);
  LTAssert(context, @"Failed to create bitmap context");

  CGContextTranslateCTM(context, 0, mat->rows);
  CGContextScaleCTM(context, 1.0, -1.0);

  UIGraphicsPushContext(context);
  // Use kCGBlendModeCopy to make sure the image overwrites the context buffer, which may be
  // uninitialized.
  [image drawInRect:CGRectMake(0, 0, mat->cols, mat->rows) blendMode:kCGBlendModeCopy alpha:1.0];
  UIGraphicsPopContext();
  
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
}

+ (CGColorSpaceRef)newBitmapColorSpaceFromColorSpace:(CGColorSpaceRef)colorSpace {
  switch (CGColorSpaceGetModel(colorSpace)) {
    case kCGColorSpaceModelMonochrome:
      return CGColorSpaceCreateDeviceGray();
    case kCGColorSpaceModelRGB:
    case kCGColorSpaceModelIndexed:
      return CGColorSpaceCreateDeviceRGB();
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
                              andDo:(LTImageCGImageBlock)block {
  size_t bitsPerComponent = self.mat.elemSize1() * 8;
  size_t bitsPerPixel = self.mat.elemSize() * 8;
  lt::Ref<CGColorSpaceRef> colorSpace = [self newColorSpaceForImage];
  CGBitmapInfo bitmapInfo = [[self class] bitmapFlagsForColorSpace:colorSpace.get()];

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
  // Note that the length is not _mat.total() * _mat.elemSize(), as this is not true for
  // non-continuous matrices. See http://goo.gl/Lmccbg.
  NSUInteger length = _mat.rows * _mat.step[0];
  if (copyData) {
    return [NSData dataWithBytes:_mat.data length:length];
  } else {
    return [NSData dataWithBytesNoCopy:_mat.data length:length freeWhenDone:NO];
  }
}

- (lt::Ref<CGColorSpaceRef>)newColorSpaceForImage {
  switch (self.depth) {
    case LTImageDepthGrayscale:
      return lt::Ref<CGColorSpaceRef>(CGColorSpaceCreateDeviceGray());
    case LTImageDepthRGBA:
      return lt::Ref<CGColorSpaceRef>(CGColorSpaceCreateDeviceRGB());
  }
}

- (BOOL)writeToPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  lt::Ref<CGDataProviderRef> provider([self newDataProvider]);
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
    CGImageDestinationAddImage(destination.get(), imageRef, (CFDictionaryRef)properties);

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

- (CGDataProviderRef)newDataProvider {
  NSData *data = [self dataFromMatWithCopying:NO];
  return CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
}

- (CGImageDestinationRef)newImageDestinationWithURL:(NSURL *)url {
  return CGImageDestinationCreateWithURL((CFURLRef)url, kUTTypeJPEG, 1, NULL);
}

#pragma mark -
#pragma mark Image properties
#pragma mark -

- (LTImageDepth)depth {
  switch (self.mat.channels()) {
    case 1:
      return LTImageDepthGrayscale;
    case 4:
      return LTImageDepthRGBA;
    default:
      LTAssert(NO, @"Invalid number of image channels: %d", self.mat.channels());
  }
}

#pragma mark -
#pragma mark Debugging
#pragma mark -

- (id)debugQuickLookObject {
  return [self UIImage];
}

@end
