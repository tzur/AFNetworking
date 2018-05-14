// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentView.h"

#import "LTContentInteractionManagerExamples.h"
#import "LTContentNavigationDelegate.h"
#import "LTContentNavigationManagerExamples.h"
#import "LTContentTouchEvent.h"
#import "LTGLContext.h"
#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTPresentationViewDrawDelegate.h"
#import "LTPresentationViewFramebufferDelegate.h"
#import "LTTexture+Factory.h"
#import "LTTouchEvent.h"
#import "LTTouchEventSequenceSplitter.h"
#import "LTTouchEventSequenceValidator.h"
#import "LTTouchEventSequenceValidatorExamples.h"
#import "LTTouchEventView.h"

@interface LTContentView ()
@property (readonly, nonatomic) LTTouchEventView *touchEventView;
@end

SpecBegin(LTContentView)

static const CGFloat kContentScaleFactor = 1;

__block LTGLContext *currentContext;
__block LTTexture *texture;

beforeEach(^{
  currentContext = [LTGLContext currentContext];
  texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 2)];
});

afterEach(^{
  texture = nil;
  currentContext = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly with a context", ^{
    LTContentView *view = [[LTContentView alloc] initWithContext:currentContext];
    expect(view).toNot.beNil();
    expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
    expect(view.contentSize).to.equal(CGSizeMakeUniform(1));
  });

  context(@"initialization with context, content texture and navigation state", ^{
    it(@"should initialize correctly without content texture and without navigation state", ^{
      LTContentView *view = [[LTContentView alloc] initWithContext:currentContext contentTexture:nil
                                                   navigationState:nil];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
      expect(view.contentSize).to.equal(CGSizeMakeUniform(1));
    });

    it(@"should initialize correctly with content texture but without navigation state", ^{
      LTContentView *view = [[LTContentView alloc] initWithContext:currentContext
                                                    contentTexture:texture navigationState:nil];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
      expect(view.contentSize).to.equal(texture.size);
    });

    it(@"should initialize correctly without content texture but with navigation state", ^{
      LTContentView *view = [[LTContentView alloc] initWithContext:currentContext contentTexture:nil
                                                   navigationState:nil];
      LTContentNavigationState *state = [view navigationState];

      view = [[LTContentView alloc] initWithContext:currentContext contentTexture:nil
                                    navigationState:state];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
      expect(view.contentSize).to.equal(CGSizeMakeUniform(1));
      expect(view.navigationState).to.equal(state);
    });

    it(@"should initialize correctly with content texture and with navigation state", ^{
      LTContentView *view = [[LTContentView alloc] initWithContext:currentContext contentTexture:nil
                                                   navigationState:nil];
      LTContentNavigationState *state = [view navigationState];

      view = [[LTContentView alloc] initWithContext:currentContext contentTexture:texture
                                    navigationState:state];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal([UIScreen mainScreen].nativeScale);
      expect(view.contentSize).to.equal(texture.size);
      expect(view.navigationState).to.equal(state);
    });
  });

  context(@"initialization with frame, scale factor, context, content texture, navigation state", ^{
    it(@"should initialize correctly without content texture and without navigation state", ^{
      LTContentView *view =
          [[LTContentView alloc] initWithFrame:CGRectZero contentScaleFactor:kContentScaleFactor
                                       context:currentContext contentTexture:nil
                               navigationState:nil];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
    });

    it(@"should initialize correctly with content texture but without navigation state", ^{
      LTContentView *view =
          [[LTContentView alloc] initWithFrame:CGRectZero contentScaleFactor:kContentScaleFactor
                                       context:currentContext contentTexture:texture
                               navigationState:nil];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
      expect(view.contentSize).to.equal(texture.size);
    });

    it(@"should initialize correctly without content texture but with navigation state", ^{
      LTContentView *view =
          [[LTContentView alloc] initWithFrame:CGRectZero contentScaleFactor:kContentScaleFactor
                                       context:currentContext contentTexture:nil
                               navigationState:nil];
      LTContentNavigationState *state = [view navigationState];

      view = [[LTContentView alloc] initWithFrame:CGRectZero contentScaleFactor:kContentScaleFactor
                                          context:currentContext contentTexture:nil
                                  navigationState:state];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
      expect(view.navigationState).to.equal(state);
    });

    it(@"should initialize correctly with content texture and with navigation state", ^{
      LTContentView *view =
          [[LTContentView alloc] initWithFrame:CGRectZero contentScaleFactor:kContentScaleFactor
                                       context:currentContext contentTexture:texture
                               navigationState:nil];
      LTContentNavigationState *state = [view navigationState];

      view = [[LTContentView alloc] initWithFrame:CGRectZero contentScaleFactor:kContentScaleFactor
                                          context:currentContext contentTexture:texture
                                  navigationState:state];
      expect(view).toNot.beNil();
      expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
      expect(view.contentSize).to.equal(texture.size);
      expect(view.navigationState).to.equal(state);
    });
  });
});

