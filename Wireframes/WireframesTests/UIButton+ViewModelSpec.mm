// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "UIButton+ViewModel.h"

#import "WFFakeImageViewModel.h"

SpecBegin(UIButton_ViewModel)

__block UIButton *button;

beforeEach(^{
  button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
});

it(@"should not leak view model", ^{
  __weak WFFakeImageViewModel *weakViewModel = nil;
  @autoreleasepool {
    WFFakeImageViewModel *viewModel = [[WFFakeImageViewModel alloc] init];
    weakViewModel = viewModel;
    button.wf_viewModel = viewModel;
    button.wf_viewModel = nil;
  }
  expect(weakViewModel).to.beNil();
});

context(@"image bindings", ^{
  __block WFFakeImageViewModel *viewModel;

  beforeEach(^{
    viewModel = [[WFFakeImageViewModel alloc] init];
  });

  it(@"should set initial value when binding images", ^{
    viewModel.image = WFCreateBlankImage(2, 1);
    viewModel.highlightedImage = WFCreateBlankImage(1, 2);

    button.wf_viewModel = viewModel;
    expect([button imageForState:UIControlStateNormal]).to.equal(viewModel.image);
    expect([button imageForState:UIControlStateHighlighted]).to.equal(viewModel.highlightedImage);
    expect([button imageForState:UIControlStateSelected]).to.equal(viewModel.highlightedImage);
    expect([button imageForState:UIControlStateHighlighted | UIControlStateSelected])
        .to.equal(viewModel.highlightedImage);
  });

  it(@"should bind image", ^{
    button.wf_viewModel = viewModel;

    UIImage *image = WFCreateBlankImage(10, 5);
    viewModel.image = image;
    expect([button imageForState:UIControlStateNormal]).to.equal(image);

    UIImage *anotherImage = WFCreateBlankImage(15, 14);
    viewModel.image = anotherImage;
    expect([button imageForState:UIControlStateNormal]).to.equal(anotherImage);
  });

  it(@"should bind highlighted image", ^{
    button.wf_viewModel = viewModel;

    UIImage *image = WFCreateBlankImage(10, 5);
    viewModel.highlightedImage = image;
    expect([button imageForState:UIControlStateHighlighted]).to.equal(image);
    expect([button imageForState:UIControlStateSelected]).to.equal(image);

    UIImage *anotherImage = WFCreateBlankImage(15, 14);
    viewModel.highlightedImage = anotherImage;
    expect([button imageForState:UIControlStateHighlighted]).to.equal(anotherImage);
    expect([button imageForState:UIControlStateSelected]).to.equal(anotherImage);

    viewModel.highlightedImage = nil;
    expect([button imageForState:UIControlStateHighlighted]).to.beNil();
    expect([button imageForState:UIControlStateSelected]).to.beNil();
  });

  it(@"should unbind image", ^{
    button.wf_viewModel = viewModel;
    button.wf_viewModel = nil;

    viewModel.image = WFCreateBlankImage(1, 1);
    expect([button imageForState:UIControlStateNormal]).to.beNil();
  });

  it(@"should not leak button after binding view model", ^{
    __weak UIButton *weakButton = nil;
    @autoreleasepool {
      UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
      button.wf_viewModel = viewModel;
      weakButton = button;
    }
    expect(weakButton).to.beNil();
  });

  it(@"should update view with animation", ^{
    viewModel.isAnimated = YES;
    viewModel.animationDuration = 0.7;
    button.wf_viewModel = viewModel;

    expect(button.layer.animationKeys).to.equal(@[@"transition"]);
    expect([button.layer animationForKey:@"transition"].duration).to.equal(0.7);
  });
});

SpecEnd
