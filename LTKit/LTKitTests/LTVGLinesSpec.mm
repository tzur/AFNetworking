// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGLines.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTVGGlyph.h"
#import "LTVGGlyphRun.h"
#import "LTVGLine.h"
#import "LTVGTypesetter.h"

LTSpecBegin(LTVGLines)

__block NSArray *linesArray;
__block LTVGLine *line;
__block LTVGLines *lines;
__block NSAttributedString *attributedString;

beforeEach(^{
  CGPoint baselineOrigin = CGPointMake(0, 8);
  UIFont *font = [UIFont fontWithName:@"Arial" size:10];
  LTVGGlyph *glyph = [LTVGTypesetter glyphWithIndex:7 font:font baselineOrigin:baselineOrigin];
  LTVGGlyph *anotherGlyph =
      [LTVGTypesetter glyphWithIndex:8 font:font baselineOrigin:baselineOrigin + CGPointMake(6, 0)];
  LTVGGlyphRun *run = [[LTVGGlyphRun alloc] initWithGlyphs:@[glyph, anotherGlyph]];
  line = [[LTVGLine alloc] initWithGlyphRuns:@[run]];
  anotherGlyph =
      [LTVGTypesetter glyphWithIndex:8 font:font baselineOrigin:baselineOrigin + CGPointMake(0, 9)];
  run = [[LTVGGlyphRun alloc] initWithGlyphs:@[anotherGlyph]];
  LTVGLine *anotherLine = [[LTVGLine alloc] initWithGlyphRuns:@[run]];
  linesArray = @[line, anotherLine];
  attributedString = [[NSAttributedString alloc] init];
  lines = [[LTVGLines alloc] initWithLines:linesArray attributedString:attributedString];
});

context(@"initialization", ^{
  it(@"should initialize with correct values", ^{
    expect(lines.lines).to.equal(linesArray);
    expect(lines.attributedString).to.equal(attributedString);
  });

  it(@"should raise when initializing with invalid lines", ^{
    expect(^{
      lines = [[LTVGLines alloc] initWithLines:nil
                              attributedString:[[NSAttributedString alloc] init]];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      lines = [[LTVGLines alloc] initWithLines:@[]
                              attributedString:[[NSAttributedString alloc] init]];
    }).to.raise(NSInvalidArgumentException);

    expect(^{
      lines = [[LTVGLines alloc] initWithLines:@[@1]
                              attributedString:[[NSAttributedString alloc] init]];
    }).to.raise(NSInvalidArgumentException);

    it(@"should raise when initializing without attributed string", ^{
      expect(^{
        lines = [[LTVGLines alloc] initWithLines:linesArray attributedString:nil];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

it(@"should be immutable", ^{
  NSMutableAttributedString *mutableAttributedString =
      [[NSMutableAttributedString alloc] initWithString:@"Test" attributes:@{}];
  lines = [[LTVGLines alloc] initWithLines:linesArray attributedString:mutableAttributedString];
  expect(lines.attributedString).to.equal(mutableAttributedString);
  NSAttributedString *attributedString = [lines.attributedString copy];
  [mutableAttributedString addAttribute:NSStrokeWidthAttributeName value:@(7)
                                  range:NSMakeRange(0, mutableAttributedString.length)];
  expect(lines.attributedString).to.equal(attributedString);
  expect(lines.attributedString).toNot.equal(mutableAttributedString);
});

context(@"NSObject", ^{
  it(@"should correctly implement the isEqual method", ^{
    expect([lines isEqual:nil]).to.beFalsy();
    expect([lines isEqual:@1]).to.beFalsy();
    expect([lines isEqual:[[LTVGLines alloc] init]]).to.beFalsy();
    expect([lines isEqual:lines]).to.beTruthy();

    LTVGLines *equalLines = [[LTVGLines alloc] initWithLines:linesArray
                                            attributedString:[[NSAttributedString alloc] init]];
    expect([lines isEqual:equalLines]).to.beTruthy();

    LTVGLines *differentLines = [[LTVGLines alloc] initWithLines:@[line]
                                                attributedString:[[NSAttributedString alloc] init]];
    expect([lines isEqual:differentLines]).to.beFalsy();

    differentLines = [[LTVGLines alloc] initWithLines:linesArray
                                     attributedString:[[NSAttributedString alloc]
                                                       initWithString:@"A"]];
    expect([lines isEqual:differentLines]).to.beFalsy();
  });
});

context(@"path", ^{
  __block CAShapeLayer *shapeLayer;

  beforeEach(^{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
  });

  it(@"should create a correct path", ^{
    CGPathRef path = [lines newPathWithLeadingFactor:0 trackingFactor:0];
    shapeLayer.path = path;
    CGPathRelease(path);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 19), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"LinesTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });

  it(@"should create a correct path with non-zero leading and non-zero tracking", ^{
    CGPathRef path = [lines newPathWithLeadingFactor:1 trackingFactor:1];
    shapeLayer.path = path;
    CGPathRelease(path);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(26, 30), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"LinesLeadingTrackingTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });

  it(@"should create a correctly aligned path", ^{
    NSArray *alignments =
        @[@(NSTextAlignmentLeft), @(NSTextAlignmentCenter), @(NSTextAlignmentRight)];
    NSArray *fileNames = @[@"LinesTest.png", @"LinesTestCenter.png", @"LinesTestRight.png"];

    for (NSUInteger i = 0; i < alignments.count; ++i) {
      NSTextAlignment alignment = (NSTextAlignment)[alignments[i] unsignedIntegerValue];
      NSString *fileName = fileNames[i];

      NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
      paragraphStyle.alignment = alignment;
      attributedString = [[NSAttributedString alloc] initWithString:@"Test"
                                                         attributes:@{NSParagraphStyleAttributeName:
                                                                        paragraphStyle}];

      lines = [[LTVGLines alloc] initWithLines:linesArray attributedString:attributedString];

      CGPathRef path = [lines newPathWithLeadingFactor:0 trackingFactor:0];
      CGAffineTransform translation;
      if (i == 0) {
        translation = CGAffineTransformIdentity;
      } else if (i == 1) {
        translation = CGAffineTransformMakeTranslation(7, 0);
      } else {
        translation = CGAffineTransformMakeTranslation(14, 0);
      }

      CGPathRef translatedPath = CGPathCreateCopyByTransformingPath(path, &translation);
      CGPathRelease(path);
      shapeLayer.path = translatedPath;
      CGPathRelease(translatedPath);

      UIGraphicsBeginImageContextWithOptions(CGSizeMake(15, 19), YES, 2.0);
      [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
      UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();

      cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
      cv::Mat expectedMat = LTLoadMat([self class], fileName);

      expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
    }
  });
});

LTSpecEnd
