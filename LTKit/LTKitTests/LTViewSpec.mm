// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTView.h"

#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTFbo.h"
#import "LTGLTexture.h"
#import "LTImage.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTestUtils.h"
#import "LTViewNavigationView.h"
#import "LTViewPixelGrid.h"
#import "UIColor+Vector.h"

@interface LTView () <LTViewNavigationViewDelegate>
@property (strong, nonatomic) GLKView *glkView;
@property (strong, nonatomic) LTViewNavigationView *navigationView;
@property (strong, nonatomic) LTViewPixelGrid *pixelGrid;
@property (nonatomic) NSUInteger pixelsPerCheckerboardSquare;
@end

LTSpecBegin(LTView)

__block LTTexture *contentTexture;
__block LTTexture *outputTexture;
__block LTFbo *fbo;
__block LTView *view;
__block cv::Mat4b inputContent;
__block cv::Mat4b output;
__block cv::Mat4b expectedOutput;
__block cv::Mat4b resizedContent;
__block cv::Rect contentAreaInOutput;

static const CGSize kViewSize = CGSizeMake(32, 64);
static const CGRect kViewFrame = CGRectFromSize(kViewSize);
static const CGSize kContentSize = CGSizeMake(256, 256);
static const CGRect kContentFrame = CGRectFromSize(kContentSize);

static const cv::Vec4b clear(0, 0, 0, 0);
static const cv::Vec4b red(255, 0, 0, 255);
static const cv::Vec4b green(0, 255, 0, 255);
static const cv::Vec4b blue(0, 0, 255, 255);
static const cv::Vec4b yellow(255, 255, 0, 255);

beforeEach(^{
  // avoid fractional content scale factor since the tests were adjusted for pixels to fit without
  // interpolation.
  id ltDevice = LTMockClass([LTDevice class]);
  [[[ltDevice stub] andReturnValue:@2] glkContentScaleFactor];

  CGSize framebufferSize = kViewSize * [LTDevice currentDevice].glkContentScaleFactor;
  short width = kContentSize.width / 2;
  short height = kContentSize.height / 2;
  inputContent = cv::Mat4b(kContentSize.height, kContentSize.width);
  inputContent(cv::Rect(0, 0, width, height)).setTo(red);
  inputContent(cv::Rect(width, 0, width, height)).setTo(green);
  inputContent(cv::Rect(0, height, width, height)).setTo(blue);
  inputContent(cv::Rect(width, height, width, height)).setTo(yellow);
  contentTexture = [[LTGLTexture alloc] initWithImage:inputContent];
  
  output = cv::Mat4b(framebufferSize.height, framebufferSize.width);
  outputTexture = [[LTGLTexture alloc] initWithImage:output];
  fbo = [[LTFbo alloc] initWithTexture:outputTexture];

  expectedOutput = cv::Mat4b(framebufferSize.height, framebufferSize.width);
  resizedContent = cv::Mat4b(std::min(framebufferSize), std::min(framebufferSize));
  CGPoint targetCenter = CGRectCenter(CGRectFromSize(framebufferSize));
  CGRect rect = CGRectCenteredAt(targetCenter,
                                 CGSizeMake(resizedContent.cols, resizedContent.rows));
  contentAreaInOutput = cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
});

afterEach(^{
  fbo = nil;
  outputTexture = nil;
  contentTexture = nil;
});

context(@"setup", ^{
  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
  });
  
  afterEach(^{
    view = nil;
  });
  
  it(@"should setup without state", ^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
  });
  
  it(@"should setup with state", ^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    LTView *otherView = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    const CGRect targetRect = CGRectFromSize(kViewSize);
    [view.navigationView zoomToRect:targetRect animated:NO];
    
    [otherView setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture
                          state:view.navigationState];
    expect(otherView.navigationView.visibleContentRect).
        to.equal(view.navigationView.visibleContentRect);
  });

  it(@"should teardown", ^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    expect(view.glkView).notTo.beNil();
    [view teardown];
    expect(view.glkView).to.beNil();
  });
  
  it(@"should do nothing when setup is called twice", ^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    GLKView *glkView = view.glkView;
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    expect(view.glkView).to.beIdenticalTo(glkView);
  });
  
  it(@"should do nothing when teardown is called twice", ^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    [view teardown];
    [view teardown];
    expect(view.glkView).to.beNil();
  });
  
  it(@"should setup after a teardown", ^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    GLKView *glkView = view.glkView;
    [view teardown];
    expect(view.glkView).to.beNil();
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    expect(view.glkView).notTo.beNil();
    expect(view.glkView).notTo.beIdenticalTo(glkView);
  });
});

