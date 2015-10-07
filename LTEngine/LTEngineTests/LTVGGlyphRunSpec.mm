// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGGlyphRun.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTVGGlyph.h"
#import "LTVGGlyphRun.h"
#import "LTVGTypesetter.h"

SpecBegin(LTVGGlyphRun)

__block UIFont *font;
__block CGPoint baselineOrigin;
__block LTVGGlyph *glyph;
__block LTVGGlyph *anotherGlyph;
__block NSArray *glyphs;
__block LTVGGlyphRun *run;

beforeEach(^{
  font = [UIFont fontWithName:@"Arial" size:10];
  baselineOrigin = CGPointMake(0, 8);
  glyph = [LTVGTypesetter glyphWithIndex:7 font:font baselineOrigin:baselineOrigin];
  anotherGlyph = [LTVGTypesetter glyphWithIndex:8 font:font
                                 baselineOrigin:baselineOrigin + CGPointMake(6, 0)];
  glyphs = @[glyph, anotherGlyph];
  run = [[LTVGGlyphRun alloc] initWithGlyphs:glyphs];
});

context(@"initialization", ^{
  it(@"should initialize with correct values", ^{
    expect(run.glyphs).to.equal(glyphs);
    expect(run.font).to.equal(font);
    expect(run.baselineOrigin).to.equal(baselineOrigin);
  });

  it(@"should raise when initializing with invalid glyphs", ^{
    expect(^{
      run = [[LTVGGlyphRun alloc] initWithGlyphs:nil];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      run = [[LTVGGlyphRun alloc] initWithGlyphs:@[]];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      run = [[LTVGGlyphRun alloc] initWithGlyphs:@[@1]];
    }).to.raise(NSInvalidArgumentException);

    LTVGGlyph *glyphWithDifferentFont =
        [[LTVGGlyph alloc] initWithPath:NULL glyphIndex:8
                                   font:[UIFont fontWithName:@"Helvetica" size:10]
                         baselineOrigin:baselineOrigin];
    expect(^{
      run = [[LTVGGlyphRun alloc] initWithGlyphs:@[glyph, glyphWithDifferentFont]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"NSObject", ^{
  it(@"should correctly implement the isEqual method", ^{
    expect([run isEqual:nil]).to.beFalsy();
    expect([run isEqual:@1]).to.beFalsy();
    expect([run isEqual:[[LTVGGlyphRun alloc] init]]).to.beFalsy();
    expect([run isEqual:run]).to.beTruthy();

    LTVGGlyphRun *equalRun = [[LTVGGlyphRun alloc] initWithGlyphs:[glyphs copy]];
    expect([run isEqual:equalRun]).to.beTruthy();

    LTVGGlyphRun *differentRun = [[LTVGGlyphRun alloc] initWithGlyphs:@[glyph, glyph]];
    expect([run isEqual:differentRun]).to.beFalsy();

    NSArray *differentGlyphs =
        @[[[LTVGGlyph alloc] initWithPath:NULL glyphIndex:7
                                     font:[UIFont fontWithName:@"Arial" size:1]
                           baselineOrigin:CGPointZero]];
    differentRun = [[LTVGGlyphRun alloc] initWithGlyphs:differentGlyphs];
    expect([run isEqual:differentRun]).to.beFalsy();
  });
});

context(@"path", ^{
  __block CAShapeLayer *shapeLayer;

  beforeEach(^{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
  });

  it(@"should create a correct path", ^{
    CGPathRef path = [run newPathWithTrackingFactor:0];
    shapeLayer.path = path;
    CGPathRelease(path);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 9), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"GlyphRunTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });

  it(@"should create a correct path with non-zero tracking", ^{
    CGPathRef path = [run newPathWithTrackingFactor:1];
    shapeLayer.path = path;
    CGPathRelease(path);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(25, 9), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"GlyphRunTrackingTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });
});

SpecEnd
