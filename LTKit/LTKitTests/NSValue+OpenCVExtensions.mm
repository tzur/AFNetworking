// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValue+OpenCVExtensions.h"

#import "NSValue+Expecta.h"

@interface LTMatRetainer : NSObject {
  cv::Mat _mat;
}

- (instancetype)initWithMat:(const cv::Mat &)mat;

@property (readonly, nonatomic) const cv::Mat &mat;

@end

@implementation LTMatRetainer

- (instancetype)initWithMat:(const cv::Mat &)mat {
  if (self = [super init]) {
    _mat = mat;
  }
  return self;
}

@end

@implementation NSValue (OpenCVExtensions)

- (const cv::Mat &)matValue {
  return *(const cv::Mat *)[self pointerValue];
}

- (cv::Scalar)scalarValue {
  cv::Scalar scalar;
  [self getValue:&scalar];
  return scalar;
}

+ (NSValue *)valueWithMat:(const cv::Mat &)mat {
  // Makes sure that the stored \c mat will be retained until this object is disposed.
  LTMatRetainer *retainer = [[LTMatRetainer alloc] initWithMat:mat];

  NSValue *value = [NSValue valueWithPointer:&retainer.mat];
  [value set_EXP_objCType:@encode(cv::Mat)];

  objc_setAssociatedObject(value, @selector(valueWithMat:), retainer,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);

  return value;
}

+ (NSValue *)valueWithScalar:(const cv::Scalar &)scalar {
  NSValue *value = [NSValue valueWithBytes:&scalar objCType:@encode(cv::Scalar)];
  [value set_EXP_objCType:@encode(cv::Scalar)];
  return value;
}

@end
