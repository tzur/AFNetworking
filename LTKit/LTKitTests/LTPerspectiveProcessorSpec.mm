// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPerspectiveProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

// Returns a matrix with a checkerboard pattern.
static cv::Mat4b LTCheckerboard(NSUInteger rows, NSUInteger cols, NSUInteger cell) {
  cv::Mat4b mat((int)rows, (int)cols);
  for (int i = 0; i < mat.rows; ++i) {
    for (int j = 0; j < mat.cols; ++j) {
      mat(i, j) =
          (i / cell + j / cell) % 2 ? cv::Vec4b(255, 255, 255, 255) : cv::Vec4b(0, 0, 0, 255);
    }
  }
  return mat;
}

SpecGLBegin(LTPerspectiveProcessor)

__block LTTexture *inputTexture;
__block LTTexture *outputTexture;
__block LTPerspectiveProcessor *processor;

const CGSize kSize = CGSizeMake(64, 32);

beforeEach(^{
  inputTexture = [LTTexture textureWithImage:LTCheckerboard(kSize.height, kSize.width, 8)];
  outputTexture = [LTTexture byteRGBATextureWithSize:kSize];
  processor = [[LTPerspectiveProcessor alloc] initWithInput:inputTexture andOutput:outputTexture];
});

afterEach(^{
  processor = nil;
  inputTexture = nil;
  outputTexture = nil;
});

context(@"initialization", ^{
  it(@"should raise when initializing without input texture", ^{
    expect(^{
      processor = [[LTPerspectiveProcessor alloc] initWithInput:nil andOutput:outputTexture];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when initializing without output texture", ^{
    expect(^{
      processor = [[LTPerspectiveProcessor alloc] initWithInput:inputTexture andOutput:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"properties", ^{
  it(@"should have default properties", ^{
    expect(processor.horizontal).to.equal(0);
    expect(processor.vertical).to.equal(0);
    expect(processor.rotationAngle).to.equal(0);
  });
  
  it(@"should set horizontal", ^{
    CGFloat newValue = processor.maxHorizontal / 2;
    processor.horizontal = newValue;
    expect(processor.horizontal).to.equal(newValue);
  });
  
  it(@"should set vertical", ^{
    CGFloat newValue = processor.maxVertical / 2;
    processor.vertical = newValue;
    expect(processor.vertical).to.equal(newValue);
  });
  
  it(@"should set rotationAngle", ^{
    CGFloat newValue = processor.maxRotationAngle / 2;
    processor.rotationAngle = newValue;
    expect(processor.rotationAngle).to.equal(newValue);
  });
});

context(@"processing", ^{
  __block cv::Mat4b expected;
  
  it(@"should apply horizontal projection", ^{
    processor.horizontal = M_PI / 180 * 15;
    [processor process];
    expected = LTLoadMat([self class], @"PerspectiveHorizontal.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 5);
  });
  
  it(@"should apply vertical projection", ^{
    processor.vertical = M_PI / 180 * 15;
    [processor process];
    expected = LTLoadMat([self class], @"PerspectiveVertical.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 5);
  });

  it(@"should apply rotation", ^{
    processor.rotationAngle = -M_PI / 180 * 20;
    [processor process];
    expected = LTLoadMat([self class], @"PerspectiveRotation.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 5);
  });
  
  it(@"should apply compound projection", ^{
    processor.horizontal = M_PI / 180 * 15;
    processor.vertical = M_PI / 180 * 15;
    processor.rotationAngle = -M_PI / 180 * 20;
    [processor process];
    expected = LTLoadMat([self class], @"PerspectiveCompound.png");
    expect($(outputTexture.image)).to.beCloseToMatWithin($(expected), 5);
  });
});

context(@"projection data", ^{
  const CGSize kSize = CGSizeMake(512, 256);
  beforeEach(^{
    inputTexture = [LTTexture textureWithImage:LTCheckerboard(kSize.height, kSize.width, 8)];
    outputTexture = [LTTexture byteRGBATextureWithSize:kSize];
    processor = [[LTPerspectiveProcessor alloc] initWithInput:inputTexture andOutput:outputTexture];
    
    processor.horizontal = M_PI / 180 * 15;
    processor.vertical = M_PI / 180 * 15;
    processor.rotationAngle = -M_PI / 180 * 20;
  });
  
  it(@"should return the corners mapped to the corners of the projected texture", ^{
    expect((CGPoint)processor.topLeft).to.beCloseToPointWithin(CGPointMake(0.364, 0.164), 0.01);
    expect((CGPoint)processor.topRight).to.beCloseToPointWithin(CGPointMake(0.695, 0.000), 0.01);
    expect((CGPoint)processor.bottomLeft).to.beCloseToPointWithin(CGPointMake(0.197, 0.995), 0.01);
    expect((CGPoint)processor.bottomRight).to.beCloseToPointWithin(CGPointMake(0.803, 0.291), 0.01);
  });
  
  it(@"should set scale and translation to fit the projected texture in the output texture", ^{
    [inputTexture clearWithColor:GLKVector4One];
    [processor process];
    cv::Mat4b output = outputTexture.image;

    UIEdgeInsets insets = UIEdgeInsetsMake(INFINITY, INFINITY, INFINITY, INFINITY);
    for (int i = 0; i < output.rows; ++i) {
      for (int j = 0; j < output.cols; ++j) {
        if (output(i, j)[3] > 0) {
          insets.top = MIN(insets.top, i);
          insets.left = MIN(insets.left, j);
          insets.right = MIN(insets.right, output.cols - 1 - j);
          insets.bottom = MIN(insets.bottom, output.rows - 1 - i);
        }
      }
    }

    expect(insets.left).to.beCloseToWithin(insets.right, 1);
    expect(insets.top).to.beCloseToWithin(insets.bottom, 1);
    expect(MIN(MIN(insets.left, insets.right), MIN(insets.top, insets.bottom))).to.equal(0);
  });
  
  it(@"should return if point is inside the projected texture", ^{
    [processor process];
    
    // Get the mask of pixels that were drawn from the projected texture.
    cv::Mat4b output = outputTexture.image;
    cv::Mat1b outputMask(output.rows, output.cols);
    std::transform(output.begin(), output.end(), outputMask.begin(), [](const cv::Vec4b &value) {
      return value[3] > 0 ? 255 : 0;
    });
    
    // Get the mask of pixels that pointInTexture: returned YES for.
    cv::Mat1b pointsInTexture(output.rows, output.cols);
    for (int i = 0; i < output.rows; ++i) {
      for (int j = 0; j < output.cols; ++j) {
        CGPoint point = CGPointMake(j + 0.5, i + 0.5) / CGSizeMake(output.cols, output.rows);
        pointsInTexture(i, j) = [processor pointInTexture:point] ? 255 : 0;
      }
    }

    // Count the number of differences, as due to numeric errors few pixels on the corners might be
    // different when testing on a device.
    cv::Mat1b differences(output.rows, output.cols, (uchar)0);
    std::transform(outputMask.begin(), outputMask.end(), pointsInTexture.begin(),
                   differences.begin(), [](const uchar &lhs, const uchar &rhs) {
      return (lhs != rhs) ? 255 : 0;
    });
    
    expect(std::count(differences.begin(), differences.end(), 255)).to.beLessThan(4);
  });
});

SpecEnd
