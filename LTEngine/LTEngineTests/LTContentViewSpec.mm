// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentView.h"

#import "LTContentInteractionManagerExamples.h"
#import "LTContentNavigationDelegate.h"
#import "LTContentTouchEvent.h"
#import "LTGLContext.h"
#import "LTImage.h"
#import "LTOpenCVExtensions.h"
#import "LTTexture+Factory.h"
#import "LTTouchEvent.h"
#import "LTTouchEventView.h"
#import "LTViewDelegates.h"

@interface LTContentView ()
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;
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
                                       context:currentContext contentTexture:nil navigationState:nil];
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
                                       context:currentContext contentTexture:nil navigationState:nil];
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
        [texture clearWithColor:LTVector4(1, 0, 0, 1)];

        [view replaceContentWith:texture];

        expect($([view snapshotView].mat)).to.equalMat($(texture.image));
      });
    });

    it(@"should replace content texture", ^{
      LTTexture *texture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
      [texture clearWithColor:LTVector4(1, 0, 0, 1)];

      [view replaceContentWith:texture];

      expect($([view snapshotView].mat)).to.equalMat($(texture.image));
    });

    context(@"draw delegate", ^{
      it(@"should not have draw delegate on default", ^{
        expect(view.drawDelegate).to.beNil();
      });

      it(@"should use given framebuffer delegate", ^{
        id delegateMock = OCMProtocolMock(@protocol(LTViewDrawDelegate));
        view.drawDelegate = delegateMock;
        OCMExpect([delegateMock ltView:OCMOCK_ANY drawProcessedContent:OCMOCK_ANY
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
        [texture clearWithColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
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
        [texture clearWithColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
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
        [texture clearWithColor:LTVector4(0.5, 0.5, 0.5, 0.5)];
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
        [texture clearWithColor:LTVector4(0, 0, 0, 0)];
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
    static const CGSize kViewSize = CGSizeMake(100, 200);
    static const CGRect kViewFrame = CGRectFromSize(kViewSize);

    __block LTContentView *view;
    __block LTContentView *otherView;
    __block CGRect targetRect;

    beforeEach(^{
      view = [[LTContentView alloc] initWithFrame:kViewFrame contentScaleFactor:kContentScaleFactor
                                          context:[LTGLContext currentContext] contentTexture:nil
                                  navigationState:nil];
      otherView = [[LTContentView alloc] initWithFrame:kViewFrame
                                    contentScaleFactor:kContentScaleFactor
                                               context:[LTGLContext currentContext]
                                        contentTexture:nil navigationState:nil];
      targetRect = CGRectFromOriginAndSize(CGPointMake(1, 1), view.contentSize);
      [view zoomToRect:targetRect animated:NO];
    });

    it(@"should navigate to a given state", ^{
      expect(otherView.navigationState).notTo.equal(view.navigationState);
      [otherView navigateToState:view.navigationState];
      expect(otherView.navigationState).to.equal(view.navigationState);
    });

    context(@"delegate", ^{
      it(@"should initially not have a delegate", ^{
        view = [[LTContentView alloc] initWithContext:[LTGLContext currentContext]];
        expect(view.navigationDelegate).to.beNil();
      });

      it(@"should inform its delegate about navigation events", ^{
        id navigationDelegateMock = OCMProtocolMock(@protocol(LTContentNavigationDelegate));
        otherView.navigationDelegate = navigationDelegateMock;
        CGRect visibleRect = CGRectMake(0, -0.5, 1, 2);
        OCMExpect([navigationDelegateMock navigationManager:otherView
                                   didNavigateToVisibleRect:visibleRect]);

        [otherView navigateToState:view.navigationState];

        OCMVerifyAll(navigationDelegateMock);
      });
    });

    context(@"bouncing", ^{
      it(@"should initially not enforce bouncing to minimum scale", ^{
        expect(view.bounceToMinimumScale).to.beFalsy();
      });

      it(@"should update whether bouncing to minimum scale is enforced", ^{
        view.bounceToMinimumScale = YES;
        expect(view.bounceToMinimumScale).to.beTruthy();
      });
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
      drawDelegateMock = OCMProtocolMock(@protocol(LTViewDrawDelegate));
      view.drawDelegate = drawDelegateMock;
    });

    afterEach(^{
      drawDelegateMock = nil;
      view = nil;
    });

    it(@"should request delegate to update the image content", ^{
      OCMExpect([drawDelegateMock ltView:OCMOCK_ANY updateContentInRect:kContentRect]);

      [view setNeedsDisplayContent];

      [view snapshotView];
      OCMVerifyAll(drawDelegateMock);
    });

    it(@"should request delegate to update a part of the image content", ^{
      CGRect rect = CGRectFromSize(CGSizeMakeUniform(0.5));
      OCMExpect([drawDelegateMock ltView:OCMOCK_ANY updateContentInRect:rect]);

      [view setNeedsDisplayContentInRect:rect];

      [view snapshotView];
      OCMVerifyAll(drawDelegateMock);
    });

    it(@"should not request delegate to update any part of the image content if not required", ^{
      [[[drawDelegateMock reject] ignoringNonObjectArgs] ltView:OCMOCK_ANY
                                            updateContentInRect:CGRectZero];

      [view setNeedsDisplay];

      [view snapshotView];
      OCMVerifyAll(drawDelegateMock);
    });

    it(@"should request delegate to update the image content only once per update request", ^{
      __block NSUInteger numberOfDelegateCalls = 0;
      OCMStub([drawDelegateMock ltView:OCMOCK_ANY updateContentInRect:kContentRect])
          .andDo(^(NSInvocation *) {
        ++numberOfDelegateCalls;
      });

      [view setNeedsDisplayContent];

      [view snapshotView];
      [view snapshotView];
      expect(numberOfDelegateCalls).to.equal(1);
    });
  });

  context(@"LTContentTouchEventProvider", ^{
    __block LTContentView *view;

    beforeEach(^{
      view = [[LTContentView alloc] initWithFrame:CGRectMake(0, 0, 1, 2)
                               contentScaleFactor:kContentScaleFactor context:currentContext
                                   contentTexture:nil navigationState:nil];
      [view layoutIfNeeded];
    });

    afterEach(^{
      view = nil;
    });

    it(@"should correctly provide stationary content touch events", ^{
      id touchEventViewMock = OCMPartialMock(view.touchEventView);

      id touchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
      id anotherTouchEventMock = OCMProtocolMock(@protocol(LTTouchEvent));
      OCMStub([touchEventMock copyWithZone:nil]).andReturn(touchEventMock);
      OCMStub([touchEventMock sequenceID]).andReturn(0);
      OCMStub([touchEventMock viewLocation]).andReturn(CGPointMake(0.5, 1));
      OCMStub([touchEventMock previousViewLocation]).andReturn(CGPointZero);
      OCMStub([anotherTouchEventMock copyWithZone:nil]).andReturn(anotherTouchEventMock);
      OCMStub([anotherTouchEventMock sequenceID]).andReturn(1);
      OCMStub([anotherTouchEventMock viewLocation]).andReturn(CGPointMake(1, 2));
      OCMStub([anotherTouchEventMock previousViewLocation]).andReturn(CGPointZero);

      NSSet<id<LTTouchEvent>> *stationaryTouchEvents =
          [NSSet setWithArray:@[touchEventMock, anotherTouchEventMock]];

      OCMStub([touchEventViewMock stationaryTouchEvents]).andReturn(stationaryTouchEvents);

      LTContentTouchEvents *touchEvents = [[view stationaryContentTouchEvents] allObjects];

      expect(touchEvents).to.haveACountOf(2);

      id<LTContentTouchEvent> contentTouchEvent = !touchEvents.firstObject.sequenceID ?
          touchEvents.firstObject : touchEvents.lastObject;
      id<LTContentTouchEvent> otherContentTouchEvent = touchEvents.firstObject.sequenceID ?
          touchEvents.firstObject : touchEvents.lastObject;

      expect(contentTouchEvent.sequenceID).to.equal(0);
      expect(contentTouchEvent.contentLocation).to.equal(CGPointMake(0.5, 0));
      expect(contentTouchEvent.previousContentLocation).to.equal(CGPointMake(0, -1));
      expect(contentTouchEvent.contentSize).to.equal(CGSizeMakeUniform(1));
      expect(contentTouchEvent.contentZoomScale).to.equal(1);

      expect(otherContentTouchEvent.sequenceID).to.equal(1);
      expect(otherContentTouchEvent.contentLocation).to.equal(CGPointMake(1, 1));
      expect(otherContentTouchEvent.previousContentLocation).to.equal(CGPointMake(0, -1));
      expect(otherContentTouchEvent.contentSize).to.equal(CGSizeMakeUniform(1));
      expect(otherContentTouchEvent.contentZoomScale).to.equal(1);
    });
  });
});

SpecEnd
