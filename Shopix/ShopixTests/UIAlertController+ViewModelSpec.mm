// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "UIAlertController+ViewModel.h"

#import "SPXAlertViewModel.h"

SpecBegin(UIAlertController_ViewModel)

__block SPXAlertViewModel *viewModel;

beforeEach(^{
  viewModel = [[SPXAlertViewModel alloc] initWithTitle:@"Title" message:@"Message" buttons:@[
    [[SPXAlertButtonViewModel alloc] initWithTitle:@"OK" action:[RACSignal empty]],
    [[SPXAlertButtonViewModel alloc] initWithTitle:@"Cancel" action:[RACSignal empty]]
  ] defaultButtonIndex:nil];
});

it(@"should create an alert controller with the given title and message", ^{
  auto alertController = [UIAlertController spx_alertControllerWithViewModel:viewModel];

  expect(alertController.title).to.equal(@"Title");
  expect(alertController.message).to.equal(@"Message");
});

it(@"should create an alert controller with the given title and no message", ^{
  auto viewModelWithoutMessage = [[SPXAlertViewModel alloc] initWithTitle:viewModel.title
                                                                  message:nil
                                                                  buttons:viewModel.buttons
                                                       defaultButtonIndex:nil];
  auto alertController =
      [UIAlertController spx_alertControllerWithViewModel:viewModelWithoutMessage];

  expect(alertController.title).to.equal(@"Title");
  expect(alertController.message).to.beNil();
});

it(@"should create an alert controller with the specified actions", ^{
  auto alertController = [UIAlertController spx_alertControllerWithViewModel:viewModel];

  expect(alertController.actions.count).to.equal(2);
  expect(alertController.actions[0].title).to.equal(@"OK");
  expect(alertController.actions[1].title).to.equal(@"Cancel");
  expect(alertController.preferredAction).to.beNil();
});

it(@"should create an alert controller with a preferred action", ^{
  auto viewModelWithDefaultButton = [[SPXAlertViewModel alloc] initWithTitle:viewModel.title
                                                                     message:nil
                                                                     buttons:viewModel.buttons
                                                          defaultButtonIndex:@1];
  auto alertController =
      [UIAlertController spx_alertControllerWithViewModel:viewModelWithDefaultButton];

  expect(alertController.actions.count).to.equal(2);
  expect(alertController.actions[0].title).to.equal(@"OK");
  expect(alertController.actions[1].title).to.equal(@"Cancel");
  expect(alertController.preferredAction).to.equal(alertController.actions[1]);
});

pending(@"should connect alert controller actions with the view model commands", ^{
  // Tests that when a specific alert button is pressed the \c action command on the matching
  // button view-model is being executed. Currently there's no way to fake alert button press.
});

SpecEnd
