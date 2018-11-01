// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTForegroundBackgroundDrawer.h"

#import "LTFbo.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "LTTextureDrawer.h"

SpecBegin(LTForegroundBackgroundDrawer)

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    id<LTTextureDrawer> foregroundDrawer = OCMProtocolMock(@protocol(LTTextureDrawer));
    id<LTTextureDrawer> backgroundDrawer = OCMProtocolMock(@protocol(LTTextureDrawer));

    LTForegroundBackgroundDrawer *drawer =
        [[LTForegroundBackgroundDrawer alloc] initWithForegroundDrawer:foregroundDrawer
                                                      backgroundDrawer:backgroundDrawer
                                                        foregroundRect:CGRectMake(0, 0, 2, 2)];

    expect(drawer.foregroundDrawer).to.beIdenticalTo(foregroundDrawer);
    expect(drawer.backgroundDrawer).to.beIdenticalTo(backgroundDrawer);
  });
});

context(@"drawing", ^{
  static const CGSize kInputSize = CGSizeMakeUniform(6);
  static const cv::Vec4b kForegroundColor1 (0, 0, 255, 255);
  static const cv::Vec4b kForegroundColor2 (0, 255, 0, 255);
  static const cv::Vec4b kBackgroundColor1 (255, 0, 0, 255);
  static const cv::Vec4b kBackgroundColor2 (255, 255, 255, 255);

  static const CGRect kSmallForegroundRect = CGRectMake(4, 4, 1, 1);
  static const CGRect kLargeForegroundRect = CGRectMake(3, 3, 3, 3);
  static const CGRect kMixedRect = CGRectMake(1, 1, 3, 3);
  static const CGRect kBackgroundRect = CGRectMake(0, 0, 3, 3);

  __block LTForegroundBackgroundDrawer *drawer;
  __block cv::Mat4b fullMixedImage;

  beforeEach(^{
    static const CGRect kForgroundRect = CGRectMake(3, 3, 3, 3);

    cv::Mat4b foregroundMat(kInputSize.height, kInputSize.width, kForegroundColor1);
    foregroundMat(1, 1) = kForegroundColor2;
    foregroundMat(1, 4) = kForegroundColor2;
    foregroundMat(4, 1) = kForegroundColor2;
    foregroundMat(4, 4) = kForegroundColor2;
    LTTexture *foreground = [LTTexture textureWithImage:foregroundMat];
    foreground.minFilterInterpolation = LTTextureInterpolationNearest;
    foreground.magFilterInterpolation = LTTextureInterpolationNearest;
    LTRectDrawer *foregroundDrawer = [[LTRectDrawer alloc] initWithSourceTexture:foreground];

    cv::Mat4b backgroundMat(kInputSize.height, kInputSize.width, kBackgroundColor1);
    backgroundMat(1, 1) = kBackgroundColor2;
    backgroundMat(1, 4) = kBackgroundColor2;
    backgroundMat(4, 1) = kBackgroundColor2;
    backgroundMat(4, 4) = kBackgroundColor2;
    LTTexture *background = [LTTexture textureWithImage:backgroundMat];
    background.minFilterInterpolation = LTTextureInterpolationNearest;
    background.magFilterInterpolation = LTTextureInterpolationNearest;
    LTRectDrawer *backgroundDrawer = [[LTRectDrawer alloc] initWithSourceTexture:background];

    fullMixedImage = backgroundMat.clone();
    foregroundMat(LTCVRectWithCGRect(kForgroundRect))
        .copyTo(fullMixedImage(LTCVRectWithCGRect(kForgroundRect)));

    drawer = [[LTForegroundBackgroundDrawer alloc] initWithForegroundDrawer:foregroundDrawer
                                                           backgroundDrawer:backgroundDrawer
                                                             foregroundRect:kForgroundRect];
  });

  afterEach(^{
    drawer = nil;
  });

  context(@"drawing to output with an equal size to the input size", ^{
    static const CGRect kTargetRect = CGRectMake(0, 0, 3, 3);

    __block LTTexture *output;
    __block LTFbo *outputFbo;
    __block cv::Mat4b expectedSmallForeground;
    __block cv::Mat4b expectedLargeForeground;
    __block cv::Mat4b expectedMixed;
    __block cv::Mat4b expectedBackground;

    beforeEach(^{
      output = [LTTexture byteRGBATextureWithSize:kTargetRect.size];
      outputFbo = [[LTFbo alloc] initWithTexture:output];

      expectedSmallForeground = fullMixedImage(LTCVRectWithCGRect(kSmallForegroundRect)).clone();
      expectedLargeForeground = fullMixedImage(LTCVRectWithCGRect(kLargeForegroundRect)).clone();
      expectedMixed = fullMixedImage(LTCVRectWithCGRect(kMixedRect)).clone();
      expectedBackground = fullMixedImage(LTCVRectWithCGRect(kBackgroundRect)).clone();
    });

    afterEach(^{
      output = nil;
      outputFbo = nil;
    });

    context(@"given framebuffer", ^{
      it(@"should draw foreground source rect correctly", ^{
        [drawer drawRect:kTargetRect inFramebuffer:outputFbo fromRect:kLargeForegroundRect];
        expect($([output image])).to.equalMat($(expectedLargeForeground));
      });

      it(@"should draw strictly contained foreground source rect correctly", ^{
        [drawer drawRect:CGRectMake(0, 0, 1, 1) inFramebuffer:outputFbo
                fromRect:kSmallForegroundRect];
        expect($([output image](cv::Rect(0, 0, 1, 1)))).to.equalMat($(expectedSmallForeground));
      });

      it(@"should draw a mix of foreground and background source rect correctly", ^{
        [drawer drawRect:kTargetRect inFramebuffer:outputFbo fromRect:kMixedRect];
        expect($([output image])).to.equalMat($(expectedMixed));
      });

      it(@"shoud draw background source rect correctly", ^{
        [drawer drawRect:kTargetRect inFramebuffer:outputFbo fromRect:kBackgroundRect];
        expect($([output image])).to.equalMat($(expectedBackground));
      });
    });

    context(@"bound framebuffer", ^{
      it(@"should draw foreground source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:kTargetRect inFramebufferWithSize:outputFbo.size
                  fromRect:kLargeForegroundRect];
        }];
        expect($([output image])).to.equalMat($(expectedLargeForeground));
      });

      it(@"should draw strictly contained foreground source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:CGRectMake(0, 0, 1, 1) inFramebufferWithSize:outputFbo.size
                  fromRect:kSmallForegroundRect];
        }];
        expect($([output image](cv::Rect(0, 0, 1, 1)))).to.equalMat($(expectedSmallForeground));
      });

      it(@"should draw a mix of foreground and background source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:kTargetRect inFramebufferWithSize:outputFbo.size fromRect:kMixedRect];
        }];
        expect($([output image])).to.equalMat($(expectedMixed));
      });

      it(@"shoud draw background source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:kTargetRect inFramebufferWithSize:outputFbo.size
                  fromRect:kBackgroundRect];
        }];
        expect($([output image])).to.equalMat($(expectedBackground));
      });
    });
  });

  context(@"drawing to output with a scaled size of the input size", ^{
    static const CGRect kTargetRect = CGRectMake(0, 0, 6, 6);

    __block LTTexture *output;
    __block LTFbo *outputFbo;
    __block cv::Mat4b expectedSmallForeground;
    __block cv::Mat4b expectedLargeForeground;
    __block cv::Mat4b expectedMixed;
    __block cv::Mat4b expectedBackground;

    beforeEach(^{
      output = [LTTexture byteRGBATextureWithSize:kTargetRect.size];
      outputFbo = [[LTFbo alloc] initWithTexture:output];

      expectedSmallForeground = fullMixedImage(LTCVRectWithCGRect(kSmallForegroundRect)).clone();
      expectedLargeForeground = fullMixedImage(LTCVRectWithCGRect(kLargeForegroundRect)).clone();
      expectedMixed = fullMixedImage(LTCVRectWithCGRect(kMixedRect)).clone();
      expectedBackground = fullMixedImage(LTCVRectWithCGRect(kBackgroundRect)).clone();
      cv::resize(expectedSmallForeground, expectedSmallForeground,
                 cv::Size(2, 2), 0, 0, cv::INTER_NEAREST);
      cv::resize(expectedLargeForeground, expectedLargeForeground,
                 cv::Size(6, 6), 0, 0, cv::INTER_NEAREST);
      cv::resize(expectedMixed, expectedMixed, cv::Size(6, 6), 0, 0, cv::INTER_NEAREST);
      cv::resize(expectedBackground, expectedBackground, cv::Size(6, 6), 0, 0, cv::INTER_NEAREST);
    });

    afterEach(^{
      output = nil;
      outputFbo = nil;
    });

    context(@"given framebuffer", ^{
      it(@"should draw foreground source rect correctly", ^{
        [drawer drawRect:kTargetRect inFramebuffer:outputFbo fromRect:kLargeForegroundRect];
        expect($([output image])).to.equalMat($(expectedLargeForeground));
      });

      it(@"should draw strictly contained foreground source rect correctly", ^{
        [drawer drawRect:CGRectMake(0, 0, 2, 2) inFramebuffer:outputFbo
                fromRect:kSmallForegroundRect];
        expect($([output image](cv::Rect(0, 0, 2, 2)))).to.equalMat($(expectedSmallForeground));
      });

      it(@"should draw a mix of foreground and background source rect correctly", ^{
        [drawer drawRect:kTargetRect inFramebuffer:outputFbo fromRect:kMixedRect];
        expect($([output image])).to.equalMat($(expectedMixed));
      });

      it(@"shoud draw background source rect correctly", ^{
        [drawer drawRect:kTargetRect inFramebuffer:outputFbo fromRect:kBackgroundRect];
        expect($([output image])).to.equalMat($(expectedBackground));
      });
    });

    context(@"bound framebuffer", ^{
      it(@"should draw foreground source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:kTargetRect inFramebufferWithSize:outputFbo.size
                  fromRect:kLargeForegroundRect];
        }];
        expect($([output image])).to.equalMat($(expectedLargeForeground));
      });

      it(@"should draw strictly contained foreground source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:CGRectMake(0, 0, 2, 2) inFramebufferWithSize:outputFbo.size
                  fromRect:kSmallForegroundRect];
        }];
        expect($([output image](cv::Rect(0, 0, 2, 2)))).to.equalMat($(expectedSmallForeground));
      });

      it(@"should draw a mix of foreground and background source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:kTargetRect inFramebufferWithSize:outputFbo.size fromRect:kMixedRect];
        }];
        expect($([output image])).to.equalMat($(expectedMixed));
      });

      it(@"shoud draw background source rect correctly", ^{
        [outputFbo bindAndDraw:^{
          [drawer drawRect:kTargetRect inFramebufferWithSize:outputFbo.size
                  fromRect:kBackgroundRect];
        }];
        expect($([output image])).to.equalMat($(expectedBackground));
      });
    });
  });
});

SpecEnd
