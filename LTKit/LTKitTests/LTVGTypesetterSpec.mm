// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGTypesetter.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTVGGlyph.h"
#import "LTVGGlyphRun.h"
#import "LTVGLine.h"
#import "LTVGLines.h"

LTSpecBegin(LTVGTypesetter)

__block NSAttributedString *attributedString;
__block LTVGLines *lines;

beforeEach(^{
  attributedString = [[NSAttributedString alloc] initWithString:@"$AB\ncd\nF"];
  lines = [LTVGTypesetter linesFromAttributedString:attributedString];
});

it(@"should create glyphs", ^{
  UIFont *font = [UIFont fontWithName:@"Arial" size:10];
  CGPoint baselineOrigin = CGPointMake(1, 2);
  LTVGGlyph *glyph = [LTVGTypesetter glyphWithIndex:7 font:font baselineOrigin:baselineOrigin];
  expect(glyph).toNot.beNil();
  expect(glyph.path).toNot.beNil();
  expect(glyph.font).to.equal(font);
  expect(glyph.baselineOrigin).to.equal(baselineOrigin);
});

it(@"should create lines", ^{
  expect(lines).toNot.beNil();
  expect(lines.lines.count).to.equal(3);
  expect(((LTVGLine *)lines.lines[0]).glyphRuns.count).to.equal(1);
  expect(((LTVGLine *)lines.lines[1]).glyphRuns.count).to.equal(1);
  expect(((LTVGLine *)lines.lines[2]).glyphRuns.count).to.equal(1);
  NSArray *glyphs = ((LTVGGlyphRun *)((LTVGLine *)lines.lines[0]).glyphRuns[0]).glyphs;
  expect(glyphs.count).to.equal(4);
  expect(((LTVGGlyph *)glyphs[0]).glyphIndex).to.equal(7);
  expect(((LTVGGlyph *)glyphs[1]).glyphIndex).to.equal(36);
  expect(((LTVGGlyph *)glyphs[2]).glyphIndex).to.equal(37);
  expect(((LTVGGlyph *)glyphs[3]).glyphIndex).to.equal(2);
  expect(lines.attributedString).to.equal(attributedString);
});

context(@"path", ^{
  __block CAShapeLayer *shapeLayer;

  beforeEach(^{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
  });

  it(@"should create lines with correct path", ^{
    CGPathRef path = [lines newPathWithLeadingFactor:0 trackingFactor:0];
    CGAffineTransform translation = CGAffineTransformMakeTranslation(0, 9);
    CGPathRef translatedPath = CGPathCreateCopyByTransformingPath(path, &translation);
    shapeLayer.path = translatedPath;
    CGPathRelease(path);
    CGPathRelease(translatedPath);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(23, 36), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"FramesetterTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });
});

LTSpecEnd
