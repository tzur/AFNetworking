// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPresentationView.h"

#import "LTContentDisplayManager.h"
#import "LTContentLocationProvider.h"
#import "LTEAGLView.h"
#import "LTFbo.h"
#import "LTFboPool.h"
#import "LTGLContext.h"
#import "LTGridDrawer.h"
#import "LTGridDrawingManager.h"
#import "LTPresentationViewDrawDelegate.h"
#import "LTPresentationViewFramebufferDelegate.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

@interface LTTestContentLocationProvider : NSObject <LTContentLocationProvider>
@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGRect visibleContentRect;
@property (nonatomic) CGFloat zoomScale;
@property (nonatomic) CGFloat minZoomScale;
@property (nonatomic) CGFloat maxZoomScale;
@end

@implementation LTTestContentLocationProvider

- (UIEdgeInsets)contentInset {
  return UIEdgeInsetsZero;
}

- (CGFloat)contentScaleFactor {
  // Avoid fractional content scale factor since the tests were adjusted for pixels to fit without
  // interpolation.
  return 2;
}

@end

@interface LTPresentationView () <LTEAGLViewDelegate>
@property (strong, nonatomic) LTEAGLView *eaglView;
@property (strong, nonatomic) LTGridDrawingManager *pixelGrid;
@property (strong, nonatomic) LTGLContext *context;
@property (nonatomic) NSUInteger pixelsPerCheckerboardSquare;
@end

@interface LTGridDrawingManager ()
@property (strong, nonatomic) LTGridDrawer *gridDrawer;
@end

@interface LTGridDrawer ()
@property (nonatomic) CGSize size;
@end

SpecBegin(LTPresentationView)

__block LTTestContentLocationProvider *contentLocationProvider;

__block LTTexture *contentTexture;
__block LTTexture *outputTexture;
__block LTFbo *fbo;
__block LTPresentationView *view;
__block cv::Mat4b inputContent;
__block cv::Mat4b output;
__block cv::Mat4b expectedOutput;
__block cv::Mat4b resizedContent;
__block cv::Rect contentAreaInOutput;

static const CGFloat kMinZoomScale = 0.5;
static const CGFloat kMaxZoomScale = 16;

static const CGSize kViewSize = CGSizeMake(32, 64);
static const CGRect kViewFrame = CGRectFromSize(kViewSize);
static const CGSize kContentSize = CGSizeMake(256, 256);
static const CGRect kContentFrame = CGRectFromSize(kContentSize);
static const CGRect kVisibleContentRect = CGRectMake(0, -kContentSize.height / 2,
                                                     kContentSize.width, kContentSize.height * 2);

static const cv::Vec4b kRed(255, 0, 0, 255);
static const cv::Vec4b kGreen(0, 255, 0, 255);
static const cv::Vec4b kBlue(0, 0, 255, 255);
static const cv::Vec4b kYellow(255, 255, 0, 255);

beforeEach(^{
  contentLocationProvider = [[LTTestContentLocationProvider alloc] init];
  contentLocationProvider.contentSize = kContentSize;
  contentLocationProvider.zoomScale = 1;
  contentLocationProvider.minZoomScale = kMinZoomScale;
  contentLocationProvider.maxZoomScale = kMaxZoomScale;
  contentLocationProvider.visibleContentRect = kVisibleContentRect;

  CGSize framebufferSize = kViewSize * 2;
  short width = kContentSize.width / 2;
  short height = kContentSize.height / 2;
  inputContent = cv::Mat4b(kContentSize.height, kContentSize.width);
  inputContent(cv::Rect(0, 0, width, height)).setTo(kRed);
  inputContent(cv::Rect(width, 0, width, height)).setTo(kGreen);
  inputContent(cv::Rect(0, height, width, height)).setTo(kBlue);
  inputContent(cv::Rect(width, height, width, height)).setTo(kYellow);
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
});

afterEach(^{
  contentLocationProvider = nil;
  fbo = nil;
  outputTexture = nil;
  contentTexture = nil;
});

