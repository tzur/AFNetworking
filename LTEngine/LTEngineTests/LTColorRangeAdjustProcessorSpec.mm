// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorRangeAdjustProcessor.h"

#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

@interface LTColorRangeAdjustProcessor ()

/// \c YES if dual mask needs processing prior to executing this processor.
//@property (nonatomic) BOOL needsDualMaskProcessing;

/// Internal dual mask processor.
//@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

/// Color that is used to construct a mask that defines a color range upon which tonal manipulation
/// is applied. Components should be in [-1, 1] range. Default value is green (0, 1, 0).
@property (nonatomic) LTVector3 rangeColor;

@end

LTSpecBegin(LTColorRangeAdjustProcessor)

__block LTTexture *input;
__block LTTexture *output;
__block LTColorRangeAdjustProcessor *processor;

beforeEach(^{
  input = [LTTexture textureWithImage:cv::Mat4b(1, 1, cv::Vec4b(128, 64, 255, 255))];
  output = [LTTexture textureWithPropertiesOf:input];
  processor = [[LTColorRangeAdjustProcessor alloc] initWithInput:input output:output];
});

afterEach(^{
  processor = nil;
  input = nil;
  output = nil;
});

context(@"properties", ^{
  it(@"should return default properties correctly", ^{
    expect(processor.maskType).to.equal(LTDualMaskTypeRadial);
    expect(processor.spread).to.equal(0);
    expect(processor.angle).to.equal(0);
    expect(processor.fuzziness).to.equal(0);
    expect(processor.disableRangeAttenuation).to.beFalsy();
    expect(processor.renderingMode).to.equal(LTColorRangeRenderingModeImage);
    expect(processor.saturation).to.equal(0);
    expect(processor.exposure).to.equal(0);
    expect(processor.contrast).to.equal(0);
    expect(processor.hue).to.equal(0);
  });
  
  it(@"should fail on incorrect input", ^{
    expect(^{
      processor.fuzziness = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.saturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.hue = 1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.exposure = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.contrast = -1.1;
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.fuzziness = -1.0;
      processor.saturation = -1.0;
      processor.exposure = -1.0;
      processor.contrast = -1.0;
      processor.hue = 1.0;
    }).toNot.raiseAny();
  });

  context(@"setting mask center", ^{
    beforeEach(^{
      cv::Mat4b inputImage = cv::Mat4b(2, 2, cv::Vec4b(128, 64, 255, 255));
      inputImage(1, 1) = cv::Vec4b(255, 255, 255, 255);
      input = [LTTexture textureWithImage:inputImage];
      output = [LTTexture textureWithPropertiesOf:input];
      processor = [[LTColorRangeAdjustProcessor alloc] initWithInput:input output:output];
    });

    it(@"should fail on out of bounds center", ^{
      expect(^{
        processor.center = LTVector2(-1, -1);
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        processor.center = LTVector2(std::nextafter(0.0f, -1.0f), 0);
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        processor.center = LTVector2(3, 3);
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        processor.center = LTVector2(1, std::nextafter(2.0f, 3.0f));
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should allow center inside image bounds", ^{
      expect(^{
        processor.center = LTVector2Zero;
      }).toNot.raiseAny();

      expect(^{
        processor.center = LTVector2(2, 2);
      }).toNot.raiseAny();
    });

    it(@"should select the target color correctly", ^{
      processor.center = LTVector2Zero;
      expect(processor.rangeColor).to.equal(LTVector3(128, 64, 255) / 255);

      processor.center = LTVector2(0.5, 0.5);
      expect(processor.rangeColor).to.equal(LTVector3(128, 64, 255) / 255);

      processor.center = LTVector2One;
      expect(processor.rangeColor).to.equal(LTVector3(1, 1, 1));

      processor.center = LTVector2(2, 2);
      expect(processor.rangeColor).to.equal(LTVector3(1, 1, 1));
    });
  });
});

context(@"small inputs", ^{
  it(@"should initialize and process 1x1 image", ^{
    expect(^{
      input = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
      output = [LTTexture textureWithPropertiesOf:input];
      processor = [[LTColorRangeAdjustProcessor alloc] initWithInput:input output:output];
      [processor process];
    }).toNot.raiseAny();
  });

  it(@"should initialize and process 4x3 image", ^{
    expect(^{
      input = [LTTexture byteRGBATextureWithSize:CGSizeMake(4, 3)];
      output = [LTTexture textureWithPropertiesOf:input];
      processor = [[LTColorRangeAdjustProcessor alloc] initWithInput:input output:output];
      [processor process];
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  beforeEach(^{
    processor.center = LTVector2(0, 0);
    processor.diameter = 10;
  });
  
  it(@"should update internal state if input texture is changed", ^{
    [input clearWithColor:LTVector4(1, 1, 1, 1)];
    processor = [[LTColorRangeAdjustProcessor alloc] initWithInput:input output:output];
    processor.contrast = 1;
    processor.center = LTVector2Zero;
    processor.diameter = 10;
    [processor process];
    [input clearWithColor:LTVector4(0, 0, 0, 1)];
    [processor process];
    // If details texture is not updated, the result will not be zero.
    cv::Mat4b expected(1, 1, cv::Vec4b(0, 0, 0, 255));
    expect($(processor.outputTexture.image)).to.beCloseToMat($(expected));
  });

  it(@"should modify exposure correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(255, 170, 255, 255));
    processor.exposure = 1.0;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });

  it(@"should modify contrast correctly", ^{
    [input clearWithColor:LTVector4(1, 1, 1, 1)];
    processor.contrast = 1.0;
    [processor process];

    // Local contrast is pivoted around the content of image and should leave the constant input
    // unchanged.
    expect($(output.image)).to.beCloseToMat($(input.image));
  });
  
  it(@"should modify saturation correctly ", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(121, 121, 121, 255));
    processor.saturation = -1.0;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should modify hue correctly ", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(114, 159, 0, 255));
    processor.hue = 1.0;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });

  it(@"should disable range attenuation", ^{
    cv::Mat4b inputImage(1, 2, cv::Vec4b(0, 0, 0, 255));
    inputImage(0, 1) = cv::Vec4b(255, 255, 64, 255);
    input = [LTTexture textureWithImage:inputImage];
    output = [LTTexture textureWithPropertiesOf:input];
    processor = [[LTColorRangeAdjustProcessor alloc] initWithInput:input output:output];

    /// Despite the dissimilarity between the first and the second pixels, saturation on the second
    /// should be completely removed.
    cv::Mat4b expected(1, 2, cv::Vec4b(0, 0, 0, 255));
    expected(0, 1) = cv::Vec4b(241, 241, 241, 255);
    processor.saturation = -1.0;
    processor.diameter = 10;
    processor.disableRangeAttenuation = YES;
    [processor process];

    expect($(output.image)).to.beCloseToMatWithin($(expected), 2);
  });
});

context(@"masks", ^{
  beforeEach(^{
    processor.center = LTVector2(0, 0);
    processor.diameter = 10;
  });
  
  it(@"should render mask correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(255, 255, 255, 255));
    processor.renderingMode = LTColorRangeRenderingModeMask;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should render mask as overlay correctly ", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(255, 0, 0, 255));
    processor.renderingMode = LTColorRangeRenderingModeMaskOverlay;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