context(@"deallocation", ^{
  it(@"should deallocate", ^{
    id<LTPresentationViewDrawDelegate> drawDelegate =
        OCMProtocolMock(@protocol(LTPresentationViewDrawDelegate));
    id<LTPresentationViewFramebufferDelegate> framebufferDelegate =
        OCMProtocolMock(@protocol(LTPresentationViewFramebufferDelegate));
    id<LTContentNavigationDelegate> navigationDelegate =
        OCMProtocolMock(@protocol(LTContentNavigationDelegate));
    __weak LTContentView *weaklyHeldView;

    @autoreleasepool {
      LTContentView *view = [[LTContentView alloc] initWithContext:currentContext];
      view.drawDelegate = drawDelegate;
      view.framebufferDelegate = framebufferDelegate;
      view.navigationDelegate = navigationDelegate;
      weaklyHeldView = view;
      expect(weaklyHeldView).toNot.beNil();
    }

    expect(weaklyHeldView).to.beNil();
  });
});

context(@"protocols", ^{
  context(@"LTContentCoordinateConverter", ^{
    __block LTContentView *view;

    beforeEach(^{
      view = [[LTContentView alloc] initWithFrame:CGRectMake(0, 0, 2, 3)
                               contentScaleFactor:kContentScaleFactor context:currentContext
                                   contentTexture:nil navigationState:nil];
      [view layoutIfNeeded];
    });

    afterEach(^{
      view = nil;
    });

    it(@"should convert points from content coordinate system to presentation coordinate system", ^{
      CGPoint convertedPoint =
          [view convertPointFromContentToPresentationCoordinates:CGPointMake(1, 1)];
      expect(convertedPoint).to.equal(CGPointMake(2, 3));
    });

    it(@"should convert points from presentation coordinate system to content coordinate system", ^{
      CGPoint convertedPoint =
          [view convertPointFromPresentationToContentCoordinates:CGPointMake(2, 3)];
      expect(convertedPoint).to.equal(CGPointMake(1, 1));
    });
  });

  context(@"LTContentDisplayManager", ^{
    __block LTContentView *view;

    beforeEach(^{
      view = [[LTContentView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)
                               contentScaleFactor:kContentScaleFactor context:currentContext
                                   contentTexture:nil navigationState:nil];
      [view layoutIfNeeded];
    });

    afterEach(^{
      view = nil;
    });

    context(@"snapshot", ^{
      it(@"should provide default snapshot", ^{
        cv::Mat4b expectedMat(1, 1, cv::Vec4b(0, 0, 0, 0));

        LTImage *image = [view snapshotView];

        expect($(image.mat)).to.equalMat($(expectedMat));
      });

      it(@"should provide snapshot", ^{
        LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
        [texture clearColor:LTVector4(1, 0, 0, 1)];

        [view replaceContentWith:texture];

        expect($([view snapshotView].mat)).to.equalMat($(texture.image));
      });
    });

    it(@"should replace content texture", ^{
      LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
      [texture clearColor:LTVector4(1, 0, 0, 1)];

      [view replaceContentWith:texture];

      expect($([view snapshotView].mat)).to.equalMat($(texture.image));
    });

    context(@"draw delegate", ^{
      it(@"should not have draw delegate on default", ^{
        expect(view.drawDelegate).to.beNil();
      });

      it(@"should use given draw delegate", ^{
        id delegateMock = OCMProtocolMock(@protocol(LTPresentationViewDrawDelegate));
        view.drawDelegate = delegateMock;
        OCMExpect([delegateMock presentationView:OCMOCK_ANY drawProcessedContent:OCMOCK_ANY
                          withVisibleContentRect:CGRectFromSize(CGSizeMakeUniform(1))]);

        [view snapshotView];

        OCMVerifyAll(delegateMock);
      });
    });

    context(@"framebuffer size", ^{
      it(@"should provide framebuffer size", ^{
        view = [[LTContentView alloc] initWithFrame:CGRectMake(0, 0, 1, 2)
                                 contentScaleFactor:kContentScaleFactor context:currentContext
                                     contentTexture:nil navigationState:nil];
        [view layoutIfNeeded];
        expect(view.framebufferSize).to.equal(CGSizeMake(1, 2));
      });
    });

    context(@"content texture size", ^{
      it(@"should provide default content texture size", ^{
        expect(view.contentTextureSize).to.equal(CGSizeMakeUniform(1));
      });

      it(@"should provide content texture size", ^{
        LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 2)];
        [view replaceContentWith:texture];
        expect(view.contentTextureSize).to.equal(CGSizeMake(1, 2));
      });
    });

    context(@"content transparency", ^{
      it(@"should provide default indication whether transparency of content is enabled", ^{
        expect(view.contentTransparency).to.beFalsy();
      });

      it(@"should not use content transparency if required", ^{
        LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
        // Use premultiplied alpha values.
        [texture clearColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
        [view replaceContentWith:texture];
        // TODO:(rouven) The alpha value should be 255 rather than 128. This must be fixed when
        // performing a general overhaul of the code, for the sake of correct transparency handling.
        cv::Mat4b expectedMat(1, 1, cv::Vec4b(128, 128, 128, 128));

        view.contentTransparency = NO;

        LTImage *image = [view snapshotView];
        expect($(image.mat)).to.equalMat($(expectedMat));
      });

      it(@"should use content transparency if required", ^{
        LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
        // Use premultiplied alpha values.
        [texture clearColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
        [view replaceContentWith:texture];
        cv::Mat4b expectedMat(1, 1, cv::Vec4b(128, 128, 128, 255));

        view.contentTransparency = YES;

        LTImage *image = [view snapshotView];
        expect($(image.mat)).to.equalMat($(expectedMat));
      });
    });

    context(@"checkerboard pattern", ^{
      it(@"should provide default indication whether checkerboard pattern is enabled", ^{
        expect(view.checkerboardPattern).to.beFalsy();
      });

      it(@"should not use checkerboard pattern if required", ^{
        LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
        // Use premultiplied alpha values.
        [texture clearColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
        [view replaceContentWith:texture];
        cv::Mat4b expectedMat(1, 1, cv::Vec4b(128, 128, 128, 255));

        view.contentTransparency = YES;
        view.checkerboardPattern = NO;

        LTImage *image = [view snapshotView];
        expect($(image.mat)).to.equalMat($(expectedMat));
      });

      it(@"should use checkerboard pattern if required", ^{
        view = [[LTContentView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)
                                 contentScaleFactor:kContentScaleFactor context:currentContext
                                     contentTexture:nil navigationState:nil];
        [view layoutIfNeeded];
        cv::Mat4b expectedMat = LTWhiteGrayCheckerboardPattern(CGSizeMakeUniform(32), 16);
        LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMake(32, 32)];
        // Use premultiplied alpha values.
        [texture clearColor:LTVector4(0, 0, 0, 0)];
        [view replaceContentWith:texture];

        view.contentTransparency = YES;
        view.checkerboardPattern = YES;

        LTImage *image = [view snapshotView];
        expect($(image.mat)).to.equalMat($(expectedMat));
      });
    });

    it(@"should provide default background color", ^{
      expect(view.backgroundColor).to.equal([UIColor blackColor]);
    });

    it(@"should set backgroundColor", ^{
      view = [[LTContentView alloc] initWithFrame:CGRectMake(0, 0, 1, 3)
                               contentScaleFactor:kContentScaleFactor context:currentContext
                                   contentTexture:nil navigationState:nil];
      [view layoutIfNeeded];
      cv::Mat4b expectedMat = (cv::Mat4b(3, 1) << cv::Vec4b(255, 0, 0, 255),
                                                  cv::Vec4b(0, 0, 0, 0),
                                                  cv::Vec4b(255, 0, 0, 255));

      view.backgroundColor = [UIColor redColor];

      expect($([view snapshotView].mat)).to.equalMat($(expectedMat));
    });
  });

  context(@"LTContentInteractionManager protocol", ^{
    __block LTContentView *view;

    beforeEach(^{
      view = [[LTContentView alloc] initWithContext:[LTGLContext currentContext]];
    });

    itShouldBehaveLike(kLTContentInteractionManagerExamples, ^{
      return @{
        kLTContentInteractionManager: view,
        kLTContentInteractionManagerView: view.touchEventView
      };
    });

    it(@"should retrieve whether content touch events are being received from touch event view", ^{
      LTTouchEventView *partialTouchEventView = OCMPartialMock(view.touchEventView);
      OCMStub([(id)partialTouchEventView isCurrentlyReceivingTouchEvents]).andReturn(YES);
      expect(view.isCurrentlyReceivingContentTouchEvents).to.beTruthy();
    });
  });

  context(@"LTContentLocationProvider", ^{
    __block LTContentView *view;

    static const CGRect kViewFrame = CGRectFromSize(CGSizeMake(10, 20));
    static const CGFloat kContentScaleFactor = 3;

    beforeEach(^{
      view = [[LTContentView alloc] initWithFrame:kViewFrame contentScaleFactor:kContentScaleFactor
                                          context:[LTGLContext currentContext]
                                   contentTexture:nil navigationState:nil];
    });

    afterEach(^{
      view = nil;
    });

    it(@"should have correct default values", ^{
      expect(view.contentScaleFactor).to.equal(kContentScaleFactor);
      expect(view.contentInset).to.equal(UIEdgeInsetsZero);
      expect(view.maxZoomScale).to.equal(16);
    });

    it(@"should have correct zoom scale according to the size of content texture", ^{
      LTTexture *contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(120, 80)];
      [view replaceContentWith:contentTexture];
      expect(view.zoomScale).to.beCloseTo(0.25);

      contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(60, 40)];
      [view replaceContentWith:contentTexture];
      expect(view.zoomScale).to.beCloseTo(0.5);
    });

    it(@"should have correct content size according to size of content texture", ^{
      LTTexture *contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(120, 80)];
      [view replaceContentWith:contentTexture];
      expect(view.contentSize).to.equal(contentTexture.size);

      contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(60, 40)];
      [view replaceContentWith:contentTexture];
      expect(view.contentSize).to.equal(contentTexture.size);
    });

    it(@"should have correct visible content rect according to size of content texture", ^{
      LTTexture *contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(120, 80)];
      [view replaceContentWith:contentTexture];
      expect(view.visibleContentRect).to.equal(CGRectMake(0, -84, 120, 240));

      contentTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(60, 40)];
      [view replaceContentWith:contentTexture];
      expect(view.visibleContentRect).to.equal(CGRectMake(0, -42, 60, 120));
    });
  });

  context(@"LTContentNavigationManager", ^{
    static const CGSize kViewSize = CGSizeMake(10, 20);
    static const CGRect kViewFrame = CGRectFromSize(kViewSize);
    static const CGSize kContentSize = CGSizeMakeUniform(100);
    static const CGRect kTargetRect = CGRectMake(25, 0, 50, 100);
    static const CGRect kUnreachableTargetRect = CGRectMake(-1, 0, 50, 100);
    static const CGRect kExpectedRect = CGRectMake(0, 0, 50, 100);
    static const CGFloat kContentScaleFactor = 3;

    __block LTContentView *view;
    __block LTContentView *otherView;

    beforeEach(^{
      LTTexture *texture = [LTTexture byteRGBATextureWithSize:kContentSize];
      view = [[LTContentView alloc] initWithFrame:kViewFrame contentScaleFactor:kContentScaleFactor
                                          context:[LTGLContext currentContext]
                                   contentTexture:texture navigationState:nil];
      otherView = [[LTContentView alloc] initWithFrame:kViewFrame
                                    contentScaleFactor:kContentScaleFactor
                                               context:[LTGLContext currentContext]
                                        contentTexture:texture navigationState:nil];
    });

    afterEach(^{
      view = nil;
      otherView = nil;
    });

    itShouldBehaveLike(kLTContentNavigationManagerExamples, ^{
      return @{
        kLTContentNavigationManager: view,
        kLTContentNavigationManagerReachableRect: $(kTargetRect),
        kLTContentNavigationManagerUnreachableRect: $(kUnreachableTargetRect),
        kLTContentNavigationManagerExpectedRect: $(kExpectedRect),
        kAnotherLTContentNavigationManager: otherView
      };
    });
  });

  context(@"LTContentRefreshing", ^{
    static const CGRect kContentRect = CGRectFromSize(CGSizeMakeUniform(1));

    __block LTContentView *view;
    __block id drawDelegateMock;

    beforeEach(^{
      view = [[LTContentView alloc] initWithFrame:kContentRect
                               contentScaleFactor:kContentScaleFactor context:currentContext
                                   contentTexture:nil navigationState:nil];
      [view layoutIfNeeded];
      drawDelegateMock = OCMProtocolMock(@protocol(LTPresentationViewDrawDelegate));
      view.drawDelegate = drawDelegateMock;
    });

    afterEach(^{
      drawDelegateMock = nil;
      view = nil;
    });

    it(@"should request delegate to update the image content", ^{
      OCMExpect([drawDelegateMock presentationView:OCMOCK_ANY updateContentInRect:kContentRect]);

      [view setNeedsDisplayContent];

      [view snapshotView];
      OCMVerifyAll(drawDelegateMock);
    });

    it(@"should request delegate to update a part of the image content", ^{
      CGRect rect = CGRectFromSize(CGSizeMakeUniform(0.5));
      OCMExpect([drawDelegateMock presentationView:OCMOCK_ANY updateContentInRect:rect]);

      [view setNeedsDisplayContentInRect:rect];

      [view snapshotView];
      OCMVerifyAll(drawDelegateMock);
    });

    it(@"should not request delegate to update any part of the image content if not required", ^{
      [[[drawDelegateMock reject] ignoringNonObjectArgs] presentationView:OCMOCK_ANY
                                                      updateContentInRect:CGRectZero];

      [view setNeedsDisplay];

      [view snapshotView];
      OCMVerifyAll(drawDelegateMock);
    });

    it(@"should request delegate to update the image content only once per update request", ^{
      __block NSUInteger numberOfDelegateCalls = 0;
      OCMStub([drawDelegateMock presentationView:OCMOCK_ANY updateContentInRect:kContentRect])
          .andDo(^(NSInvocation *) {
        ++numberOfDelegateCalls;
      });

      [view setNeedsDisplayContent];

      [view snapshotView];
      [view snapshotView];
      expect(numberOfDelegateCalls).to.equal(1);
    });
  });
});

context(@"touch event sequence pipeline", ^{
  __block LTContentView *view;

  beforeEach(^{
    view = [[LTContentView alloc] initWithContext:[LTGLContext currentContext]];
  });

  it(@"should use a touch event sequence validator concatenated to the touch event view", ^{
    expect(view.touchEventView.delegate).to.beKindOf([LTTouchEventSequenceValidator class]);
  });

  it(@"should use a touch event sequence splitter concatenated to the touch event validator", ^{
    LTTouchEventSequenceValidator *validator = view.touchEventView.delegate;
    LTTouchEventSequenceSplitter *splitter = validator.delegate;
    expect(splitter).to.beKindOf([LTTouchEventSequenceSplitter class]);
  });

  it(@"should be the delegate of the touch event sequence splitter", ^{
    LTTouchEventSequenceValidator *validator = view.touchEventView.delegate;
    LTTouchEventSequenceSplitter *splitter = validator.delegate;
    expect(splitter.delegate).to.beIdenticalTo(view);
  });

  itShouldBehaveLike(kLTTouchEventSequenceValidatorExamples, ^{
    return @{kLTTouchEventSequenceValidatorExamplesDelegate: view.touchEventView.delegate};
  });
});

SpecEnd