context(@"initialization", ^{
  beforeEach(^{
    view = [[LTPresentationView alloc] initWithFrame:kViewFrame context:[LTGLContext currentContext]
                                      contentTexture:contentTexture
                             contentLocationProvider:contentLocationProvider];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should have default values", ^{
    expect(view.contentScaleFactor).to.equal(contentLocationProvider.contentScaleFactor);
    expect(view.framebufferSize).to.equal(view.bounds.size * view.contentScaleFactor);
    expect(view.contentTransparency).to.beFalsy();
    expect(view.checkerboardPattern).to.beFalsy();
    expect(view.backgroundColor).to.equal([UIColor blackColor]);
  });

  it(@"should set contentTransparency", ^{
    view.contentTransparency = YES;
    expect(view.contentTransparency).to.beTruthy();
  });

  it(@"should set checkerboardPattern", ^{
    view.checkerboardPattern = YES;
    expect(view.checkerboardPattern).to.beTruthy();
  });

  context(@"invalid initialization calls", ^{
    it(@"should raise when initializing with texture and content rectangle of mismatching sizes", ^{
      contentLocationProvider.contentSize = 2 * kContentSize;
      expect(^{
        view = [[LTPresentationView alloc] initWithFrame:kViewFrame
                                                 context:[LTGLContext currentContext]
                                          contentTexture:contentTexture
                                 contentLocationProvider:contentLocationProvider];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"LTEAGLViewDelegate", ^{
  beforeEach(^{
    view = [[LTPresentationView alloc] initWithFrame:kViewFrame context:[LTGLContext currentContext]
                                      contentTexture:contentTexture
                             contentLocationProvider:contentLocationProvider];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should perform drawing when requested", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    [texture clearColor:LTVector4::zeros()];

    [[[LTFboPool currentPool] fboWithTexture:texture] bindAndDraw:^{
      [view eaglView:OCMClassMock([LTEAGLView class]) drawInRect:CGRectZero];
    }];

    expect(texture.fillColor).toNot.equal(LTVector4::zeros());

    // -eaglView:drawInRect: internally invalidates the currently bound frame buffer. The following
    // call guarantees that all rendering commands to the \c texture are compleated at the end of
    // the test, prior to deallocation of the invalidated Fbo. Otherwise when running on IPhone6+
    // device it crashes with \c EXC_BAD_ACCESS due to internal bug when \c glDeleteFramebuffer is
    // called.
    [texture mappedImageForReading:^(const cv::Mat &, BOOL) {}];
  });

  it(@"should use its context when performing drawing", ^{
    LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    [texture clearColor:LTVector4::zeros()];

    id contextMock = OCMClassMock([LTGLContext class]);
    view.context = contextMock;
    OCMExpect([contextMock executeAndPreserveState:OCMOCK_ANY]);

    [[[LTFboPool currentPool] fboWithTexture:texture] bindAndDraw:^{
      [view eaglView:OCMClassMock([LTEAGLView class]) drawInRect:CGRectZero];
    }];

    OCMVerifyAll(contextMock);

    // -eaglView:drawInRect: internally invalidates the currently bound frame buffer. The following
    // call guarantees that all rendering commands to the \c texture are compleated at the end of
    // the test, prior to deallocation of the invalidated Fbo. Otherwise when running on IPhone6+
    // device it crashes with \c EXC_BAD_ACCESS due to internal bug when \c glDeleteFramebuffer is
    // called.
    [texture mappedImageForReading:^(const cv::Mat &, BOOL) {}];
  });

#if defined(DEBUG) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
  it(@"should not perform any drawing if no framebuffer is bound", ^{
    id contextMock = OCMClassMock([LTGLContext class]);
    view.context = contextMock;
    OCMReject([contextMock executeAndPreserveState:OCMOCK_ANY]);

    [view eaglView:OCMClassMock([LTEAGLView class]) drawInRect:CGRectZero];
  });
#endif
});

context(@"drawing", ^{
  __block LTPresentationView *view;

  beforeEach(^{
    view = [[LTPresentationView alloc] initWithFrame:kViewFrame context:[LTGLContext currentContext]
                                      contentTexture:contentTexture
                             contentLocationProvider:contentLocationProvider];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  it(@"should draw according to provided visible content rect", ^{
    CGSize pixelSize = CGSizeMake(1, 1);
    CGSize contentSizeInPixels = contentTexture.size;
    CGRect bottomRightPixel = CGRectFromOriginAndSize(CGPointMake(contentSizeInPixels.width - 1,
                                                                  contentSizeInPixels.height - 1),
                                                      pixelSize);

    contentLocationProvider.visibleContentRect = bottomRightPixel;

    view.pixelGrid = nil;

    // The expected result should be the bottom right pixel of the content all over the framebuffer.
    expectedOutput = inputContent(inputContent.rows - 1, inputContent.cols - 1);

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.equalMat($(expectedOutput));
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
      view.backgroundColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1];
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
      CGRect targetInPixels = CGRectCenteredAt(CGRectCenter(kContentFrame),
                                               kViewSize / zoomFactor * view.contentScaleFactor);

      contentLocationProvider.visibleContentRect = targetInPixels;
      contentLocationProvider.zoomScale = zoomFactor;
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
    newMat(cv::Rect(0, 0, newSize.width, newSize.height / 2)) = kRed;
    newMat(cv::Rect(0, newSize.height / 2, newSize.width, newSize.height / 2)) = kBlue;
    LTTexture *newTexture = [LTTexture textureWithImage:newMat];

    [view replaceContentWith:newTexture];

    contentLocationProvider.contentSize = newSize;
    contentLocationProvider.visibleContentRect = CGRectFromSize(newSize);

    cv::flip(newMat, newMat, 0);
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.equalMat($(newMat));
  });

  it(@"should update pixel grid when replacing content", ^{
    CGSize newSize = kContentSize * 2;
    [view replaceContentWith:[LTTexture byteRGBATextureWithSize:newSize]];
    expect(view.pixelGrid.gridDrawer.size).to.equal(newSize);
  });
});

context(@"public interface", ^{
  __block LTPresentationView *view;

  beforeEach(^{
    view = [[LTPresentationView alloc] initWithFrame:kViewFrame context:[LTGLContext currentContext]
                                      contentTexture:contentTexture
                             contentLocationProvider:contentLocationProvider];
    [view layoutIfNeeded];
  });

  afterEach(^{
    view = nil;
  });

  pending(@"should take a snapshot of the view");
});

context(@"draw delegate", ^{
  __block LTPresentationView *view;
  __block id mock;

  beforeEach(^{
    mock = [OCMockObject niceMockForProtocol:@protocol(LTPresentationViewDrawDelegate)];
    view = [[LTPresentationView alloc] initWithFrame:kViewFrame context:[LTGLContext currentContext]
                                      contentTexture:contentTexture
                             contentLocationProvider:contentLocationProvider];
    [view layoutIfNeeded];
    view.drawDelegate = mock;
  });

  afterEach(^{
    mock = nil;
    view = nil;
  });

  context(@"delegation of rendering of entire content", ^{
    it(@"should call drawContentForPresentationView: method of delegate if implemented", ^{
      OCMStub([mock drawContentForPresentationView:view]).andDo(^(NSInvocation *) {
        [[LTGLContext currentContext] clearColor:LTVector4(0, 1, 0, 1)];
      }).andReturn(YES);
      expectedOutput = kGreen;

      [view drawToFbo:fbo];

      output = [outputTexture image];
      expect($(output)).to.beCloseToMat($(expectedOutput));
    });

    it(@"should only call drawContentForPresentationView: method of delegate if implemented", ^{
      id delegateMock = OCMStrictProtocolMock(@protocol(LTPresentationViewDrawDelegate));
      view.drawDelegate = delegateMock;
      OCMStub([delegateMock drawContentForPresentationView:view])
          .andDo(^(NSInvocation *) {
        [[LTGLContext currentContext] clearColor:LTVector4(0, 1, 0, 1)];
      }).andReturn(YES);
      expectedOutput = kGreen;

      [view drawToFbo:fbo];

      output = [outputTexture image];
      expect($(output)).to.beCloseToMat($(expectedOutput));
    });
  });

  it(@"should use delegate to update content rect", ^{
    [[[mock stub] andDo:^(NSInvocation *) {
      [[LTGLContext currentContext] clearColor:LTVector4(0, 1, 0, 1)];
    }] presentationView:view updateContentInRect:kContentFrame];
    [view setNeedsDisplayContent];
    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = kGreen;

    [view drawToFbo:fbo];

    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should call the delegate once per setNeedsDisplayContent", ^{
    __block BOOL delegateCalled = NO;
    [[[mock stub] andDo:^(NSInvocation *) {
      delegateCalled = YES;
    }] presentationView:view updateContentInRect:kContentFrame];
    [view drawToFbo:fbo];
    expect(delegateCalled).to.beFalsy();
    [view setNeedsDisplayContent];
    [view drawToFbo:fbo];
    expect(delegateCalled).to.beTruthy();
    delegateCalled = NO;
    [view drawToFbo:fbo];
    expect(delegateCalled).to.beFalsy();
  });

  it(@"should use delegate to draw background below content", ^{
    CGRect rectBelowContent = CGRectMake(contentAreaInOutput.x, contentAreaInOutput.y,
                                         contentAreaInOutput.width, contentAreaInOutput.height);
    OCMStub([mock presentationView:view drawBackgroundBelowContentAroundRect:rectBelowContent])
        .andDo(^(NSInvocation *) {
      [[LTGLContext currentContext] clearColor:LTVector4(1, 0, 1, 1)];
    });

    expectedOutput = cv::Vec4b(255, 0, 255, 255);
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
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
      [[LTGLContext currentContext] clearColor:LTVector4(0, 1, 0, 1)];
    }] presentationView:view drawOverlayAboveContentWithTransform:CGAffineTransformIdentity];

    // The overlay should affect only the visible content rectangle (scissor box).
    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = kGreen;

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should use delegate to provide an alternative content texture", ^{
    cv::Mat4b altMat(kContentSize.height, kContentSize.width);
    altMat = kRed;
    LTTexture *altTexture = [LTTexture textureWithImage:altMat];
    OCMStub([mock alternativeTextureForView:view]).andReturn(altTexture);

    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = kRed;
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should use content texture if alternative content texture is nil", ^{
    OCMStub([mock alternativeTextureForView:view]);

    expectedOutput = view.backgroundColor.lt_cvVector;
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should provide the correct texture and visible content to the drawProcessedContent", ^{
    // When there's no alternative content texture, the content texture should be provided.
    OCMExpect([mock presentationView:view drawProcessedContent:contentTexture
              withVisibleContentRect:kVisibleContentRect]);
    [view drawToFbo:fbo];

    // When there's an alternative content texture, it should be provided instead.
    LTTexture *altTexture = [LTTexture textureWithImage:inputContent];
    OCMStub([mock alternativeTextureForView:view]).andReturn(altTexture);
    OCMExpect([mock presentationView:view drawProcessedContent:altTexture
              withVisibleContentRect:kVisibleContentRect]);
    [view drawToFbo:fbo];
    OCMVerifyAll(mock);
  });

  it(@"should use delegate to draw the processed content", ^{
    [[[[mock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
      expect([LTGLContext currentContext].renderingToScreen).to.beTruthy();
      cv::Mat4b altMat(kContentSize.height, kContentSize.width);
      altMat = kBlue;
      LTTexture *altTexture = [LTTexture textureWithImage:altMat];
      LTRectDrawer *rectDrawer = [[LTRectDrawer alloc] initWithSourceTexture:altTexture];
      [rectDrawer drawRect:CGRectFromSize(view.framebufferSize)
       inFramebufferWithSize:view.framebufferSize fromRect:kVisibleContentRect];
      BOOL returnValue = YES;
      [invocation setReturnValue:&returnValue];
    }] presentationView:view drawProcessedContent:contentTexture withVisibleContentRect:CGRectZero];

    expectedOutput = view.backgroundColor.lt_cvVector;
    expectedOutput(contentAreaInOutput) = kBlue;
    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });

  it(@"should draw the unprocessed content texture if drawProcessedContent returns NO", ^{
    [[[[mock stub] ignoringNonObjectArgs] andReturnValue:@NO]
     presentationView:view drawProcessedContent:contentTexture withVisibleContentRect:CGRectZero];

    expectedOutput = view.backgroundColor.lt_cvVector;
    cv::resize(inputContent, resizedContent, contentAreaInOutput.size(), 0, 0, cv::INTER_NEAREST);
    cv::flip(resizedContent, resizedContent, 0);
    resizedContent.copyTo(expectedOutput(contentAreaInOutput));

    [view drawToFbo:fbo];
    output = [outputTexture image];
    expect($(output)).to.beCloseToMat($(expectedOutput));
  });
});

it(@"should call framebuffer delegate when framebuffer size changes", ^{
  id delegateMock = OCMProtocolMock(@protocol(LTPresentationViewFramebufferDelegate));

  LTPresentationView *view = [[LTPresentationView alloc]
                              initWithFrame:kViewFrame context:[LTGLContext currentContext]
                              contentTexture:contentTexture
                              contentLocationProvider:contentLocationProvider];
  LTAddViewToWindow(view);

  view.framebufferDelegate = delegateMock;

  OCMExpect([delegateMock presentationView:view
                  framebufferChangedToSize:view.frame.size * view.contentScaleFactor]);

  [view layoutIfNeeded];

  OCMVerifyAllWithDelay(delegateMock, 1);
});

SpecEnd
