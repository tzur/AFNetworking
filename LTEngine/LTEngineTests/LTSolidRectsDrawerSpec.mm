// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTSolidRectsDrawer.h"

#import "LTFbo.h"
#import "LTOpenCVExtensions.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

SpecBegin(LTSolidRectsDrawer)

static const CGSize kTextureSize = CGSizeMakeUniform(20);

__block LTTexture *outputTexture;
__block LTFbo *target;

beforeEach(^{
  outputTexture = [LTTexture byteRGBATextureWithSize:kTextureSize];
  [outputTexture clearColor:LTVector4(0, 0, 1, 1)];
  target = [[LTFbo alloc] initWithTexture:outputTexture];
});

afterEach(^{
  target = nil;
  outputTexture = nil;
});

context(@"regular rects", ^{
  __block NSArray<LTRotatedRect *> *rects;

  beforeEach(^{
    rects = @[[LTRotatedRect rect:CGRectMake(1, 4, 4, 6)],
              [LTRotatedRect rect:CGRectMake(13, 4, 6, 3)],
              [LTRotatedRect rect:CGRectMake(8, 13, 10, 4)]];
  });

  it(@"should draw regular rects correctly", ^{
    LTSolidRectsDrawer *rectsDrawer =
        [[LTSolidRectsDrawer alloc] initWithFillColor:LTVector4::ones()];
    [rectsDrawer drawRotatedRects:rects inFramebuffer:target];

    cv::Mat expectedImage = LTLoadMat([self class], @"SolidRectsDrawerRegularRects.png");
    expect($(outputTexture.image)).to.equalMat($(expectedImage));
  });

  it(@"should use the correct fill color", ^{
    LTSolidRectsDrawer *rectsDrawer =
        [[LTSolidRectsDrawer alloc] initWithFillColor:LTVector4(1, 0, 0, 1)];
    [rectsDrawer drawRotatedRects:rects inFramebuffer:target];

    cv::Mat expectedImage = LTLoadMat([self class], @"SolidRectsDrawerRegularRectsRed.png");
    expect($(outputTexture.image)).to.equalMat($(expectedImage));
  });
});

context(@"rotated rects", ^{
  __block NSArray<LTRotatedRect *> *rects;

  beforeEach(^{
    LTRotatedRect *rect1 = [LTRotatedRect rectWithCenter:CGPointMake(5, 6)
                                                    size:CGSizeMake(4, 6) angle:(M_PI_4)];
    LTRotatedRect *rect2 = [LTRotatedRect rect:CGRectMake(12, 9, 5, 4)];
    LTRotatedRect *rect3 = [LTRotatedRect rectWithCenter:CGPointMake(6, 15)
                                                    size:CGSizeMake(6, 2) angle:(M_PI_4)];

    rects = @[rect1, rect2, rect3];
  });

  it(@"should draw rotated rects correctly", ^{
    LTSolidRectsDrawer *rectsDrawer =
        [[LTSolidRectsDrawer alloc] initWithFillColor:LTVector4::ones()];
    [rectsDrawer drawRotatedRects:rects inFramebuffer:target];

    cv::Mat expectedImage = LTLoadMat([self class], @"SolidRectsDrawerRotatedRects.png");

    expect($(outputTexture.image)).to.equalMat($(expectedImage));
  });

  it(@"should use the correct fill color", ^{
    LTSolidRectsDrawer *rectsDrawer =
        [[LTSolidRectsDrawer alloc] initWithFillColor:LTVector4(1, 0, 0, 1)];
    [rectsDrawer drawRotatedRects:rects inFramebuffer:target];

    cv::Mat expectedImage = LTLoadMat([self class], @"SolidRectsDrawerRotatedRectsRed.png");
    expect($(outputTexture.image)).to.equalMat($(expectedImage));
  });
});

context(@"overlapping rects", ^{
  it(@"should draw overlapping rects correctly and without any issues", ^{
    LTSolidRectsDrawer *rectsDrawer =
        [[LTSolidRectsDrawer alloc] initWithFillColor:LTVector4::ones()];

    NSArray<LTRotatedRect *> *rects = @[[LTRotatedRect rect:CGRectMake(3, 3, 12, 4)],
                                        [LTRotatedRect rect:CGRectMake(11, 2, 7, 14)]];
    [rectsDrawer drawRotatedRects:rects inFramebuffer:target];

    cv::Mat expectedImage = LTLoadMat([self class], @"SolidRectsDrawerOverlappingRects.png");
    expect($(outputTexture.image)).to.equalMat($(expectedImage));
  });
});

context(@"out of bounds rects", ^{
  it(@"should draw out of bounds rects correctly and without any issues", ^{
    LTSolidRectsDrawer *rectsDrawer =
        [[LTSolidRectsDrawer alloc] initWithFillColor:LTVector4::ones()];
    NSArray<LTRotatedRect *> *rects = @[[LTRotatedRect rect:CGRectMake(-3, -3, 7, 9)],
                                        [LTRotatedRect rect:CGRectMake(14, 16, 8, 5)],
                                        [LTRotatedRect rect:CGRectMake(2, 14, 3, 9)]];
    [rectsDrawer drawRotatedRects:rects inFramebuffer:target];

    cv::Mat expectedImage = LTLoadMat([self class], @"SolidRectsDrawerOutOfBoundsRects.png");
    expect($(outputTexture.image)).to.equalMat($(expectedImage));
  });
});

SpecEnd
