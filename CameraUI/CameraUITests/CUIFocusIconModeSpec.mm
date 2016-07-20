// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIFocusIconMode.h"

SpecBegin(CUIFocusIconMode)

static const CGPoint kPoint = CGPointMake(2.0, 3.0);
static const CGPoint kPoint2 = CGPointMake(1.0, 3.0);

it(@"should create definite focus", ^{
  CUIFocusIconMode *definiteFocus = [CUIFocusIconMode definiteFocusAtPosition:kPoint];
  expect(definiteFocus.mode).to.equal(CUIFocusIconDisplayModeDefinite);
  expect([definiteFocus.position CGPointValue]).to.equal(kPoint);
});

it(@"should create indefinite focus", ^{
  CUIFocusIconMode *indefiniteFocus = [CUIFocusIconMode indefiniteFocusAtPosition:kPoint];
  expect(indefiniteFocus.mode).to.equal(CUIFocusIconDisplayModeIndefinite);
  expect([indefiniteFocus.position CGPointValue]).to.equal(kPoint);
});

it(@"should create hidden focus", ^{
  CUIFocusIconMode *hiddenFocus = [CUIFocusIconMode hiddenFocus];
  expect(hiddenFocus.mode).to.equal(CUIFocusIconDisplayModeHidden);
});

context(@"NSObject protocol", ^{
  __block CUIFocusIconMode *focusIconMode;
  __block CUIFocusIconMode *equalFocusIconMode;

  beforeEach(^{
    focusIconMode = [CUIFocusIconMode hiddenFocus];
    equalFocusIconMode = [CUIFocusIconMode hiddenFocus];
  });

  context(@"equality", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([focusIconMode isEqual:focusIconMode]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      expect([focusIconMode isEqual:nil]).to.beFalsy();
    });

    it(@"should return YES when comparing to an equal focus icon mode event", ^{
      expect([focusIconMode isEqual:equalFocusIconMode]).to.beTruthy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([focusIconMode isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to different focus icon mode event", ^{
      CUIFocusIconMode *anotherFocusIconMode = [CUIFocusIconMode definiteFocusAtPosition:kPoint];
      expect([focusIconMode isEqual:anotherFocusIconMode]).to.beFalsy();
    });

    it(@"should return NO when comparing different positions", ^{
      CUIFocusIconMode *definiteFocus1 = [CUIFocusIconMode definiteFocusAtPosition:kPoint2];
      CUIFocusIconMode *definiteFocus2 =
          [CUIFocusIconMode definiteFocusAtPosition:kPoint];
      expect([definiteFocus1 isEqual:definiteFocus2]).to.beFalsy();
    });

    it(@"should return NO when comparing different modes", ^{
      CUIFocusIconMode *definiteFocus = [CUIFocusIconMode definiteFocusAtPosition:kPoint];
      CUIFocusIconMode *indefiniteFocus = [CUIFocusIconMode indefiniteFocusAtPosition:kPoint];
      expect([definiteFocus isEqual:indefiniteFocus]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      expect(focusIconMode.hash).to.equal(equalFocusIconMode.hash);
    });
  });
});

SpecEnd