context(@"properties", ^{
  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    [view forceGLKViewFramebufferAllocation];
  });
  
  afterEach(^{
    view = nil;
  });
  
  it(@"should have default values", ^{
    expect(view.contentScaleFactor).to.equal([LTDevice currentDevice].glkContentScaleFactor);
    expect(view.contentSize).to.equal(kContentSize);
    expect(view.framebufferSize).to.equal(view.bounds.size * view.contentScaleFactor);
    expect(view.forwardTouchesToDelegate).to.beFalsy();
    expect(view.contentTransparency).to.beFalsy();
    expect(view.checkerboardPattern).to.beFalsy();
    expect(view.navigationMode).to.equal(LTViewNavigationFull);
    expect(view.contentInset).to.equal(UIEdgeInsetsZero);
    expect(view.minZoomScaleFactor).to.equal(0);
    expect(view.maxZoomScale).to.equal(16);
    expect(view.doubleTapZoomFactor).to.equal(3);
    expect(view.doubleTapLevels).to.equal(3);
    expect(view.zoomScale).to.equal(view.navigationView.zoomScale);
    expect(view.viewForContentCoordinates).to.
        beIdenticalTo(view.navigationView.viewForContentCoordinates);
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
  
  it(@"should set navigationMode", ^{
    expect(view.navigationView.mode).to.equal(view.navigationMode);
    view.navigationMode = LTViewNavigationNone;
    expect(view.navigationMode).to.equal(LTViewNavigationNone);
    expect(view.navigationView.mode).to.equal(view.navigationMode);
  });
  
  it(@"should set contentInsets", ^{
    const UIEdgeInsets kInsets = UIEdgeInsetsMake(5, 10, 15, 20);
    view.contentInset = kInsets;
    expect(view.contentInset).to.equal(kInsets);
    expect(view.navigationView.contentInset).to.equal(view.contentInset);
  });
  
  it(@"should set minZoomScaleFactor", ^{
    CGFloat value = view.minZoomScaleFactor ?: 1;
    view.minZoomScaleFactor = value * 0.5;
    expect(view.minZoomScaleFactor).to.equal(value * 0.5);
    expect(view.navigationView.minZoomScaleFactor).to.equal(view.minZoomScaleFactor);
  });
  
  it(@"should set maxZoomScale", ^{
    CGFloat value = view.maxZoomScale;
    view.maxZoomScale = value * 2;
    expect(view.maxZoomScale).to.equal(value * 2);
    expect(view.navigationView.maxZoomScale).to.equal(view.maxZoomScale);
  });

  it(@"should set doubleTapZoomFactor", ^{
    CGFloat value = view.doubleTapZoomFactor;
    view.doubleTapZoomFactor = value * 2;
    expect(view.doubleTapZoomFactor).to.equal(value * 2);
    expect(view.navigationView.doubleTapZoomFactor).to.equal(view.doubleTapZoomFactor);
  });

  it(@"should set doubleTapLevelts", ^{
    CGFloat value = view.doubleTapLevels;
    view.doubleTapLevels = value * 2;
    expect(view.doubleTapLevels).to.equal(value * 2);
    expect(view.navigationView.doubleTapLevels).to.equal(view.doubleTapLevels);
  });
});

