// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorRangeAdjustProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"

LTSpecBegin(TColorRangeAdjustProcessor)

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
  it(@"should return default tone properties correctly", ^{
    expect(processor.rangeColor).to.equal(LTVector3(0, 1, 0));
    expect(processor.fuzziness).to.equal(0);
    expect(processor.saturation).to.equal(0);
    expect(processor.luminance).to.equal(0);
    expect(processor.hue).to.equal(0);
  });
  
  it(@"should fail on incorrect input", ^{
    expect(^{
      processor.rangeColor = LTVector3(1.1, 0, 0);
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.fuzziness = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.saturation = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.luminance = -1.1;
    }).to.raise(NSInvalidArgumentException);
    expect(^{
      processor.hue = 1.1;
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should not fail on correct tone input", ^{
    expect(^{
      processor.rangeColor = LTVector3(1, 0, 0);
      processor.fuzziness = -1.0;
      processor.saturation = -1.0;
      processor.luminance = -1.0;
      processor.hue = 1.0;
    }).toNot.raiseAny();
  });
});

context(@"processing", ^{
  beforeEach(^{
    processor.rangeColor = LTVector3(0.502, 0.251, 1);
  });
  
  it(@"should modify luminance correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(255, 255, 255, 255));
    processor.luminance = 1.0;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should modify saturation correctly ", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(105, 105, 105, 255));
    processor.saturation = -1.0;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should modify hue correctly ", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(247, 128, 72, 255));
    processor.hue = 1.0;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
});

context(@"rendering", ^{
  beforeEach(^{
    processor.rangeColor = LTVector3(0.502, 0.251, 1);
  });
  
  it(@"should render mask correctly", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(255, 255, 255, 255));
    processor.renderingMode = LTColorRangeRenderingModeMask;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
  
  it(@"should render mask as overlay correctly ", ^{
    cv::Mat4b expected(1, 1, cv::Vec4b(128, 64, 255, 255));
    processor.renderingMode = LTColorRangeRenderingModeMaskOverlay;
    [processor process];
    
    expect($(output.image)).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
