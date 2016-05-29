// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTView.h"

#import "LTEAGLView.h"
#import "LTContentLocationManager.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGridDrawer.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "LTViewPixelGrid.h"
#import "UIColor+Vector.h"

@interface LTTestContentLocationManager : NSObject <LTContentLocationManager>
@property (nonatomic) CGRect visibleContentRect;
@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) CGFloat maxZoomScale;
@property (nonatomic) BOOL updatedContentSize;
@end

@implementation LTTestContentLocationManager

- (UIEdgeInsets)contentInset {
  return UIEdgeInsetsZero;
}

- (CGFloat)contentScaleFactor {
  return 2;
}

- (UIView *)viewForContentCoordinates {
  return nil;
}

- (LTViewNavigationState *)navigationState {
  return nil;
}

- (void)cancelBogusScrollviewPanGesture {
}

@synthesize contentSize = _contentSize;

- (void)setContentSize:(__unused CGSize)contentSize {
  _contentSize = contentSize;
  self.updatedContentSize = YES;
}

@synthesize navigationMode = _navigationMode;

@end

@interface LTView () <LTViewNavigationViewDelegate>
@property (strong, nonatomic) LTEAGLView *eaglView;
@property (strong, nonatomic) LTViewPixelGrid *pixelGrid;
@property (nonatomic) NSUInteger pixelsPerCheckerboardSquare;
@end

@interface LTViewPixelGrid ()
@property (strong, nonatomic) LTGridDrawer *gridDrawer;
@end

@interface LTGridDrawer ()
@property (nonatomic) CGSize size;
@end

SpecBegin(LTView)

__block LTTestContentLocationManager *contentLocationManager;

__block LTTexture *contentTexture;
__block LTTexture *outputTexture;
__block LTFbo *fbo;
__block LTView *view;
__block cv::Mat4b inputContent;
__block cv::Mat4b output;
__block cv::Mat4b expectedOutput;
__block cv::Mat4b resizedContent;
__block cv::Rect contentAreaInOutput;

__block LTViewRenderingModel *renderingModel;

// Avoid fractional content scale factor since the tests were adjusted for pixels to fit without
// interpolation.
static const CGFloat kContentScaleFactor = 2;

static const CGFloat kMaxZoomScale = 16;

static const CGSize kViewSize = CGSizeMake(32, 64);
static const CGRect kViewFrame = CGRectFromSize(kViewSize);
static const CGSize kContentSize = CGSizeMake(256, 256);
static const CGRect kContentFrame = CGRectFromSize(kContentSize);
static const CGRect kVisibleContentRect = CGRectMake(0, -kContentSize.height / 4,
                                                     kContentSize.width / 2, kContentSize.height);

static const cv::Vec4b clear(0, 0, 0, 0);
static const cv::Vec4b red(255, 0, 0, 255);
static const cv::Vec4b green(0, 255, 0, 255);
static const cv::Vec4b blue(0, 0, 255, 255);
static const cv::Vec4b yellow(255, 255, 0, 255);

beforeEach(^{
  contentLocationManager = [[LTTestContentLocationManager alloc] init];
  contentLocationManager.contentSize = kContentSize;
  contentLocationManager.zoomScale = 1;
  contentLocationManager.maxZoomScale = kMaxZoomScale;
  contentLocationManager.visibleContentRect = kVisibleContentRect;

  CGSize framebufferSize = kViewSize * 2;
  short width = kContentSize.width / 2;
  short height = kContentSize.height / 2;
  inputContent = cv::Mat4b(kContentSize.height, kContentSize.width);
  inputContent(cv::Rect(0, 0, width, height)).setTo(red);
  inputContent(cv::Rect(width, 0, width, height)).setTo(green);
  inputContent(cv::Rect(0, height, width, height)).setTo(blue);
  inputContent(cv::Rect(width, height, width, height)).setTo(yellow);
  contentTexture = [LTTexture textureWithImage:inputContent];
  
  output = cv::Mat4b(framebufferSize.height, framebufferSize.width);
  outputTexture = [LTTexture textureWithImage:output];
  fbo = [[LTFbo alloc] initWithTexture:outputTexture];

  expectedOutput = cv::Mat4b(framebufferSize.height, framebufferSize.width);
  resizedContent = cv::Mat4b(std::min(framebufferSize), std::min(framebufferSize));
  CGPoint targetCenter = CGRectCenter(CGRectFromSize(framebufferSize));
  CGRect rect = CGRectCenteredAt(targetCenter,
                                 CGSizeMake(resizedContent.cols, resizedContent.rows));
  contentAreaInOutput = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

  renderingModel = [LTViewRenderingModel modelWithContext:[LTGLContext currentContext]
                                           contentTexture:contentTexture];
});

afterEach(^{
  contentLocationManager = nil;
  fbo = nil;
  outputTexture = nil;
  contentTexture = nil;
  renderingModel = nil;
});

context(@"initialization", ^{
  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame
                  contentLocationManager:contentLocationManager renderingModel:renderingModel];
    [view layoutIfNeeded];
  });
  
  afterEach(^{
    view = nil;
  });
  
  it(@"should have default values", ^{
    expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
    expect(view.framebufferSize).to.equal(view.bounds.size * view.contentScaleFactor);
    expect(view.forwardTouchesToDelegate).to.beFalsy();
    expect(view.contentTransparency).to.beFalsy();
    expect(view.checkerboardPattern).to.beFalsy();
    expect(view.navigationMode).to.equal(LTViewNavigationFull);
  });
  
  it(@"should set contentTransparency", ^{
    view.contentTransparency = YES;
    expect(view.contentTransparency).to.beTruthy();
  });

  it(@"should set checkerboardPattern", ^{
    view.checkerboardPattern = YES;
    expect(view.checkerboardPattern).to.beTruthy();
  });

  it(@"should set forwardTouchesToDelegate", ^{
    view.forwardTouchesToDelegate = YES;
    expect(view.forwardTouchesToDelegate).to.beTruthy();
  });

  context(@"invalid initialization calls", ^{
    it(@"should raise when initializing with texture and content rectangle of mismatching sizes", ^{
      contentLocationManager.contentSize = 2 * kContentSize;
      expect(^{
        view = [[LTView alloc] initWithFrame:kViewFrame
                      contentLocationManager:contentLocationManager renderingModel:renderingModel];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"properties", ^{
  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should provide a view to which gestures should be added", ^{
    expect(view.gestureView).toNot.beNil();
  });

  context(@"navigation mode", ^{
    it(@"should proxy navigation mode to the content location manager", ^{
      contentLocationManager.navigationMode = LTViewNavigationNone;
      view.navigationMode = LTViewNavigationTwoFingers;
      expect(contentLocationManager.navigationMode).to.equal(LTViewNavigationTwoFingers);
    });

    it(@"should proxy navigation mode from the content location manager", ^{
      contentLocationManager.navigationMode = LTViewNavigationTwoFingers;
      LTViewNavigationMode mode = view.navigationMode;
      expect(mode).to.equal(LTViewNavigationTwoFingers);

      contentLocationManager.navigationMode = LTViewNavigationZoomAndScroll;
      mode = view.navigationMode;
      expect(mode).to.equal(LTViewNavigationZoomAndScroll);
    });
  });
});

context(@"drawing", ^{
  __block LTView *view;

  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should draw according to provided visible content rect", ^{
    CGSize pixelSize = CGSizeMake(1, 1) / view.contentScaleFactor;
    CGSize contentSizeInPoints = contentTexture.size / view.contentScaleFactor;
    CGRect bottomRightPixel = CGRectFromOriginAndSize(CGPointMake(contentSizeInPoints.width - 1,
                                                                  contentSizeInPoints.height - 1),
                                                      pixelSize);

    contentLocationManager.visibleContentRect = bottomRightPixel;

    view.pixelGrid = nil;

    // The expected result should be the bottom right pixel of the content all over the framebuffer.
    expectedOutput = inputContent(inputContent.rows - 1, inputContent.cols - 1);
    
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect(LTCompareMat(expectedOutput, output)).to.beTruthy();
  });

  it(@"should draw the downsampled content on the center of the framebuffer", ^{
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    expectedOutput = view.backgroundColor.lt_cvVector;
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
  
  it(@"should draw background color outside the content", ^{
    UIColor *backgroundColor = [UIColor redColor];
    view.backgroundColor = backgroundColor;
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    expectedOutput = backgroundColor.lt_cvVector;
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
  
  it(@"should draw transparent pixels as black if contentTransparency is NO", ^{
    view.contentTransparency = NO;
    [contentTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
      cv::Vec4b transparency(128, 0, 0, 128);
      (*mapped)(cv::Rect(0, 0, mapped->cols / 2, mapped->rows / 2)).setTo(transparency);
      cv::resize(*mapped, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
      cv::flip(resizedContent, resizedContent, 0);
      expectedOutput = view.backgroundColor.lt_cvVector;
      resizedContent.copyTo(expectedOutput(contentAreaInOutput));
    }];

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  context(@"contentTransparency is YES", ^{
    it(@"should blend transparent pixels with a checkerboard if checkerboardPattern is YES", ^{
      view.contentTransparency = YES;
      view.checkerboardPattern = YES;
      [contentTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        cv::Vec4b semiTransparent(128, 0, 0, 128);
        cv::Vec4b blendedWhite = LTBlend(cv::Vec4b(255, 255, 255, 255), semiTransparent);
        cv::Vec4b blendedGray = LTBlend(cv::Vec4b(193, 193, 193, 255), semiTransparent);
        (*mapped)(cv::Rect(0, 0, mapped->cols / 2, mapped->rows / 2)).setTo(semiTransparent);
        cv::resize(*mapped, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
        unsigned int pixels = (unsigned int)view.pixelsPerCheckerboardSquare;
        resizedContent(cv::Rect(0, 0, pixels, pixels)) = blendedGray;
        resizedContent(cv::Rect(pixels, pixels, pixels, pixels)) = blendedGray;
        resizedContent(cv::Rect(pixels, 0, pixels, pixels)) = blendedWhite;
        resizedContent(cv::Rect(0, pixels, pixels, pixels)) = blendedWhite;
        cv::flip(resizedContent, resizedContent, 0);
        expectedOutput = view.backgroundColor.lt_cvVector;
        resizedContent.copyTo(expectedOutput(contentAreaInOutput));
      }];

      [view drawToFbo:fbo];
      expect($(outputTexture.image)).to.beCloseToMat($(expectedOutput));
    });

    it(@"should blend transparent pixels with backgroundColor if checkerboardPattern is NO", ^{
      view.contentTransparency = YES;
      view.checkerboardPattern = NO;
      view.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1.0];
      [contentTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
        cv::Vec4b semiTransparent(128, 0, 0, 128);
        cv::Vec4b blendedGray = LTBlend(cv::Vec4b(193, 193, 193, 255), semiTransparent);
        (*mapped)(cv::Rect(0, 0, mapped->cols / 2, mapped->rows / 2)).setTo(semiTransparent);
        cv::resize(*mapped, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
        unsigned int pixels = (unsigned int)view.pixelsPerCheckerboardSquare;
        resizedContent(cv::Rect(0, 0, pixels * 2, pixels * 2)) = blendedGray;
        cv::flip(resizedContent, resizedContent, 0);
        expectedOutput = view.backgroundColor.lt_cvVector;
        resizedContent.copyTo(expectedOutput(contentAreaInOutput));
      }];

      [view drawToFbo:fbo];
      expect($(outputTexture.image)).to.beCloseToMat($(expectedOutput));
    });
  });

  context(@"magnifying interpolation", ^{
    // Tests if zooming by the given factor uses the expected interpolation.
    void (^testInterpolation)(CGFloat, int) = ^(CGFloat zoomFactor, int expectedInterpolation) {
      CGRect contentBoundsInPoints = CGRectFromSize(kContentSize / view.contentScaleFactor);
      CGRect targetInPoints = CGRectCenteredAt(CGRectCenter(contentBoundsInPoints),
                                               kViewSize / zoomFactor);
      CGRect targetInPixels = CGRectCenteredAt(CGRectCenter(kContentFrame),
                                               kViewSize / zoomFactor * view.contentScaleFactor);

      contentLocationManager.visibleContentRect = targetInPoints;
      contentLocationManager.zoomScale = zoomFactor;
      view.pixelGrid = nil;
      
      cv::resize(inputContent(LTCVRectWithCGRect(targetInPixels)), expectedOutput,
                 cv::Size(expectedOutput.cols, expectedOutput.rows), 0, 0, expectedInterpolation);
      cv::flip(expectedOutput, expectedOutput, 0);

      [view drawToFbo:fbo];
      output = [outputTexture image];
      expect($(output)).to.beCloseToMat($(expectedOutput));
    };
    
    it(@"should use linear interpolation on lower zoom levels", ^{
      testInterpolation(2, cv::INTER_LINEAR);
    });
    
    it(@"should use nearest neighbor interpolation on higher zoom levels", ^{
      testInterpolation(4, cv::INTER_NEAREST);
    });
  });
  
  pending(@"should draw background", ^{
    // TODO:(amit) implement when the background is determined.
  });
  
  pending(@"should draw shadows", ^{
    // TODO:(amit) implement when the shadows are determined.
  });
  
  it(@"should replace content", ^{
    CGSize newSize = kViewSize * view.contentScaleFactor;
    cv::Mat4b newMat(newSize.height, newSize.width);
    newMat(cv::Rect(0, 0, newSize.width, newSize.height / 2)) = red;
    newMat(cv::Rect(0, newSize.height / 2, newSize.width, newSize.height / 2)) = blue;
    LTTexture *newTexture = [LTTexture textureWithImage:newMat];
    
    [view replaceContentWith:newTexture];

    contentLocationManager.contentSize = newSize;
    contentLocationManager.visibleContentRect = CGRectFromSize(kViewSize);

    cv::flip(newMat, newMat, 0);
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect(LTCompareMat(newMat, output)).to.beTruthy();
  });

  it(@"should update pixel grid when replacing content", ^{
    CGSize newSize = kContentSize * 2;
    [view replaceContentWith:[LTTexture byteRGBATextureWithSize:newSize]];
    expect(view.pixelGrid.gridDrawer.size).to.equal(newSize);
  });

  it(@"should update content location manager upon texture size changes", ^{
    CGSize newTextureSize = kContentSize * 2;
    [view replaceContentWith:[LTTexture byteRGBATextureWithSize:newTextureSize]];
    expect(contentLocationManager.contentSize).to.equal(newTextureSize);
  });

  it(@"should not update content location manager upon change to texture with the same size", ^{
    contentLocationManager.updatedContentSize = NO;
    [view replaceContentWith:[LTTexture byteRGBATextureWithSize:kContentSize]];
    expect(contentLocationManager.updatedContentSize).to.beFalsy();
  });
});

context(@"public interface", ^{
  __block LTView *view;

  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should return transform mapping the visibleContentRect to the entire framebuffer", ^{
    CGAffineTransform transform = [view transformForVisibleContentRect:view.visibleContentRect];
    CGRect transformedRect = CGRectApplyAffineTransform(view.visibleContentRect, transform);
    expect(transformedRect).to.equal(CGRectFromSize(view.framebufferSize));
  });

  pending(@"should take a snapshot of the view");
});

context(@"draw delegate", ^{
  __block LTView *view;
  __block id mock;
  
  beforeEach(^{
    mock = [OCMockObject niceMockForProtocol:@protocol(LTViewDrawDelegate)];
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
    [view layoutIfNeeded];
    view.drawDelegate = mock;
  });
  
  afterEach(^{
    mock = nil;
    view = nil;
  });
  
  it(@"should use delegate to update content rect", ^{
    [[[mock stub] andDo:^(NSInvocation *) {
      glClearColor(0, 1, 0, 1);
      glClear(GL_COLOR_BUFFER_BIT);
    }] ltView:view updateContentInRect:kContentFrame];
    [view setNeedsDisplayContent];
    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = green;

    [view drawToFbo:fbo];

    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should call the delegate once per setNeedsDisplayContent", ^{
    __block BOOL delegateCalled = NO;
    [[[mock stub] andDo:^(NSInvocation *) {
      delegateCalled = YES;
    }] ltView:view updateContentInRect:kContentFrame];
    [view drawToFbo:fbo];
    expect(delegateCalled).to.beFalsy();
    [view setNeedsDisplayContent];
    [view drawToFbo:fbo];
    expect(delegateCalled).to.beTruthy();
    delegateCalled = NO;
    [view drawToFbo:fbo];
    expect(delegateCalled).to.beFalsy();
  });
  
  it(@"should use delegate to draw overlays above content", ^{
    [[[[mock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
      CGAffineTransform transform;
      // Verify that the transform maps the content frame to the visible content rectangle on the
      // framebuffer.
      [invocation getArgument:&transform atIndex:3];
      CGRect visibleContentRect = CGRectApplyAffineTransform(kContentFrame, transform);
      CGRect expectedRect = CGRectMake(contentAreaInOutput.x, contentAreaInOutput.y,
                                       contentAreaInOutput.width, contentAreaInOutput.height);
      expect(visibleContentRect).to.equal(expectedRect);
      
      // Clear the framebuffer (should only affect the visible content rectangle according to the
      // defined scissor box.
      glClearColor(0, 1, 0, 1);
      glClear(GL_COLOR_BUFFER_BIT);
    }] ltView:view drawOverlayAboveContentWithTransform:CGAffineTransformIdentity];
    
    // The overlay should affect only the visible content rectangle (scissor box).
    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = green;
    
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should use delegate to provide an alternative content texture", ^{
    cv::Mat4b altMat(kContentSize.height, kContentSize.width);
    altMat = red;
    LTTexture *altTexture = [LTTexture textureWithImage:altMat];
    [[[mock stub] andReturn:altTexture] alternativeContentTexture];
    
    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = red;
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
  
  it(@"should use content texture if alternativeContentTexture returns nil", ^{
    [[[mock stub] andReturn:nil] alternativeContentTexture];
    
    expectedOutput = view.backgroundColor.lt_cvVector;
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));
    
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should provide the correct texture and visible content to the drawProcessedContent", ^{
    // When there's no alternativeContentTexture, the content texture should be provided.
    [[mock expect] ltView:view drawProcessedContent:contentTexture
                   withVisibleContentRect:view.visibleContentRect];
    [view drawToFbo:fbo];
    
    // When there's an alternativeContentTexture, it should be provided instead.
    LTTexture *altTexture = [LTTexture textureWithImage:inputContent];
    [[[mock stub] andReturn:altTexture] alternativeContentTexture];
    [[mock expect] ltView:view drawProcessedContent:altTexture
                   withVisibleContentRect:view.visibleContentRect];
    [view drawToFbo:fbo];
    OCMVerifyAll(mock);
  });

  it(@"should use delegate to draw the processed content", ^{
    [[[[mock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
      expect([LTGLContext currentContext].renderingToScreen).to.beTruthy();
      cv::Mat4b altMat(kContentSize.height, kContentSize.width);
      altMat = blue;
      LTTexture *altTexture = [LTTexture textureWithImage:altMat];
      LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithSourceTexture:altTexture];
      [rectDrawer drawRect:CGRectFromSize(view.framebufferSize)
       inFramebufferWithSize:view.framebufferSize fromRect:view.visibleContentRect];
      BOOL returnValue = YES;
      [invocation setReturnValue:&returnValue];
    }] ltView:view drawProcessedContent:contentTexture withVisibleContentRect:CGRectZero];
    
    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = blue;
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
  
  it(@"should draw the unprocessed content texture if drawProcessedContent returns NO", ^{
    [[[[mock stub] ignoringNonObjectArgs] andReturnValue:@NO]
     ltView:view drawProcessedContent:contentTexture withVisibleContentRect:CGRectZero];

    expectedOutput = view.backgroundColor.lt_cvVector;
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));
    
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
});

context(@"touch delegate", ^{
  __block LTView *view;
  __block id mock;
  
  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
    [view layoutIfNeeded];
    view.forwardTouchesToDelegate = YES;
    view.navigationMode = LTViewNavigationNone;

    mock = [OCMockObject niceMockForProtocol:@protocol(LTViewTouchDelegate)];
    OCMStub([mock ltViewAttachedToDelegate:view]);
    OCMStub([mock ltViewDetachedFromDelegate:view]);
    view.touchDelegate = mock;
  });
  
  afterEach(^{
    mock = nil;
    view = nil;
  });
  
  it(@"should forward touchesBegan event", ^{
    [[mock expect] ltView:view touchesBegan:[NSSet set] withEvent:nil];
    [view simulateTouchesOfPhase:UITouchPhaseBegan];
    OCMVerifyAll(mock);
  });
  
  it(@"should forward touchesMoved event", ^{
    [[mock expect] ltView:view touchesMoved:[NSSet set] withEvent:nil];
    [view simulateTouchesOfPhase:UITouchPhaseMoved];
    OCMVerifyAll(mock);
  });
  
  it(@"should forward touchesEnded event", ^{
    [[mock expect] ltView:view touchesEnded:[NSSet set] withEvent:nil];
    [view simulateTouchesOfPhase:UITouchPhaseEnded];
    OCMVerifyAll(mock);
  });
  
  it(@"should forward touchesCancelled event", ^{
    [[mock expect] ltView:view touchesCancelled:[NSSet set] withEvent:nil];
    [view simulateTouchesOfPhase:UITouchPhaseCancelled];
    OCMVerifyAll(mock);
  });
  
  it(@"should not forward events if property is set to NO", ^{
    [[mock reject] ltView:OCMOCK_ANY touchesBegan:OCMOCK_ANY withEvent:OCMOCK_ANY];
    [[mock reject] ltView:OCMOCK_ANY touchesMoved:OCMOCK_ANY withEvent:OCMOCK_ANY];
    [[mock reject] ltView:OCMOCK_ANY touchesEnded:OCMOCK_ANY withEvent:OCMOCK_ANY];
    [[mock reject] ltView:OCMOCK_ANY touchesCancelled:OCMOCK_ANY withEvent:OCMOCK_ANY];
    view.forwardTouchesToDelegate = NO;
    [view simulateTouchesOfPhase:UITouchPhaseBegan];
    [view simulateTouchesOfPhase:UITouchPhaseMoved];
    [view simulateTouchesOfPhase:UITouchPhaseEnded];
    [view simulateTouchesOfPhase:UITouchPhaseCancelled];
    OCMVerifyAll(mock);
  });

  it(@"should only forward events if navigation mode is none or two fingers", ^{
    NSArray *validModes = @[@(LTViewNavigationNone), @(LTViewNavigationTwoFingers)];
    for (NSUInteger i = 0; i < LTViewNavigationNone; ++i) {
      mock = [OCMockObject niceMockForProtocol:@protocol(LTViewTouchDelegate)];
      OCMStub([mock ltViewAttachedToDelegate:view]);
      OCMStub([mock ltViewDetachedFromDelegate:view]);

      view.touchDelegate = mock;
      view.navigationMode = (LTViewNavigationMode)i;
      if ([validModes containsObject:@(i)]) {
        [[mock expect] ltView:OCMOCK_ANY touchesBegan:OCMOCK_ANY withEvent:OCMOCK_ANY];
        [[mock expect] ltView:OCMOCK_ANY touchesMoved:OCMOCK_ANY withEvent:OCMOCK_ANY];
        [[mock expect] ltView:OCMOCK_ANY touchesEnded:OCMOCK_ANY withEvent:OCMOCK_ANY];
        [[mock expect] ltView:OCMOCK_ANY touchesCancelled:OCMOCK_ANY withEvent:OCMOCK_ANY];
      } else {
        [[mock reject] ltView:OCMOCK_ANY touchesBegan:OCMOCK_ANY withEvent:OCMOCK_ANY];
        [[mock reject] ltView:OCMOCK_ANY touchesMoved:OCMOCK_ANY withEvent:OCMOCK_ANY];
        [[mock reject] ltView:OCMOCK_ANY touchesEnded:OCMOCK_ANY withEvent:OCMOCK_ANY];
        [[mock reject] ltView:OCMOCK_ANY touchesCancelled:OCMOCK_ANY withEvent:OCMOCK_ANY];
      }
      [view simulateTouchesOfPhase:UITouchPhaseBegan];
      [view simulateTouchesOfPhase:UITouchPhaseMoved];
      [view simulateTouchesOfPhase:UITouchPhaseEnded];
      [view simulateTouchesOfPhase:UITouchPhaseCancelled];
      OCMVerifyAll(mock);
    }
  });

  context(@"attach and detach", ^{
    __block id mock;
    __block id otherMock;
    __block BOOL attached;
    __block BOOL otherAttached;

    beforeEach(^{
      attached = NO;
      otherAttached = NO;
      mock = OCMProtocolMock(@protocol(LTViewTouchDelegate));
      otherMock = OCMProtocolMock(@protocol(LTViewTouchDelegate));

      OCMStub([mock ltViewAttachedToDelegate:view]).andDo(^(NSInvocation *) {
        attached = YES;
      });
      OCMStub([mock ltViewDetachedFromDelegate:view]).andDo(^(NSInvocation *) {
        attached = NO;
      });

      OCMStub([otherMock ltViewAttachedToDelegate:view]).andDo(^(NSInvocation *) {
        otherAttached = YES;
      });
      OCMStub([otherMock ltViewDetachedFromDelegate:view]).andDo(^(NSInvocation *) {
        otherAttached = NO;
      });
    });

    afterEach(^{
      mock = nil;
      otherMock = nil;
    });
    
    it(@"updating forwardTouchesToDelegate should trigger attach or detach", ^{
      view.forwardTouchesToDelegate = NO;
      view.touchDelegate = mock;
      view.navigationMode = LTViewNavigationNone;
      expect(attached).to.beFalsy();
      view.forwardTouchesToDelegate = YES;
      expect(attached).to.beTruthy();
      view.forwardTouchesToDelegate = NO;
      expect(attached).to.beFalsy();
    });

    it(@"updating navigationMode should trigger attach or detach", ^{
      view.navigationMode = LTViewNavigationFull;
      view.touchDelegate = mock;
      view.forwardTouchesToDelegate = YES;
      expect(attached).to.beFalsy();
      view.navigationMode = LTViewNavigationNone;
      expect(attached).to.beTruthy();
      view.navigationMode = LTViewNavigationFull;
      expect(attached).to.beFalsy();
      view.navigationMode = LTViewNavigationTwoFingers;
      expect(attached).to.beTruthy();
      view.navigationMode = LTViewNavigationBounceToMinimalScale;
      expect(attached).to.beFalsy();
    });

    it(@"should detach from previous if replacing attached delegate", ^{
      view.navigationMode = LTViewNavigationNone;
      view.forwardTouchesToDelegate = YES;
      view.touchDelegate = mock;
      expect(attached).to.beTruthy();
      view.touchDelegate = otherMock;
      expect(attached).to.beFalsy();
    });

    it(@"should attach to new delegate if replacing attached delegate", ^{
      view.navigationMode = LTViewNavigationNone;
      view.forwardTouchesToDelegate = YES;
      view.touchDelegate = mock;
      expect(attached).to.beTruthy();
      expect(otherAttached).to.beFalsy();
      view.touchDelegate = otherMock;
      expect(otherAttached).to.beTruthy();
    });

    it(@"should not detach if replacing a detached delegate", ^{
      view.navigationMode = LTViewNavigationNone;
      view.forwardTouchesToDelegate = NO;
      view.touchDelegate = mock;
      expect(attached).to.beFalsy();
      [[mock reject] ltViewDetachedFromDelegate:[OCMArg any]];
      view.touchDelegate = otherMock;
      OCMVerifyAll(mock);
    });

    it(@"should not attach if replacing a detached delegate", ^{
      view.navigationMode = LTViewNavigationNone;
      view.forwardTouchesToDelegate = NO;
      view.touchDelegate = mock;
      expect(attached).to.beFalsy();
      [[otherMock reject] ltViewAttachedToDelegate:[OCMArg any]];
      view.touchDelegate = otherMock;
      OCMVerifyAll(otherMock);
    });

    it(@"should not be able to change navigation mode from detach due to such change", ^{
      mock = OCMProtocolMock(@protocol(LTViewTouchDelegate));
      view.touchDelegate = mock;

      OCMExpect([mock ltViewDetachedFromDelegate:[OCMArg checkWithBlock:^BOOL(LTView *view) {
        view.navigationMode = LTViewNavigationBounceToMinimalScale;
        return YES;
      }]]);

      view.navigationMode = LTViewNavigationFull;
      OCMVerifyAll(mock);
      expect(view.navigationMode).to.equal(LTViewNavigationFull);
    });

    it(@"should not be able to change forwardTouchesToDelegate from detach due to such change", ^{
      mock = OCMProtocolMock(@protocol(LTViewTouchDelegate));
      view.touchDelegate = mock;

      OCMExpect([mock ltViewDetachedFromDelegate:[OCMArg checkWithBlock:^BOOL(LTView *view) {
        view.forwardTouchesToDelegate = YES;
        return YES;
      }]]);

      view.forwardTouchesToDelegate = NO;
      OCMVerifyAll(mock);
      expect(view.forwardTouchesToDelegate).beFalsy();
    });
  });
});

context(@"navigation delegate", ^{
  __block id delegate;
  __block LTView *view;
  
  beforeEach(^{
    delegate = [OCMockObject mockForProtocol:@protocol(LTViewNavigationDelegate)];
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
    view.navigationDelegate = delegate;
  });
  
  afterEach(^{
    delegate = nil;
    view = nil;
  });
  
  it(@"should forward event to delegate", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, view.bounds.size);
    [[[delegate expect] ignoringNonObjectArgs] ltViewDidNavigateToRect:targetRect];
    [view didNavigateToRect:targetRect];
    OCMVerifyAll(delegate);
  });
});

context(@"content location delegate", ^{
  __block LTView *view;

  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame contentLocationManager:contentLocationManager
                          renderingModel:renderingModel];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should update the content location manager upon replacement of texture", ^{
    CGSize newSize = CGSizeMake(1, 2);
    LTTexture *newTexture = [LTTexture byteRGBATextureWithSize:newSize];
    [view replaceContentWith:newTexture];
    expect(contentLocationManager.contentSize).to.equal(newSize);
  });
});

context(@"framebuffer delegate", ^{
  __block id delegateMock;
  __block id eaglViewMock;
  __block LTView *view;

  beforeEach(^{
    delegateMock = [OCMockObject mockForProtocol:@protocol(LTViewFramebufferDelegate)];
    eaglViewMock = [OCMockObject niceMockForClass:[LTEAGLView class]];
    [[[eaglViewMock stub] andReturnValue:$(CGSizeMake(20, 10))] drawableSize];

    view = [[LTView alloc] initWithFrame:kViewFrame
                  contentLocationManager:contentLocationManager renderingModel:renderingModel];
    view.eaglView = eaglViewMock;
    view.framebufferDelegate = delegateMock;
  });

  afterEach(^{
    delegateMock = nil;
    eaglViewMock = nil;
    view = nil;
  });

  it(@"should forward event to delegate", ^{
    OCMExpect([delegateMock ltView:view framebufferChangedToSize:CGSizeMake(20, 10)]);
    [fbo bindAndDrawOnScreen:^{
      [((id<LTEAGLViewDelegate>)view) eaglView:eaglViewMock drawInRect:CGRectMake(0, 0, 1, 1)];
    }];
    OCMVerifyAll(delegateMock);
  });
});

SpecEnd
