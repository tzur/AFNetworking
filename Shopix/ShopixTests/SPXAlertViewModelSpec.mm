// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModel.h"

SpecBegin(SPXAlertButtonViewModel)

it(@"should initialize with the given title", ^{
  auto viewModel = [[SPXAlertButtonViewModel alloc] initWithTitle:@"OK" action:^{}];

  expect(viewModel.title).to.equal(@"OK");
});

it(@"should subscribe to the action signal when the action command is executed", ^{
  __block BOOL wasExecuted = NO;
  auto actionBlock = ^{
    wasExecuted = YES;
  };
  auto viewModel = [[SPXAlertButtonViewModel alloc] initWithTitle:@"OK" action:actionBlock];

  viewModel.action();

  expect(wasExecuted).will.beTruthy();
});

SpecEnd

SpecBegin(SPXAlertViewModel)

__block NSArray<SPXAlertButtonViewModel *> *buttons;

beforeEach(^{
  buttons = @[
    [[SPXAlertButtonViewModel alloc] initWithTitle:@"OK" action:^{}],
    [[SPXAlertButtonViewModel alloc] initWithTitle:@"Cancel" action:^{}]
  ];
});

it(@"should initialize with the specified properties", ^{
  auto viewModel = [[SPXAlertViewModel alloc] initWithTitle:@"Title" message:@"Message"
                                                    buttons:buttons defaultButtonIndex:@0];

  expect(viewModel.title).to.equal(@"Title");
  expect(viewModel.message).to.equal(@"Message");
  expect(viewModel.buttons).to.equal(buttons);
  expect(viewModel.defaultButtonIndex).to.equal(@0);
});

it(@"should initialize with the nil message", ^{
  auto viewModel = [[SPXAlertViewModel alloc] initWithTitle:@"Title" message:nil buttons:buttons
                                         defaultButtonIndex:@1];

  expect(viewModel.title).to.equal(@"Title");
  expect(viewModel.message).to.beNil();
  expect(viewModel.buttons).to.equal(buttons);
  expect(viewModel.defaultButtonIndex).to.equal(@1);
});

it(@"should initialize without default button", ^{
  auto viewModel = [[SPXAlertViewModel alloc] initWithTitle:@"Title" message:@"Message"
                                                    buttons:buttons defaultButtonIndex:nil];

  expect(viewModel.title).to.equal(@"Title");
  expect(viewModel.message).to.equal(@"Message");
  expect(viewModel.buttons).to.equal(buttons);
  expect(viewModel.defaultButtonIndex).to.beNil();
});

it(@"should raise exception if buttons array is empty", ^{
  expect(^{
    auto __unused viewModel = [[SPXAlertViewModel alloc] initWithTitle:@"Title" message:nil
                                                               buttons:@[] defaultButtonIndex:nil];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise exception if default button index is invalid", ^{
  expect(^{
    auto __unused viewModel = [[SPXAlertViewModel alloc] initWithTitle:@"Title" message:nil
                                                               buttons:buttons
                                                    defaultButtonIndex:@2];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd

