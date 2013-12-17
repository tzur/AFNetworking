// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import "SpectaUtility.h"

static NSString * const kMatOutputBasedir = @"/tmp/";

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual);
static void LTWriteMat(const cv::Mat &mat, NSString *name);
static UIImage *LTMatToUIImage(const cv::Mat &mat);

#pragma mark -
#pragma mark Public methods
#pragma mark -

BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual) {
  if (expected.size != actual.size || expected.depth() != actual.depth() ||
      expected.channels() != actual.channels()) {
    return NO;
  }

  // TODO: (yaron) make this work with other types too.

  for (int y = 0; y < expected.rows; ++y) {
    for (int x = 0; x < expected.cols; ++x) {
      cv::Vec4b va = expected.at<cv::Vec4b>(y, x);
      cv::Vec4b vb = actual.at<cv::Vec4b>(y, x);

      if (memcmp(va.val, vb.val, sizeof(va.val))) {
        LTWriteMatrices(expected, actual);
        return NO;
      }
    }
  }

  return YES;
}

cv::Rect LTCVRectWithCGRect(CGRect rect) {
  return cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

GLKVector4 LTCVVec4bToGLKVector4(cv::Vec4b value) {
  GLKVector4 result;
  for (int i = 0; i < value.channels; ++i) {
    result.v[i] = value(i) / (float)UCHAR_MAX;
  }
  return result;
}

cv::Vec4b LTGLKVector4ToVec4b(GLKVector4 value) {
  return cv::Vec4b(value.x * UCHAR_MAX, value.y * UCHAR_MAX,
                   value.z * UCHAR_MAX, value.w * UCHAR_MAX);
}

#pragma mark -
#pragma mark Implementation
#pragma mark -

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual) {
  LTWriteMat(expected, @"expected");
  LTWriteMat(actual, @"actual");
}

static void LTWriteMat(const cv::Mat &mat, NSString *name) {
  UIImage *image = LTMatToUIImage(mat);

  NSString *filename = [NSString stringWithFormat:@"%@-%@.png",
                        [SPTCurrentTestCase description], name];
  NSString *path = [kMatOutputBasedir stringByAppendingPathComponent:filename];

  [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
}

static UIImage *LTMatToUIImage(const cv::Mat &mat) {
  LTAssert(mat.type() == CV_8UC4, @"Unsupported mat type");

  const size_t kBitsPerComponent = 8;
  const size_t kBitsPerPixel = 32;
  const CGBitmapInfo kBitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;

  size_t bufferLength = mat.total() * mat.elemSize();
  size_t bytesPerRow = mat.elemSize() * mat.cols;
  
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, mat.data, bufferLength, NULL);

  CGImageRef imageRef = CGImageCreate(mat.cols,
                                      mat.rows,
                                      kBitsPerComponent,
                                      kBitsPerPixel,
                                      bytesPerRow,
                                      colorSpaceRef,
                                      kBitmapInfo,
                                      provider,
                                      NULL,
                                      YES,
                                      kCGRenderingIntentDefault);

  CGContextRef context = CGBitmapContextCreate(NULL,
                                               mat.cols,
                                               mat.rows,
                                               kBitsPerComponent,
                                               bytesPerRow,
                                               colorSpaceRef,
                                               kBitmapInfo);

  CGContextDrawImage(context, CGRectMake(0, 0, mat.cols, mat.rows), imageRef);

  CGImageRef cgImage = CGBitmapContextCreateImage(context);
  UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0
                                 orientation:UIImageOrientationUp];

  CGContextRelease(context);
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpaceRef);

	return image;
}
