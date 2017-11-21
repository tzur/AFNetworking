// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModel+ShopixPresets.h"

SpecBegin(SPXAlertViewModel_ShopixPresets)

__block LTVoidBlock okAction;
__block LTVoidBlock tryAgainAction;
__block LTVoidBlock contactUsAction;
__block LTVoidBlock cancelAction;
__block NSUInteger okActionInvocationCount;
__block NSUInteger tryAgainActionInvocationCount;
__block NSUInteger contactUsActionInvocationCount;
__block NSUInteger cancelActionInvocationCount;

beforeEach(^{
  okActionInvocationCount = 0;
  okAction = ^{
    ++okActionInvocationCount;
  };

  tryAgainActionInvocationCount = 0;
  tryAgainAction = ^{
    ++tryAgainActionInvocationCount;
  };

  contactUsActionInvocationCount = 0;
  contactUsAction = ^{
    ++contactUsActionInvocationCount;
  };

  cancelActionInvocationCount = 0;
  cancelAction = ^{
    ++cancelActionInvocationCount;
  };
});

context(@"successful restoration alert", ^{
  __block SPXAlertViewModel *viewModel;

  beforeEach(^{
    viewModel =
        [SPXAlertViewModel successfulRestorationAlertWithAction:okAction subscriptionRestored:YES];
  });

  it(@"should generate an alert with single button", ^{
    expect(viewModel.buttons.count).to.equal(1);
  });

  it(@"should show different messages based on the subscriptionRestored flag", ^{
    auto subscriptionWasNotRestoredViewModel =
        [SPXAlertViewModel successfulRestorationAlertWithAction:^{} subscriptionRestored:NO];

    expect(viewModel.message).toNot.equal(subscriptionWasNotRestoredViewModel.message);
  });

  it(@"should invoke the given action block when OK button is pressed", ^{
    viewModel.buttons[0].action();

    expect(okActionInvocationCount).to.equal(1);
  });
});

context(@"restoration failed alert", ^{
  __block SPXAlertViewModel *viewModel;

  beforeEach(^{
    viewModel = [SPXAlertViewModel restorationFailedAlertWithTryAgainAction:tryAgainAction
                                                            contactUsAction:contactUsAction
                                                               cancelAction:cancelAction];
  });

  it(@"should generate an alert with 3 buttons", ^{
    expect(viewModel.buttons.count).to.equal(3);
  });

  it(@"should invoke the try again action block when the try again button is pressed", ^{
    viewModel.buttons[0].action();

    expect(tryAgainActionInvocationCount).to.equal(1);
    expect(contactUsActionInvocationCount).to.equal(0);
    expect(cancelActionInvocationCount).to.equal(0);
  });

  it(@"should invoke the contact us action block when the contact us button is pressed", ^{
    viewModel.buttons[1].action();

    expect(tryAgainActionInvocationCount).to.equal(0);
    expect(contactUsActionInvocationCount).to.equal(1);
    expect(cancelActionInvocationCount).to.equal(0);
  });

  it(@"should invoke the cancel action block when the cancel button is pressed", ^{
    viewModel.buttons[2].action();

    expect(tryAgainActionInvocationCount).to.equal(0);
    expect(contactUsActionInvocationCount).to.equal(0);
    expect(cancelActionInvocationCount).to.equal(1);
  });
});

context(@"purchase failed alert", ^{
  __block SPXAlertViewModel *viewModel;

  beforeEach(^{
    viewModel = [SPXAlertViewModel purchaseFailedAlertWithTryAgainAction:tryAgainAction
                                                         contactUsAction:contactUsAction
                                                            cancelAction:cancelAction];
  });

  it(@"should generate an alert with 3 buttons", ^{
    expect(viewModel.buttons.count).to.equal(3);
  });

  it(@"should invoke the try again action block when the try again button is pressed", ^{
    viewModel.buttons[0].action();

    expect(tryAgainActionInvocationCount).to.equal(1);
    expect(contactUsActionInvocationCount).to.equal(0);
    expect(cancelActionInvocationCount).to.equal(0);
  });

  it(@"should invoke the contact us action block when the contact us button is pressed", ^{
    viewModel.buttons[1].action();

    expect(tryAgainActionInvocationCount).to.equal(0);
    expect(contactUsActionInvocationCount).to.equal(1);
    expect(cancelActionInvocationCount).to.equal(0);
  });

  it(@"should invoke the cancel action block when the cancel button is pressed", ^{
    viewModel.buttons[2].action();

    expect(tryAgainActionInvocationCount).to.equal(0);
    expect(contactUsActionInvocationCount).to.equal(0);
    expect(cancelActionInvocationCount).to.equal(1);
  });
});

SpecEnd
