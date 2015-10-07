// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTVGGlyph.h"

#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTVGTypeSetter.h"

SpecBegin(LTVGGlyph)

__block UIFont *font;
__block CGPoint baselineOrigin;
__block LTVGGlyph *glyph;
__block CGPathRef path;

beforeEach(^{
  font = [UIFont fontWithName:@"Arial" size:10];
  baselineOrigin = CGPointMake(0, 8);
  path = CGPathCreateWithRect(CGRectMake(0, 1, 2, 3), NULL);
  glyph = [[LTVGGlyph alloc] initWithPath:path glyphIndex:7 font:font
                           baselineOrigin:baselineOrigin];
});

afterEach(^{
  CGPathRelease(path);
});

context(@"initialization", ^{
  it(@"should raise when trying to initialize without font", ^{
    expect(^{
      glyph = [[LTVGGlyph alloc] initWithPath:path glyphIndex:7 font:nil
                               baselineOrigin:baselineOrigin];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize correctly without a path for blank glyphs", ^{
    glyph = [[LTVGGlyph alloc] initWithPath:NULL glyphIndex:7 font:font
                             baselineOrigin:baselineOrigin];
    expect(glyph.glyphIndex).to.equal(7);
    expect(glyph.font).to.equal(font);
    expect(glyph.baselineOrigin).to.equal(baselineOrigin);
  });

  it(@"should initialize correctly with a path", ^{
    glyph = [[LTVGGlyph alloc] initWithPath:path glyphIndex:7 font:font
                             baselineOrigin:baselineOrigin];
    expect(glyph.path == path).beFalsy();
    expect(CGPathEqualToPath(glyph.path, path)).to.beTruthy();
    expect(glyph.glyphIndex).to.equal(7);
    expect(glyph.font).to.equal(font);
    expect(glyph.baselineOrigin).to.equal(baselineOrigin);
  });
});

context(@"NSObject", ^{
  it(@"should correctly implement the isEqual method", ^{
    expect([glyph isEqual:nil]).to.beFalsy();
    expect([glyph isEqual:@1]).to.beFalsy();
    expect([glyph isEqual:[[LTVGGlyph alloc] init]]).to.beFalsy();
    expect([glyph isEqual:glyph]).to.beTruthy();

    LTVGGlyph *equalGlyph =
        [[LTVGGlyph alloc] initWithPath:path glyphIndex:7 font:font baselineOrigin:baselineOrigin];
    expect([glyph isEqual:equalGlyph]).to.beTruthy();

    LTVGGlyph *differentGlyph =
        [[LTVGGlyph alloc] initWithPath:path glyphIndex:8 font:font baselineOrigin:baselineOrigin];
    expect([glyph isEqual:differentGlyph]).to.beFalsy();

    differentGlyph =
        [[LTVGGlyph alloc] initWithPath:path glyphIndex:7
                                   font:[UIFont fontWithName:@"Arial" size:11]
                         baselineOrigin:baselineOrigin];
    expect([glyph isEqual:differentGlyph]).to.beFalsy();

    differentGlyph =
        [[LTVGGlyph alloc] initWithPath:path glyphIndex:7 font:font
                         baselineOrigin:CGPointMake(0, 1)];
    expect([glyph isEqual:differentGlyph]).to.beFalsy();
  });
});

context(@"path", ^{
  __block CAShapeLayer *shapeLayer;

  beforeEach(^{
    shapeLayer = [CAShapeLayer layer];
    shapeLayer.fillColor = [UIColor redColor].CGColor;
    glyph = [LTVGTypesetter glyphWithIndex:7 font:font baselineOrigin:baselineOrigin];
  });

  it(@"should create a correct path", ^{
    shapeLayer.path = glyph.path;

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(5, 9), YES, 2.0);
    [shapeLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
    cv::Mat expectedMat = LTLoadMat([self class], @"GlyphTest.png");

    expect($(mat)).to.beCloseToMatWithin($(expectedMat), 0);
  });
});

SpecEnd