context(@"drawing", ^{
  __block LTView *view;

  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    [view forceGLKViewFramebufferAllocation];
  });
  
  afterEach(^{
    view = nil;
  });

  it(@"should draw according to the navigation view's visible content rect", ^{
    // Return the bottom right pixel as the visible content rect.
    id mock = [OCMockObject partialMockForObject:view.navigationView];
    CGSize pixelSize = CGSizeMake(1, 1) / view.contentScaleFactor;
    CGSize contentSizeInPoints = view.contentSize / view.contentScaleFactor;
    CGRect bottomRightPixel = CGRectFromOriginAndSize(CGPointMake(contentSizeInPoints.width - 1,
                                                                  contentSizeInPoints.height - 1),
                                                      pixelSize);
    [[[mock stub] andReturnValue:$(bottomRightPixel)] visibleContentRect];
    view.navigationView = mock;
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
      id mock = [OCMockObject partialMockForObject:view.navigationView];
      CGRect contentBoundsInPoints = CGRectFromSize(kContentSize / view.contentScaleFactor);
      CGRect targetInPoints = CGRectCenteredAt(CGRectCenter(contentBoundsInPoints),
                                               kViewSize / zoomFactor);
      CGRect targetInPixels = CGRectCenteredAt(CGRectCenter(kContentFrame),
                                               kViewSize / zoomFactor * view.contentScaleFactor);
      
      [[[mock stub] andReturnValue:$(targetInPoints)] visibleContentRect];
      view.navigationView = mock;
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
    LTTexture *newTexture = [[LTGLTexture alloc] initWithImage:newMat];
    [view replaceContentWith:newTexture];
    
    cv::flip(newMat, newMat, 0);
    
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect(LTCompareMat(newMat, output)).to.beTruthy();
  });
  
  it(@"should replace content when minimum zoomscale is greater than 1", ^{
    CGSize newSize = kViewSize * view.contentScaleFactor / 2;
    [view replaceContentWith:[[LTGLTexture alloc] initByteRGBAWithSize:newSize]];

    newSize = kViewSize * view.contentScaleFactor / CGSizeMake(4, 2);
    cv::Mat4b newMat(newSize.height, newSize.width);
    newMat(cv::Rect(0, 0, newSize.width, newSize.height / 2)) = red;
    newMat(cv::Rect(0, newSize.height / 2, newSize.width, newSize.height / 2)) = blue;
    LTTexture *newTexture = [[LTGLTexture alloc] initWithImage:newMat];
    [view replaceContentWith:newTexture];
    
    cv::resize(newMat, newMat, cv::Size(), 2, 2);
    cv::flip(newMat, newMat, 0);
    
    CGSize size = view.framebufferSize;
    expectedOutput.setTo(0);
    newMat.copyTo(expectedOutput(cv::Rect(size.width / 4, 0, size.width / 2, size.height)));
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect(LTCompareMat(expectedOutput, output)).to.beTruthy();
  });
});

context(@"public interface", ^{
  __block LTView *view;

  beforeEach(^{
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    [view forceGLKViewFramebufferAllocation];
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
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    [view forceGLKViewFramebufferAllocation];
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
    LTTexture *altTexture = [[LTGLTexture alloc] initWithImage:altMat];
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
    LTTexture *altTexture = [[LTGLTexture alloc] initWithImage:inputContent];
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
      LTTexture *altTexture = [[LTGLTexture alloc] initWithImage:altMat];
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
    mock = [OCMockObject niceMockForProtocol:@protocol(LTViewTouchDelegate)];
    view = [[LTView alloc] initWithFrame:kViewFrame];
    [view setupWithContext:[LTGLContext currentContext] contentTexture:contentTexture state:nil];
    [view forceGLKViewFramebufferAllocation];
    view.touchDelegate = mock;
    view.forwardTouchesToDelegate = YES;
    view.navigationMode = LTViewNavigationNone;
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
  
  it (@"should not forward events if property is set to NO", ^{
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

  it (@"should only forward events if navigation mode is none or two fingers", ^{
    NSArray *validModes = @[@(LTViewNavigationNone), @(LTViewNavigationTwoFingers)];
    for (NSUInteger i = 0; i < LTViewNavigationNone; ++i) {
      mock = [OCMockObject niceMockForProtocol:@protocol(LTViewTouchDelegate)];
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
});

context(@"navigation delegate", ^{
  __block id delegate;
  __block LTViewNavigationView *navView;
  __block LTView *view;
  
  beforeEach(^{
    delegate = [OCMockObject mockForProtocol:@protocol(LTViewNavigationViewDelegate)];
    navView = [[LTViewNavigationView alloc] initWithFrame:kViewFrame contentSize:kContentSize];
    view = [[LTView alloc] initWithFrame:kViewFrame];
    
    view.navigationView = navView;
    view.navigationView.delegate = view;
    view.navigationDelegate = delegate;
  });
  
  afterEach(^{
    delegate = nil;
    navView = nil;
    view = nil;
  });
  
  it(@"should forward event to delegate", ^{
    const CGRect targetRect = CGRectFromOriginAndSize(CGPointZero, view.bounds.size);
    [[[delegate expect] ignoringNonObjectArgs] didNavigateToRect:targetRect];
    [view.navigationView zoomToRect:targetRect animated:NO];
    OCMVerifyAll(delegate);
  });
});

LTSpecEnd
