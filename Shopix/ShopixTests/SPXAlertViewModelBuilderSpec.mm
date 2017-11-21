// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "SPXAlertViewModelBuilder.h"

#import "SPXAlertViewModel.h"

SpecBegin(SPXAlertViewModelBuilder)

it(@"should build the view model with the required parameters", ^{
  auto viewModel = [SPXAlertViewModelBuilder builder]
      .setTitle(@"Title")
      .addButton(@"OK", ^{})
      .build();

  expect(viewModel.title).to.equal(@"Title");
  expect(viewModel.message).to.beNil();
  expect(viewModel.buttons.count).to.equal(1);
  expect(viewModel.buttons[0].title).to.equal(@"OK");
  expect(viewModel.defaultButtonIndex).to.beNil();
});

it(@"should raise exception if built without title", ^{
  expect(^{
    auto __unused viewModel = [SPXAlertViewModelBuilder builder]
        .addButton(@"OK", ^{})
        .build();
  }).to.raise(NSInternalInconsistencyException);
});

it(@"should raise exception if built without buttons", ^{
  expect(^{
    auto __unused viewModel = [SPXAlertViewModelBuilder builder]
        .setTitle(@"Title")
        .build();
  }).to.raise(NSInternalInconsistencyException);
});

it(@"should build the view model with a default button", ^{
  auto viewModel = [SPXAlertViewModelBuilder builder]
      .setTitle(@"Title")
      .addButton(@"OK", ^{})
      .addDefaultButton(@"Cancel", ^{})
      .build();

  expect(viewModel.title).to.equal(@"Title");
  expect(viewModel.message).to.beNil();
  expect(viewModel.buttons.count).to.equal(2);
  expect(viewModel.buttons[0].title).to.equal(@"OK");
  expect(viewModel.buttons[1].title).to.equal(@"Cancel");
  expect(viewModel.defaultButtonIndex).to.equal(1);
});

it(@"should raise exception if default button index is set to an invalid index", ^{
  expect(^{
    auto __unused viewModel = [SPXAlertViewModelBuilder builder]
        .setTitle(@"Title")
        .addButton(@"OK", ^{})
        .setDefaultButtonIndex(1);
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
