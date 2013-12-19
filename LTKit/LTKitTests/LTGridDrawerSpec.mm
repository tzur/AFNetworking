// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTGridDrawer.h"

#import <GLKit/GLKit.h>

#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTTestUtils.h"

SpecBegin(LTGridDrawerSpec)

beforeEach(^{
  EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [EAGLContext setCurrentContext:context];
  glEnable(GL_CULL_FACE);
});

afterEach(^{
  [EAGLContext setCurrentContext:nil];
  glDisable(GL_CULL_FACE);
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
  
  CGSize framebufferSize = CGSizeMake(128,128);
  cv::Vec4b black(0, 0, 0, UCHAR_MAX);
  cv::Vec4b white(UCHAR_MAX, UCHAR_MAX, UCHAR_MAX, UCHAR_MAX);
  cv::Vec4b red(UCHAR_MAX, 0, 0, UCHAR_MAX);
  cv::Vec4b gray(128, 128, 128, 128);
  
  __block cv::Mat4b expected(framebufferSize.height, framebufferSize.width);
  
  beforeEach(^{
    output = [[LTGLTexture alloc] initWithSize:framebufferSize
                                      precision:LTTexturePrecisionByte
                                       channels:LTTextureChannelsRGBA
                                 allocateMemory:YES];
    fbo = [[LTFbo alloc] initWithTexture:output];
    [fbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
    expected = black;
  });
  
  afterEach(^{
    fbo = nil;
    output = nil;
    gridDrawer = nil;
  });
  
  context(@"grid correctness", ^{
    beforeEach(^{
      expected.row(0) = white;
      expected.row(expected.rows - 1) = white;
      expected.col(0) = white;
      expected.col(expected.cols - 1) = white;
    });
    
    it(@"should draw a single pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw the top left 1x1 subregion of a 2x2 pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(2, 2)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw the bottom right 1x1 subregion of a 2x2 pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(2, 2)];
      [gridDrawer drawSubGridInRegion:CGRectMake(1, 1, 1, 1) inFrameBuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw a 1x1 centered subregion of a 2x2 pixel grid", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(2, 2)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0.5, 0.5, 1, 1) inFrameBuffer:fbo];

      expected = black;
      expected.row(expected.rows / 2) = white;
      expected.row(expected.rows / 2 - 1) = white;
      expected.col(expected.cols / 2) = white;
      expected.col(expected.cols / 2 - 1) = white;

      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw a grid with half the size of the framebuffer (covering all pixels)", ^{
      CGSize halfSize = CGSizeMake(framebufferSize.width / 2, framebufferSize.height / 2);
      gridDrawer = [[LTGridDrawer alloc] initWithSize:halfSize];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, halfSize.width, halfSize.height)
                        inFrameBuffer:fbo];
      
      expected = white;
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw a small subregion of a grid larger than the target framebuffer", ^{
      CGFloat regionFactor = 10;
      CGSize regionSize =
          CGSizeMake(framebufferSize.width / regionFactor, framebufferSize.height / regionFactor);
      CGSize doubleSize = CGSizeMake(framebufferSize.width * 2, framebufferSize.height * 2);
      gridDrawer = [[LTGridDrawer alloc] initWithSize:doubleSize];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, regionSize.width, regionSize.height)
                        inFrameBuffer:fbo];
      
      expected = black;
      for (int row = 0; row < expected.rows; row += regionFactor) {
        expected.row(row) = white;
        if (row + regionFactor - 1 < expected.rows) {
          expected.row(row + regionFactor - 1) = white;
        }
      }
      for (int col = 0; col < expected.cols; col += regionFactor) {
        expected.col(col) = white;
        if (col + regionFactor - 1 < expected.cols) {
          expected.col(col + regionFactor - 1) = white;
        }
      }
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });

  context(@"rendering targets", ^{
    beforeEach(^{
      expected.row(0) = white;
      expected.row(expected.rows - 1) = white;
      expected.col(0) = white;
      expected.col(expected.cols - 1) = white;
    });
    it(@"should draw on a framebuffer object", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    it(@"should draw on an anonymous target", ^{
      [fbo bindAndExecute:^{
        gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
        [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBufferWithSize:fbo.size];
      }];
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });
  
  context(@"custom properties", ^{
    CGFloat inv = 1.0 / UCHAR_MAX;
    void (^blendBlock)(cv::Mat4b &mat, cv::Vec4b base, cv::Vec4b color) =
        ^void (cv::Mat4b &mat, cv::Vec4b base, cv::Vec4b color) {
      // Blending should match photoshop's "normal" blend mode, assuming input is premultiplied:
      // C_out = C_new + (1-A_new)*C_old;
      // A_out = A_old + (1-A_old)*A_new;
      // Note that the corner pixels are double blended, as two grid lines cross there.
      cv::Vec4b blended;
      cv::Vec4b blended2;
      cv::Vec4b alpha;
      cv::Vec4b alpha2;
      cv::addWeighted(base, 1.0 - inv * color[3], color, 1.0, 0.0, blended);
      cv::addWeighted(base, 1.0, color, 1 - inv * base[3], 0.0, alpha);
      blended[3] = alpha[3];
      cv::addWeighted(blended, 1.0 - inv * color[3], color, 1.0, 0.0, blended2);
      cv::addWeighted(blended, 1.0, color, 1 - inv * blended[3], 0.0, alpha2);
      blended2[3] = alpha2[3];
      mat = base;
      mat.row(0) = blended;
      mat.row(mat.rows - 1) = blended;
      mat.col(0) = blended;
      mat.col(mat.cols - 1) = blended;
      mat(0,0) = blended2;
      mat(0, mat.cols - 1) = blended2;
      mat(mat.rows - 1, 0) = blended2;
      mat(mat.rows - 1, mat.cols - 1) = blended2;
    };
    beforeEach(^{
      [fbo clearWithColor:LTCVVec4bToGLKVector4(gray)];
      expected = gray;
    });
    it(@"should draw with a custom RGBA color", ^{
      cv::Vec4b rgba(10, 20, 30, 40);
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.color = [UIColor colorWithRed:rgba[0] * inv green:rgba[1] * inv
                                          blue:rgba[2] * inv alpha:rgba[3] * inv];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      blendBlock(expected, gray, rgba);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw with a custom grayscale color", ^{
      CGFloat w = 50;
      CGFloat a = 120;
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.color = [UIColor colorWithWhite:w * inv alpha:a * inv];
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      blendBlock(expected, gray, cv::Vec4b(w, w, w, a));
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw with a custom opacity", ^{
      CGFloat opacity = 0.2;
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.opacity = opacity;
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      blendBlock(expected, gray, opacity * white);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });

    it(@"should draw with custom color and custom opacity", ^{
      cv::Vec4b rgba(10, 20, 30, 80);
      CGFloat opacity = 0.7;
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.color = [UIColor colorWithRed:rgba[0] * inv green:rgba[1] * inv
                                          blue:rgba[2] * inv alpha:rgba[3] * inv];
      gridDrawer.opacity = opacity;
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      blendBlock(expected, gray, opacity * rgba);
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
    
    it(@"should draw with a custom width", ^{
      gridDrawer = [[LTGridDrawer alloc] initWithSize:CGSizeMake(1, 1)];
      gridDrawer.width = 3.0;
      [gridDrawer drawSubGridInRegion:CGRectMake(0, 0, 1, 1) inFrameBuffer:fbo];
      for (NSUInteger i = 0; i < gridDrawer.width; ++i) {
        expected.row((int)i) = white;
        expected.row(expected.rows - 1 - (int)i) = white;
        expected.col((int)i) = white;
        expected.col(expected.cols - 1 - (int)i) = white;
      }
      expect(LTCompareMat(expected, output.image)).to.beTruthy();
    });
  });
});

SpecEnd
