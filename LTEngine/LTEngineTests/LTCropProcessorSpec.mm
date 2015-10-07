// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCropProcessor.h"

#import "LTFbo.h"
#import "LTOpenCVExtensions.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

/// Based on the following code:
/// http://stackoverflow.com/questions/16265673/rotate-image-by-90-180-or-270-degrees
static cv::Mat LTRotateClockwise(cv::Mat input, NSInteger rotations) {
  rotations = (rotations % 4);
  
  cv::Mat output(input.rows, input.cols, input.type());
  input.copyTo(output);
  
  // 0 for vertical flip, 1 for horizontal.
  BOOL flipAxis = rotations > 0 ? 1 : 0;
  for (NSInteger i = 0; i < std::abs(rotations); ++i) {
    cv::transpose(output, output);
    cv::flip(output, output, flipAxis);
  }
  
  return output;
}

SpecBegin(LTCropProcessor)

__block LTCropProcessor *processor;
__block LTTexture *inputTexture;

const CGSize kInputSize = CGSizeMake(16, 32);
const CGSize kHalfSize = kInputSize / 2;

const cv::Vec4b kRed(255, 0, 0, 255);

beforeEach(^{
  cv::Mat4b input(kInputSize.height, kInputSize.width);
  input.setTo(cv::Vec4b(0, 0, 0, 255));
  input(cv::Rect(0, 0, kHalfSize.width, kHalfSize.height)).setTo(kRed);
  inputTexture = [LTTexture textureWithImage:input];
  processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
});

afterEach(^{
  processor = nil;
  inputTexture = nil;
});

