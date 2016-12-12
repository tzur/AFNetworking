// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNBrushTips.h"

#import <LTEngine/LTOpenCVExtensions.h>
#import <LTEngine/LTTexture+Factory.h>
#import <LTEngine/LTGLTexture.h>

SpecBegin(DVNBrushTips)

context(@"round tip", ^{
  context(@"invalid arguments", ^{
    it(@"should raise when attempting to call with dimension that is not power of 2", ^{
      expect(^{
        LTGLTexture __unused *tip = [DVNBrushTips roundTipWithDimension:13 hardness:0];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when attempting to call with dimension that is less than 16", ^{
      expect(^{
        LTGLTexture __unused *tip = [DVNBrushTips roundTipWithDimension:8 hardness:0];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should raise when attempting to call with hardness that is out of [0, 1] range", ^{
      expect(^{
        LTGLTexture __unused *tip = [DVNBrushTips roundTipWithDimension:16 hardness:1.5];
      }).to.raise(NSInvalidArgumentException);
    });
  });
  
  it(@"should return correct brush tip mat", ^{
    NSUInteger dimension = 64;
    LTGLTexture *texture = [DVNBrushTips roundTipWithDimension:dimension hardness:0.75];
    expect(texture.pixelFormat).to.equal($(LTGLPixelFormatR16Float));
    
    for (NSUInteger i = 0; i < 3; ++i) {
      cv::Mat tipAtLevel = [texture imageAtLevel:i];
      int expectedDimension = dimension / pow(2, i);
      cv::Mat1b convertedGray(expectedDimension, expectedDimension);
      cv::Mat4b convertedRGBA(expectedDimension, expectedDimension);
      LTConvertHalfFloat<half_float::half, uchar>(tipAtLevel, &convertedGray, 255);
      cv::cvtColor(convertedGray, convertedRGBA, CV_GRAY2RGBA);
      NSString *filename =
          [NSString stringWithFormat:@"DVNBrushTipsRound%dHardness75.png", expectedDimension];
      
      expect(tipAtLevel.rows).to.equal(expectedDimension);
      expect(tipAtLevel.cols).to.equal(expectedDimension);
      expect($(convertedRGBA)).to.equalMat($(LTLoadMat([self class], filename)));
    }
  });
});

SpecEnd
