// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewController.h"

#import "SPXAlertViewControllerProvider.h"
#import "SPXFakeMailComposeViewController.h"
#import "SPXFeedbackComposeViewControllerProvider.h"
#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionTermsViewModel.h"
#import "SPXSubscriptionViewModel.h"

SpecBegin(SPXSubscriptionViewController)

__block SPXFakeMailComposeViewController *mailComposeViewController;
__block id<SPXFeedbackComposeViewControllerProvider> feedbackViewControllerProvider;
__block SPXSubscriptionViewModel *viewModel;
__block SPXSubscriptionViewController *viewController;

beforeEach(^{
  id<SPXSubscriptionButtonsFactory> buttonsFactory =
      OCMProtocolMock(@protocol(SPXSubscriptionButtonsFactory));
  id<SPXAlertViewControllerProvider> alertsProvider =
      OCMProtocolMock(@protocol(SPXAlertViewControllerProvider));
  mailComposeViewController = OCMClassMock([SPXFakeMailComposeViewController class]);
  feedbackViewControllerProvider =
      OCMProtocolMock(@protocol(SPXFeedbackComposeViewControllerProvider));

  viewModel = OCMClassMock([SPXSubscriptionViewModel class]);
  auto termsViewModel = [[SPXSubscriptionTermsViewModel alloc]
                         initWithFullTerms:[NSURL URLWithString:@""]
                         privacyPolicy:[NSURL URLWithString:@""]];
  OCMStub([viewModel termsViewModel]).andReturn(termsViewModel);

  viewController = [[SPXSubscriptionViewController alloc]
                    initWithViewModel:viewModel alertControllerProvider:alertsProvider
                    mailComposerProvider:feedbackViewControllerProvider
                    subscriptionButtonsFactory:buttonsFactory];
});

context(@"mail composer", ^{
  __block RACSubject *feedbackComposerRequestedSubject;
  __block RACSubject *dismissRequestedSubject;
  __block BOOL blockInvoked;
  __block LTVoidBlock completionBlock;
  __block SPXSubscriptionViewController *viewControllerPartialMock;

  beforeEach(^{
    dismissRequestedSubject = [RACSubject subject];
    OCMStub([mailComposeViewController dismissRequested]).andReturn(dismissRequestedSubject);
    feedbackComposerRequestedSubject = [RACSubject subject];
    OCMStub([viewModel feedbackComposerRequested]).andReturn(feedbackComposerRequestedSubject);
    blockInvoked = NO;
    completionBlock = ^{
      blockInvoked = YES;
    };

    viewControllerPartialMock = OCMPartialMock(viewController);
    UIView __unused *view = viewControllerPartialMock.view;
  });

  afterEach(^{
    viewControllerPartialMock = nil;
  });

  it(@"should present the feedback mail composer when requested", ^{
    OCMStub([feedbackViewControllerProvider createFeedbackComposeViewController])
        .andReturn(mailComposeViewController);

    OCMExpect([viewControllerPartialMock presentViewController:mailComposeViewController
                                                      animated:YES completion:OCMOCK_ANY]);

    [feedbackComposerRequestedSubject sendNext:^{}];

    OCMVerifyAll(viewControllerPartialMock);
  });

  it(@"should dismiss the feedback mail composer when requested", ^{
    OCMStub([feedbackViewControllerProvider createFeedbackComposeViewController])
        .andReturn(mailComposeViewController);

    OCMStub([viewControllerPartialMock presentViewController:mailComposeViewController
                                                      animated:YES completion:OCMOCK_ANY]);
    OCMExpect([viewControllerPartialMock dismissViewControllerAnimated:YES completion:OCMOCK_ANY]);

    [feedbackComposerRequestedSubject sendNext:^{}];
    [dismissRequestedSubject sendNext:[RACUnit defaultUnit]];

    OCMVerifyAll(viewControllerPartialMock);
  });

  it(@"should invoke the completion block on mail composer dismissal", ^{
    OCMStub([feedbackViewControllerProvider createFeedbackComposeViewController])
        .andReturn(mailComposeViewController);

    OCMStub([viewControllerPartialMock presentViewController:mailComposeViewController
                                                    animated:YES completion:OCMOCK_ANY]);
    OCMStub([viewControllerPartialMock dismissViewControllerAnimated:YES
                                                          completion:[OCMArg invokeBlock]]);

    [feedbackComposerRequestedSubject sendNext:completionBlock];
    [dismissRequestedSubject sendNext:[RACUnit defaultUnit]];

    expect(blockInvoked).to.beTruthy();
  });

  it(@"should invoke the completion block if the mail composer is nil", ^{
    [feedbackComposerRequestedSubject sendNext:completionBlock];

    expect(blockInvoked).to.beTruthy();
  });
});

SpecEnd