context(@"initialization", ^{
  it(@"should raise when initializing without input", ^{
    expect(^{
      processor = [[LTCropProcessor alloc] initWithInput:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  it(@"should rotate by 0 degrees", ^{
    processor.rotations = 0;
    [processor process];
    cv::Mat4b expected = LTRotateClockwise(inputTexture.image, processor.rotations);
    expect($(processor.outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should rotate by 90 degrees", ^{
    processor.rotations = 1;
    [processor process];
    cv::Mat4b expected = LTRotateClockwise(inputTexture.image, processor.rotations);
    expect($(processor.outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should rotate by 180 degrees", ^{
    processor.rotations = 2;
    [processor process];
    cv::Mat4b expected = LTRotateClockwise(inputTexture.image, processor.rotations);
    expect($(processor.outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should rotate by 270 degrees", ^{
    processor.rotations = 3;
    [processor process];
    cv::Mat4b expected = LTRotateClockwise(inputTexture.image, processor.rotations);
    expect($(processor.outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should rotate counter-clockwise for negative values", ^{
    for (NSInteger i = 0; i < 8; ++i) {
      processor.rotations = -i;
      [processor process];
      
      LTCropProcessor *otherProcessor = [[LTCropProcessor alloc] initWithInput:inputTexture];
      otherProcessor.rotations = 4 - (i % 4);
      [otherProcessor process];
      expect($(processor.outputTexture.image)).to.equalMat($(otherProcessor.outputTexture.image));
    }
  });

  it(@"should rotate more than 360 degrees", ^{
    for (NSInteger i = 4; i < 8; ++i) {
      processor.rotations = i;
      [processor process];
      
      LTCropProcessor *otherProcessor = [[LTCropProcessor alloc] initWithInput:inputTexture];
      otherProcessor.rotations = i % 4;
      [otherProcessor process];
      expect($(processor.outputTexture.image)).to.equalMat($(otherProcessor.outputTexture.image));
    }
  });
  
  it(@"should flip horizontally", ^{
    processor.flipHorizontal = YES;
    [processor process];
    cv::Mat4b expected = inputTexture.image;
    cv::flip(expected, expected, 1);
    expect($(processor.outputTexture.image)).to.equalMat($(expected));
  });
  
  it(@"should flip vertically", ^{
    processor.flipVertical = YES;
    [processor process];
    cv::Mat4b expected = inputTexture.image;
    cv::flip(expected, expected, 0);
    expect($(processor.outputTexture.image)).to.equalMat($(expected));
  });

  context(@"flip after rotate", ^{
    it(@"should flip horizontally after rotate", ^{
      for (NSUInteger i = 0; i < 4; ++i) {
        processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
        processor.rotations = i;
        [processor process];
        
        cv::Mat4b expected = processor.outputTexture.image;
        cv::flip(expected, expected, 1);
        
        processor.flipHorizontal = YES;
        [processor process];
        expect($(processor.outputTexture.image)).to.equalMat($(expected));
      }
    });
    
    it(@"should flip vertically after rotate", ^{
      for (NSUInteger i = 0; i < 4; ++i) {
        processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
        processor.rotations = i;
        [processor process];
        
        cv::Mat4b expected = processor.outputTexture.image;
        cv::flip(expected, expected, 0);
        
        processor.flipVertical = YES;
        [processor process];
        expect($(processor.outputTexture.image)).to.equalMat($(expected));
      }
    });
    
    it(@"should flip both after rotate", ^{
      for (NSUInteger i = 0; i < 4; ++i) {
        processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
        processor.rotations = i;
        [processor process];
        
        cv::Mat4b expected = processor.outputTexture.image;
        cv::flip(expected, expected, -1);
        
        processor.flipHorizontal = YES;
        processor.flipVertical = YES;
        [processor process];
        expect($(processor.outputTexture.image)).to.equalMat($(expected));
      }
    });
  });
  
  context(@"rotate after flip", ^{
    it(@"should rotate after horizontal flip", ^{
      for (NSUInteger i = 0; i < 4; ++i) {
        processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
        processor.flipHorizontal = YES;
        [processor process];
        cv::Mat4b expected = LTRotateClockwise(processor.outputTexture.image, i);
        
        processor.rotations = i;
        [processor process];
        expect($(processor.outputTexture.image)).to.equalMat($(expected));
      }
    });
    
    it(@"should rotate after vertical flip", ^{
      for (NSUInteger i = 0; i < 4; ++i) {
        processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
        processor.flipVertical = YES;
        [processor process];
        cv::Mat4b expected = LTRotateClockwise(processor.outputTexture.image, i);
        
        processor.rotations = i;
        [processor process];
        expect($(processor.outputTexture.image)).to.equalMat($(expected));
      }
    });
    
    it(@"should rotate after flip on both axes", ^{
      for (NSUInteger i = 0; i < 4; ++i) {
        processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
        processor.flipHorizontal = YES;
        processor.flipVertical = YES;
        [processor process];
        cv::Mat4b expected = LTRotateClockwise(processor.outputTexture.image, i);
        
        processor.rotations = i;
        [processor process];
        expect($(processor.outputTexture.image)).to.equalMat($(expected));
      }
    });
  });
  
  context(@"crop", ^{
    beforeEach(^{
      cv::Mat4b input = LTLoadMat([self class], @"CropInput.png");
      inputTexture = [LTTexture textureWithImage:input];
      processor = [[LTCropProcessor alloc] initWithInput:inputTexture];
    });

    it(@"should not crop if applyCrop is NO", ^{
      CGRect kTarget = CGRectMake(5, 47, 122, 80);
      
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);
      
      processor.applyCrop = NO;
      [processor process];
      
      cv::Mat4b expected = inputTexture.image;
      expect($(processor.outputTexture.image)).to.equalMat($(expected));
    });

    it(@"should crop according to cropRectangle", ^{
      CGRect kTarget = CGRectMake(5, 47, 122, 80);
      
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);
      
      processor.applyCrop = YES;
      [processor process];

      cv::Mat4b expected = inputTexture.image;
      expected = expected(LTCVRectWithCGRect(kTarget));
      expect($(processor.outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should crop when setting rectangle after rotation", ^{
      CGRect kTarget = CGRectMake(51, 5, 80, 122);

      processor.rotations = 1;
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);
      
      processor.applyCrop = YES;
      [processor process];
      
      cv::Mat4b expected = inputTexture.image;
      expected =  LTRotateClockwise(expected, processor.rotations);
      expected = expected(LTCVRectWithCGRect(kTarget));
      expect($(processor.outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should crop when setting rectangle after flip", ^{
      CGRect kTarget = CGRectMake(3, 51, 122, 80);
      
      processor.flipHorizontal = YES;
      processor.flipVertical = YES;
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);
      
      processor.applyCrop = YES;
      [processor process];
      
      cv::Mat4b expected = inputTexture.image;
      cv::flip(expected, expected, -1);
      expected = expected(LTCVRectWithCGRect(kTarget));
      expect($(processor.outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should crop when setting rectangle after rotation and flip", ^{
      CGRect kTarget = CGRectMake(47, 3, 80, 122);

      processor.flipHorizontal = YES;
      processor.flipVertical = YES;
      processor.rotations = 1;
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);

      processor.applyCrop = YES;
      [processor process];
      
      cv::Mat4b expected = inputTexture.image;
      cv::flip(expected, expected, -1);
      expected =  LTRotateClockwise(expected, processor.rotations);
      expected = expected(LTCVRectWithCGRect(kTarget));
      expect($(processor.outputTexture.image)).to.equalMat($(expected));
    });
    
    it(@"should adjust crop rectangle after rotation", ^{
      CGRect kTarget = CGRectMake(5, 47, 122, 80);
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);
      processor.rotations = 1;
      expect(processor.cropRectangle).to.equal(CGRectMake(51, 5, 80, 122));
      processor.rotations = 2;
      expect(processor.cropRectangle).to.equal(CGRectMake(129, 51, 122, 80));
      processor.rotations = 3;
      expect(processor.cropRectangle).to.equal(CGRectMake(47, 129, 80, 122));
      processor.rotations = 4;
      expect(processor.cropRectangle).to.equal(kTarget);
    });
    
    it(@"should adjust crop rectangle after flip", ^{
      CGRect kTarget = CGRectMake(5, 47, 122, 80);
      processor.cropRectangle = LTRect(kTarget);
      expect(processor.cropRectangle).to.equal(kTarget);
      processor.flipHorizontal = YES;
      expect(processor.cropRectangle).to.equal(CGRectMake(129, 47, 122, 80));
      processor.flipVertical = YES;
      expect(processor.cropRectangle).to.equal(CGRectMake(129, 51, 122, 80));
      processor.flipHorizontal = NO;
      expect(processor.cropRectangle).to.equal(CGRectMake(5, 51, 122, 80));
      processor.flipVertical = NO;
      expect(processor.cropRectangle).to.equal(kTarget);
    });
    
    it(@"should adjust crop rectangle after rotation and flip", ^{
      CGRect kTarget = CGRectMake(5, 47, 122, 80);
      processor.cropRectangle = LTRect(kTarget);
      processor.flipHorizontal = YES;
      processor.flipVertical = YES;
      processor.rotations = 1;
      expect(processor.cropRectangle).to.equal(CGRectMake(47, 129, 80, 122));
    });
  });
});

SpecEnd
