// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGLine.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTVGGlyph.h"
#import "LTVGGlyphRun.h"
#import "LTVGTypesetter.h"

static const CGFloat kEpsilon = 1e-6;

SpecBegin(LTVGLine)

__block UIFont *font;
__block CGPoint baselineOrigin;
__block LTVGGlyph *glyph;
__block LTVGGlyphRun *run;
__block LTVGGlyphRun *anotherRun;
__block NSArray *runs;
__block LTVGLine *line;

beforeEach(^{
  font = [UIFont fontWithName:@"Arial" size:10];
  baselineOrigin = CGPointMake(0, 8);
  glyph = [LTVGTypesetter glyphWithIndex:7 font:font baselineOrigin:baselineOrigin];
  LTVGGlyph *anotherGlyph =
      [LTVGTypesetter glyphWithIndex:8 font:font baselineOrigin:baselineOrigin + CGPointMake(6, 0)];
  run = [[LTVGGlyphRun alloc] initWithGlyphs:@[glyph, anotherGlyph]];
  glyph = [LTVGTypesetter glyphWithIndex:8 font:[UIFont fontWithName:@"Helvetica" size:10]
                          baselineOrigin:baselineOrigin + CGPointMake(15, 0)];
  anotherRun = [[LTVGGlyphRun alloc] initWithGlyphs:@[glyph]];
  runs = @[run, anotherRun];
  line = [[LTVGLine alloc] initWithGlyphRuns:runs];
});

context(@"initialization", ^{
  it(@"should initialize with correct values", ^{
    expect(line.glyphRuns).to.equal(runs);
    expect(line.baselineOrigin).to.equal(baselineOrigin);
    expect(line.lineHeight).to.beCloseToWithin(11.5, kEpsilon);
  });

  it(@"should raise when initializing with invalid runs", ^{
    expect(^{
      line = [[LTVGLine alloc] initWithGlyphRuns:nil];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      line = [[LTVGLine alloc] initWithGlyphRuns:@[@1]];
    }).to.raise(NSInvalidArgumentException);

    LTVGGlyph *glyphWithInvalidBaselineOrigin =
        [[LTVGGlyph alloc] initWithPath:NULL glyphIndex:8 font:font
                         baselineOrigin:baselineOrigin + CGPointMake(0, 1)];
    anotherRun = [[LTVGGlyphRun alloc] initWithGlyphs:@[glyphWithInvalidBaselineOrigin]];
    expect(^{
      line = [[LTVGLine alloc] initWithGlyphRuns:@[run, anotherRun]];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"NSObject", ^{
  it(@"should correctly implement the isEqual method", ^{
    expect([line isEqual:nil]).to.beFalsy();
    expect([line isEqual:@1]).to.beFalsy();
    expect([line isEqual:[[LTVGLine alloc] init]]).to.beFalsy();
    expect([line isEqual:line]).to.beTruthy();

    LTVGLine *equalLine = [[LTVGLine alloc] initWithGlyphRuns:@[run, anotherRun]];
    expect([line isEqual:equalLine]).to.beTruthy();

    LTVGLine *differentLine = [[LTVGLine alloc] initWithGlyphRuns:@[run, run]];
    expect([line isEqual:differentLine]).to.beFalsy();
  });
});

context(@"path", ^{
  __block CAShapeLayer *shapeLayer;

  beforeEach(^{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
  });
  
  it(@"should create a correct path", ^{
    CGPathRef path = [line newPathWithTrackingFactor:0];
    shapeLayer.path = path;
    CGPathRelease(path);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(25, 9), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"LineTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });

  it(@"should create a correct path with non-zero tracking", ^{
    CGPathRef path = [line newPathWithTrackingFactor:1];
    shapeLayer.path = path;
    CGPathRelease(path);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(45, 9), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"LineTrackingTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });
});

SpecEnd
