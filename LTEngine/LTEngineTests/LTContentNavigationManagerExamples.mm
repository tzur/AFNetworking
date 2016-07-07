// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContentNavigationManagerExamples.h"

#import "LTContentLocationProvider.h"
#import "LTContentNavigationDelegate.h"
#import "LTContentNavigationManager.h"

NSString * const kLTContentNavigationManagerExamples = @"LTContentNavigationManagerExamples";
NSString * const kLTContentNavigationManager = @"LTContentNavigationManager";
NSString * const kLTContentNavigationManagerReachableRect =
    @"LTContentNavigationManagerReachableRect";
NSString * const kLTContentNavigationManagerUnreachableRect =
    @"LTContentNavigationManagerUnreachableRect";
NSString * const kLTContentNavigationManagerExpectedRect =
    @"LTContentNavigationManagerExpectedRect";
NSString * const kAnotherLTContentNavigationManager = @"AnotherLTContentNavigationManager";

SharedExamplesBegin(LTContentNavigationManager)

sharedExamplesFor(kLTContentNavigationManagerExamples, ^(NSDictionary *data) {
  static const CGFloat kEpsilon = 1e-6;

  __block id<LTContentLocationProvider, LTContentNavigationManager> manager;
  __block CGRect targetRectInPixels;

  beforeEach(^{
    manager = data[kLTContentNavigationManager];
    targetRectInPixels = [data[kLTContentNavigationManagerReachableRect] CGRectValue];
  });

  afterEach(^{
    manager = nil;
  });

  context(@"programmatic updates of content rectangle", ^{
    context(@"reachable rectangle", ^{
      it(@"should zoom to a provided rectangle", ^{
        expect(manager.visibleContentRect).toNot.equal(targetRectInPixels);
        [manager zoomToRect:targetRectInPixels animated:NO];
        expect(manager.visibleContentRect.origin).to.beCloseToPointWithin(targetRectInPixels.origin,
                                                                          kEpsilon);
        expect(manager.visibleContentRect.size).to.beCloseToSizeWithin(targetRectInPixels.size,
                                                                       kEpsilon);
      });

      it(@"should zoom to a provided reachable rectangle, with animation", ^{
        expect(manager.visibleContentRect).toNot.equal(targetRectInPixels);
        [manager zoomToRect:targetRectInPixels animated:YES];
        expect(manager.visibleContentRect.origin.x)
            .will.beCloseToWithin(targetRectInPixels.origin.x, kEpsilon);
        expect(manager.visibleContentRect.origin.y)
            .will.beCloseToWithin(targetRectInPixels.origin.y, kEpsilon);
        expect(manager.visibleContentRect.size.width)
            .will.beCloseToWithin(targetRectInPixels.size.width, kEpsilon);
        expect(manager.visibleContentRect.size.height)
            .will.beCloseToWithin(targetRectInPixels.size.height, kEpsilon);
      });
    });

    context(@"unreachable rectangle", ^{
      __block CGRect unreachableTargetRectInPixels;
      __block CGRect expectedRect;

      beforeEach(^{
        unreachableTargetRectInPixels =
            [data[kLTContentNavigationManagerUnreachableRect] CGRectValue];
        expectedRect = [data[kLTContentNavigationManagerExpectedRect] CGRectValue];
      });

      it(@"should zoom as close as possible to a provided rectangle", ^{
        expect(manager.visibleContentRect).toNot.equal(expectedRect);
        [manager zoomToRect:unreachableTargetRectInPixels animated:NO];
        expect(manager.visibleContentRect.origin).to.beCloseToPointWithin(expectedRect.origin,
                                                                          kEpsilon);
        expect(manager.visibleContentRect.size).to.beCloseToSizeWithin(expectedRect.size, kEpsilon);
      });

      it(@"should zoom as close as possible to a provided reachable rectangle, with animation", ^{
        expect(manager.visibleContentRect).toNot.equal(expectedRect);
        [manager zoomToRect:unreachableTargetRectInPixels animated:YES];
        expect(manager.visibleContentRect.origin.x)
            .will.beCloseToWithin(expectedRect.origin.x, kEpsilon);
        expect(manager.visibleContentRect.origin.y)
            .will.beCloseToWithin(expectedRect.origin.y, kEpsilon);
        expect(manager.visibleContentRect.size.width)
            .will.beCloseToWithin(expectedRect.size.width, kEpsilon);
        expect(manager.visibleContentRect.size.height)
            .will.beCloseToWithin(expectedRect.size.height, kEpsilon);
      });
    });
  });

  context(@"navigation state", ^{
    it(@"should provide its navigation state", ^{
      expect(manager.navigationState).toNot.beNil();
    });

    it(@"should navigate to a given navigation state", ^{
      id<LTContentLocationProvider, LTContentNavigationManager> otherManager =
          data[kAnotherLTContentNavigationManager];
      expect(manager.visibleContentRect.origin)
          .to.beCloseToPointWithin(otherManager.visibleContentRect.origin, kEpsilon);
      expect(manager.visibleContentRect.size)
          .to.beCloseToSizeWithin(otherManager.visibleContentRect.size, kEpsilon);

      [otherManager zoomToRect:targetRectInPixels animated:NO];
      expect(manager.visibleContentRect).notTo.equal(otherManager.visibleContentRect);

      [manager navigateToState:otherManager.navigationState];
      expect(manager.visibleContentRect.origin)
          .to.beCloseToPointWithin(targetRectInPixels.origin, kEpsilon);
      expect(manager.visibleContentRect.size).to.beCloseToSizeWithin(targetRectInPixels.size,
                                                                     kEpsilon);
    });
  });

  context(@"delegate", ^{
    it(@"should initially not have a delegate", ^{
      expect(manager.navigationDelegate).to.beNil();
    });

    it(@"should inform its delegate about navigation events following zoom requests", ^{
      id navigationDelegateMock = OCMProtocolMock(@protocol(LTContentNavigationDelegate));
      manager.navigationDelegate = navigationDelegateMock;

      OCMExpect([[navigationDelegateMock ignoringNonObjectArgs] navigationManager:manager
                                                         didNavigateToVisibleRect:CGRectZero])
          .andDo(^(NSInvocation *invocation) {
        CGRect rect;
        [invocation getArgument:&rect atIndex:3];
        expect(rect.origin).to.beCloseToPointWithin(targetRectInPixels.origin, kEpsilon);
        expect(rect.size).to.beCloseToSizeWithin(targetRectInPixels.size, kEpsilon);
      });

      [manager zoomToRect:targetRectInPixels animated:NO];

      OCMVerifyAll(navigationDelegateMock);
    });

    it(@"should inform its delegate about navigation events following navigation state updates", ^{
      id navigationDelegateMock = OCMProtocolMock(@protocol(LTContentNavigationDelegate));
      manager.navigationDelegate = navigationDelegateMock;
      CGRect currentRectInPixels = manager.visibleContentRect;
      LTContentNavigationState *navigationState = manager.navigationState;
      [manager zoomToRect:targetRectInPixels animated:NO];

      OCMExpect([navigationDelegateMock navigationManager:manager
                                 didNavigateToVisibleRect:currentRectInPixels]);

      [manager navigateToState:navigationState];

      OCMVerifyAll(navigationDelegateMock);
    });
  });

  context(@"bouncing", ^{
    it(@"should initially not enforce bouncing to aspect fit", ^{
      expect(manager.bounceToAspectFit).to.beFalsy();
    });

    it(@"should update whether bouncing to aspect fit is enforced", ^{
      manager.bounceToAspectFit = YES;
      expect(manager.bounceToAspectFit).to.beTruthy();
    });

    it(@"should bounce to aspect fit if requested", ^{
      CGRect expectedRect = manager.visibleContentRect;
      [manager zoomToRect:targetRectInPixels animated:NO];
      expect(manager.visibleContentRect.origin).toNot.beCloseToPointWithin(expectedRect.origin,
                                                                        kEpsilon);
      expect(manager.visibleContentRect.size).toNot.beCloseToSizeWithin(expectedRect.size,
                                                                        kEpsilon);
      manager.bounceToAspectFit = YES;
      expect(manager.visibleContentRect.origin.x)
          .will.beCloseToWithin(expectedRect.origin.x, kEpsilon);
      expect(manager.visibleContentRect.origin.y)
          .will.beCloseToWithin(expectedRect.origin.y, kEpsilon);
      expect(manager.visibleContentRect.size.width)
          .will.beCloseToWithin(expectedRect.size.width, kEpsilon);
      expect(manager.visibleContentRect.size.height)
          .will.beCloseToWithin(expectedRect.size.height, kEpsilon);
    });
  });
});

SharedExamplesEnd
