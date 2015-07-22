// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainterImageProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLContext.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTPaintingStrategy.h"
#import "LTTexture+Factory.h"
#import "LTTextureBrush.h"

@interface LTPainterImageProcessor ()
@property (strong, nonatomic) LTPainter *painter;
@end

LTSpecBegin(LTPainterImageProcessor)

__block id strategy;
__block LTPainterImageProcessor *processor;
__block LTTexture *output;

beforeEach(^{
  LTGLContext *context = [[LTGLContext alloc] init];
  [LTGLContext setCurrentContext:context];
  output = [LTTexture byteRGBATextureWithSize:CGSizeMake(2, 2)];
  strategy = [OCMockObject niceMockForProtocol:@protocol(LTPaintingStrategy)];
});

afterEach(^{
  processor = nil;
  output = nil;
  [LTGLContext setCurrentContext:nil];
});

context(@"initialization", ^{
  it(@"should initialize with canvas and strategy", ^{
    processor = [[LTPainterImageProcessor alloc] initWithCanvasTexture:output
                                                      paintingStrategy:strategy];
    expect(processor.canvasSize).to.equal(output.size);
  });
  
  it(@"should raise when no canvas is provided", ^{
    expect(^{
      processor = [[LTPainterImageProcessor alloc] initWithCanvasTexture:nil
                                                        paintingStrategy:strategy];
    }).to.raise(NSInvalidArgumentException);
  });
  
  it(@"should raise when no strategy is provided", ^{
    expect(^{
      processor = [[LTPainterImageProcessor alloc] initWithCanvasTexture:output
                                                        paintingStrategy:nil];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"processing", ^{
  beforeEach(^{
    processor = [[LTPainterImageProcessor alloc] initWithCanvasTexture:output
                                                      paintingStrategy:strategy];
  });
  
  it(@"should advance processedProgress to target progress", ^{
    processor.targetProgress = 0.5;
    expect(processor.processedProgress).to.equal(0);
    [processor process];
    expect(processor.processedProgress).to.equal(0.5);
  });
  
  it(@"should notify strategy that painting will begin upon first processing", ^{
    [[strategy expect] paintingWillBeginWithPainter:processor.painter];
    processor.targetProgress = 0.5;
    [processor process];
    OCMVerifyAll(strategy);
  });
  
  it(@"should not notify strategy that painting will begin on consequent processings", ^{
    processor.targetProgress = 0.5;
    [processor process];
    [[strategy reject] paintingWillBeginWithPainter:OCMOCK_ANY];
    processor.targetProgress = 0.6;
    [processor process];
    OCMVerifyAll(strategy);
  });
  
  it(@"should ask painting directions from strategy", ^{
    processor.targetProgress = 0.5;
    [[strategy expect] paintingDirectionsForStartingProgress:0 endingProgress:0.5];
    [processor process];
    processor.targetProgress = 1.0;
    [[strategy expect] paintingDirectionsForStartingProgress:0.5 endingProgress:1.0];
    [processor process];
    OCMVerifyAll(strategy);
  });
  
  it(@"should paint according to directions received from strategy", ^{
    const CGSize kSize = CGSizeMakeUniform(256);
    const CGSize kBrushSize = CGSizeMakeUniform(16);
    
    output = [LTTexture byteRGBATextureWithSize:kSize];
    [output clearWithColor:LTVector4(0, 0, 0, 1)];
    processor = [[LTPainterImageProcessor alloc] initWithCanvasTexture:output
                                                      paintingStrategy:strategy];

    LTBrush *redBrush = [[LTTextureBrush alloc] init];
    LTBrush *greenBrush = [[LTTextureBrush alloc] init];
    redBrush.baseDiameter = kBrushSize.width;
    greenBrush.baseDiameter = kBrushSize.width;
    redBrush.intensity = LTVector4(1, 0, 0, 1);
    greenBrush.intensity = LTVector4(0, 1, 0, 1);

    LTPainterPoint *redPoint = [[LTPainterPoint alloc] init];
    LTPainterPoint *greenPoint = [[LTPainterPoint alloc] init];
    redPoint.contentPosition = CGPointZero + 0.5 * kBrushSize;
    greenPoint.contentPosition = CGPointZero + kSize - 0.5 * kBrushSize;
    
    LTPaintingDirections *redDirections = [LTPaintingDirections directionsWithBrush:redBrush
                                                             linearStrokeStartingAt:redPoint];
    LTPaintingDirections *greenDirections = [LTPaintingDirections directionsWithBrush:greenBrush
                                                               linearStrokeStartingAt:greenPoint];

    [redDirections.stroke addPointAt:redPoint];
    [greenDirections.stroke addPointAt:greenPoint];
    
    [[[[strategy stub] ignoringNonObjectArgs] andReturn:@[redDirections, greenDirections]]
        paintingDirectionsForStartingProgress:0 endingProgress:0];
    processor.targetProgress = 0.5;
    [processor process];
    
    cv::Mat4b expected(kSize.height, kSize.width, cv::Vec4b(0, 0, 0, 255));
    CGRect redRect = CGRectFromOriginAndSize(CGPointZero, kBrushSize);
    CGRect greenRect = CGRectFromOriginAndSize(CGPointZero + kSize - kBrushSize, kBrushSize);
    expected(LTCVRectWithCGRect(redRect)).setTo(cv::Vec4b(255, 0, 0, 255));
    expected(LTCVRectWithCGRect(greenRect)).setTo(cv::Vec4b(0, 255, 0, 255));
    expect($(output.image)).to.beCloseToMat($(expected));
  });
});

LTSpecEnd
