// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImage.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "LTCGExtensions.h"
#import "NSError+LTKit.h"

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
  LTParameterAssert(mat->type() == [[self class] matTypeForImage:image],
                    @"Invalid mat type given (%d vs. the required %d)",
                    [[self class] matTypeForImage:image], mat->type());

  size_t bitsPerComponent = CGImageGetBitsPerComponent(image.CGImage);
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
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
      return kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
    default:
      LTAssert(NO, @"Invalid color space model given: %d", CGColorSpaceGetModel(colorSpace));
  }
}

+ (CGSize)imageSizeInPixels:(UIImage *)image {
  return CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
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

  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  [self createImageWithDataProvider:provider andDo:^(CGImageRef imageRef) {
    image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
  }];
  CGDataProviderRelease(provider);

  return image;
}

typedef void (^LTImageCGImageBlock)(CGImageRef imageRef);

- (void)createImageWithDataProvider:(CGDataProviderRef)dataProvider
                              andDo:(LTImageCGImageBlock)block {
  size_t bitsPerComponent = self.mat.elemSize1() * 8;
  size_t bitsPerPixel = self.mat.elemSize() * 8;
  CGColorSpaceRef colorSpace = [self newColorSpaceForImage];
  CGBitmapInfo bitmapInfo = [[self class] bitmapFlagsForColorSpace:colorSpace];

  CGImageRef imageRef = CGImageCreate(self.mat.cols, self.mat.rows, bitsPerComponent, bitsPerPixel,
                                      self.mat.step.p[0], colorSpace, bitmapInfo, dataProvider,
                                      NULL, false, kCGRenderingIntentDefault);
  LTAssert(imageRef, @"Failed to create CGImage from LTImage");

  if (block) {
    block(imageRef);
  }

  CGImageRelease(imageRef);
  CGColorSpaceRelease(colorSpace);
}

- (NSData *)dataFromMatWithCopying:(BOOL)copyData {
  NSUInteger length = _mat.total() * _mat.elemSize();
  if (copyData) {
    return [NSData dataWithBytes:_mat.data length:length];
  } else {
    return [NSData dataWithBytesNoCopy:_mat.data length:length freeWhenDone:NO];
  }
}

- (CGColorSpaceRef)newColorSpaceForImage {
  switch (self.depth) {
    case LTImageDepthGrayscale:
      return CGColorSpaceCreateDeviceGray();
    case LTImageDepthRGBA:
      return CGColorSpaceCreateDeviceRGB();
  }
}

- (BOOL)writeToPath:(NSString *)path error:(NSError *__autoreleasing *)error {
  CGDataProviderRef provider = [self newDataProvider];
  if (!provider) {
    if (error) {
      *error = [NSError errorWithDomain:kLTKitErrorDomain code:LTErrorCodeObjectCreationFailed
                               userInfo:@{kLTInternalErrorMessageKey:
                                            @"Failed creating data provider"}];
    }
    return NO;
  }
  @onExit {
    CGDataProviderRelease(provider);
  };

  __block BOOL imageWritten = NO;
  [self createImageWithDataProvider:provider andDo:^(CGImageRef imageRef) {
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageDestinationRef destinationRef = [self newImageDestinationWithURL:url];
    if (!destinationRef) {
      if (error) {
        *error = [NSError errorWithDomain:kLTKitErrorDomain code:LTErrorCodeObjectCreationFailed
                                 userInfo:@{kLTInternalErrorMessageKey:
                                              @"Error creating image destination"}];
      }
      return;
    }
    @onExit {
      CFRelease(destinationRef);
    };

    CGImageDestinationAddImage(destinationRef, imageRef, nil);

    NSDictionary *properties = @{(__bridge NSString *)kCGImageDestinationLossyCompressionQuality:
                                   @1};
    CGImageDestinationSetProperties(destinationRef, (CFDictionaryRef)properties);

    BOOL writtenSuccessfully = CGImageDestinationFinalize(destinationRef);
    if (!writtenSuccessfully) {
      if (error) {
        *error = [NSError errorWithDomain:kLTKitErrorDomain code:NSFileWriteUnknownError
                                 userInfo:@{kLTInternalErrorMessageKey: @"Error writing image file",
                                            NSFilePathErrorKey: path}];
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
