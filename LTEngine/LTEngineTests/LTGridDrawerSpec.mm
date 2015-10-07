// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGridDrawer.h"

#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLTexture.h"

/// Fills the given mat with baseColor, and then blend the given color on its border, double
/// blending the corners if necessary.
static void LTBlendBorder(cv::Mat4b mat, const cv::Vec4b &baseColor, const cv::Vec4b &color,
                          BOOL doubleBlendCorners = YES) {
  // Replace the mat borders with the blend of the base color and the given color.
  cv::Vec4b blended = LTBlend(baseColor, color);
  mat = baseColor;
  mat.row(0) = blended;
  mat.row(mat.rows - 1) = blended;
  mat.col(0) = blended;
  mat.col(mat.cols - 1) = blended;

  // Replace the corners with double blending, if necessary.
  if (doubleBlendCorners) {
    cv::Vec4b blended2 = LTBlend(blended, color);
    mat(0,0) = blended2;
    mat(0, mat.cols - 1) = blended2;
    mat(mat.rows - 1, 0) = blended2;
    mat(mat.rows - 1, mat.cols - 1) = blended2;
  }
}

SpecBegin(LTGridDrawerSpec)

beforeEach(^{
  LTGLContext *context = [LTGLContext currentContext];

  // Make sure that everything is properly drawn when face culling is enabled, and with a normal
  // blending mode.
  context.faceCullingEnabled = YES;
  context.blendEnabled = YES;
  context.blendEquation = kLTGLContextBlendEquationDefault;
  context.blendFunc = kLTGLContextBlendFuncNormal;
});

context(@"initialization", ^{
  it(@"Should initialize with a proper size", ^{
    expect(^{
      __unused LTGridDrawer *grid = [[LTGridDrawer alloc] initWithSize:CGSizeMake(256, 256)];
    }).toNot.raiseAny();
  });
});

context(@"drawing", ^{
  __block LTFbo *fbo;
  __block LTTexture *output;
  __block LTGridDrawer *gridDrawer;
  
  const CGSize kFramebufferSize = CGSizeMake(128, 128);
  const cv::Vec4b kBlack(0, 0, 0, UCHAR_MAX);
  const cv::Vec4b kWhite(UCHAR_MAX, UCHAR_MAX, UCHAR_MAX, UCHAR_MAX);
  const cv::Vec4b kRed(UCHAR_MAX, 0, 0, UCHAR_MAX);
  const cv::Vec4b kGray(128, 128, 128, 128);
  
  __block cv::Mat4b expected(kFramebufferSize.height, kFramebufferSize.width);
  
  beforeEach(^{
    output = [[LTGLTexture alloc] initWithSize:kFramebufferSize
                                      precision:LTTexturePrecisionByte
                                        format:LTTextureFormatRGBA
                                 allocateMemory:YES];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
    expected = kBlack;
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    gridDrawer = nil;
  });
  
  context(@"grid correctness", ^{
    beforeEach(^{
      expected.row(0) = kWhite;
      expected.row(expected.rows - 1) = kWhite;
      expected.col(0) = kWhite;
      expected.col(expected.cols - 1) = kWhite;
    });
    
    it(@"should draw a single pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw the top left 1x1 subregion of a 2x2 pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(2, 2)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw the bottom right 1x1 subregion of a 2x2 pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(2, 2)];
      [gridDrawer drawSubGridInRegion:CGRectMake(1, 1, 1, 1) inFramebuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw a 1x1 centered subregion of a 2x2 pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(2, 2)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0.5, 0.5, 1, 1) inFramebuffer:fbo];

      expected = kBlack;
      expected.row(expected.rows / 2) = kWhite;
      expected.row(expected.rows / 2 - 1) = kWhite;
      expected.col(expected.cols / 2) = kWhite;
      expected.col(expected.cols / 2 - 1) = kWhite;

      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw a grid with half the size of the framebuffer (covering all pixels)", ^{
      CGSize halfSize = CGSizeMake(kFramebufferSize.width / 2, kFramebufferSize.height / 2);
      gridDrawer = [[LTGridDrawer alloc] initWithSize:halfSize];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, halfSize.width, halfSize.height)
                        inFramebuffer:fbo];
      
      expected = kWhite;
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw a small subregion of a grid larger than the target framebuffer", ^{
      const CGFloat kRegionFactor = 10;
      CGSize regionSize = CGSizeMake(kFramebufferSize.width / kRegionFactor,
                                     kFramebufferSize.height / kRegionFactor);
      CGSize doubleSize = CGSizeMake(kFramebufferSize.width * 2, kFramebufferSize.height * 2);
      gridDrawer = [[LTGridDrawer alloc] initWithSize:doubleSize];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, regionSize.width, regionSize.height)
                        inFramebuffer:fbo];
      
      expected = kBlack;
      for (int row = 0; row < expected.rows; row += kRegionFactor) {
        expected.row(row) = kWhite;
        if (row + kRegionFactor - 1 < expected.rows) {
          expected.row(row + kRegionFactor - 1) = kWhite;
        }
      }
      for (int col = 0; col < expected.cols; col += kRegionFactor) {
        expected.col(col) = kWhite;
        if (col + kRegionFactor - 1 < expected.cols) {
          expected.col(col + kRegionFactor - 1) = kWhite;
        }
      }
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });

  context(@"rendering targets", ^{
    beforeEach(^{
      expected.row(0) = kWhite;
      expected.row(expected.rows - 1) = kWhite;
      expected.col(0) = kWhite;
      expected.col(expected.cols - 1) = kWhite;
    });
    
    it(@"should draw on a framebuffer object", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw on a screen framebuffer", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      [fbo bindAndDrawOnScreen:^{
        [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebufferWithSize:fbo.size];
      }];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });
  
  context(@"draw-affecting properties", ^{
    beforeEach(^{
      [fbo clearWithColor:LTCVVec4bToLTVector4(kGray)];
      expected = kGray;
    });
    
    it(@"should draw with a custom RGBA color", ^{
      cv::Vec4b rgba(10, 20, 30, 40);
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.color = LTCVVec4bToLTVector4(rgba);
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      LTBlendBorder(expected, kGray, rgba);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw with a custom opacity", ^{
      const CGFloat kOpacity = 0.25;
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.opacity = kOpacity;
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      LTBlendBorder(expected, kGray, kOpacity * kWhite);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw with custom color and custom opacity", ^{
      cv::Vec4b rgba(16, 32, 64, 128);
      const CGFloat kOpacity = 0.5;
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.color = LTCVVec4bToLTVector4(rgba);
      gridDrawer.opacity = kOpacity;
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      LTBlendBorder(expected, kGray, kOpacity * rgba);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw with a custom width", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.width = 3.0;
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFramebuffer:fbo];
      for (NSUInteger i = 0; i < gridDrawer.width; ++i) {
        expected.row((int)i) = kWhite;
        expected.row(expected.rows - 1 - (int)i) = kWhite;
        expected.col((int)i) = kWhite;
        expected.col(expected.cols - 1 - (int)i) = kWhite;
      }
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });
});

SpecEnd
