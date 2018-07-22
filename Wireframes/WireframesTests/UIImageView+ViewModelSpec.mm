// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "UIImageView+ViewModel.h"

#import "WFFakeImageViewModel.h"

SpecBegin(UIImageView_ViewModel)

__block UIImageView *view;

beforeEach(^{
  view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
});

it(@"should not leak view model", ^{
  __weak WFFakeImageViewModel *weakViewModel = nil;
  @autoreleasepool {
    WFFakeImageViewModel *viewModel = [[WFFakeImageViewModel alloc] init];
    weakViewModel = viewModel;
    view.wf_viewModel = viewModel;
    view.wf_viewModel = nil;
  }
  expect(weakViewModel).to.beNil();
});

context(@"image bindings", ^{
  __block WFFakeImageViewModel *viewModel;
  beforeEach(^{
    viewModel = [[WFFakeImageViewModel alloc] init];
  });

  it(@"should set initial value when binding images", ^{
    view.image = WFCreateBlankImage(3, 3);
    view.highlightedImage = WFCreateBlankImage(4, 4);
    viewModel.image = WFCreateBlankImage(2, 1);
    viewModel.highlightedImage = WFCreateBlankImage(1, 2);

    view.wf_viewModel = viewModel;
    expect(view.image).to.equal(viewModel.image);
    expect(view.highlightedImage).to.equal(viewModel.highlightedImage);
  });

  it(@"should bind image", ^{
    view.wf_viewModel = viewModel;

    UIImage *image = WFCreateBlankImage(10, 5);
    viewModel.image = image;
    expect(view.image).to.equal(image);

    UIImage *anotherImage = WFCreateBlankImage(15, 14);
    viewModel.image = anotherImage;
    expect(view.image).to.equal(anotherImage);
  });

  it(@"should bind highlighted image", ^{
    view.wf_viewModel = viewModel;

    UIImage *image = WFCreateBlankImage(10, 5);
    viewModel.highlightedImage = image;
    expect(view.highlightedImage).to.equal(image);

    UIImage *anotherImage = WFCreateBlankImage(15, 14);
    viewModel.highlightedImage = anotherImage;
    expect(view.highlightedImage).to.equal(anotherImage);

    viewModel.highlightedImage = nil;
    expect(view.highlightedImage).to.beNil();
  });

  it(@"should unbind image", ^{
    view.wf_viewModel = viewModel;
    view.wf_viewModel = nil;

    viewModel.image = WFCreateBlankImage(1, 1);
    expect(view.image).to.beNil();
  });

  it(@"should not leak view after binding view model", ^{
    __weak UIImageView *weakView = nil;
    @autoreleasepool {
      UIImageView *view = [[UIImageView alloc] initWithFrame:CGRectZero];
      view.wf_viewModel = viewModel;
      weakView = view;
    }
    expect(weakView).to.beNil();
  });

  it(@"should update view with animation", ^{
    viewModel.isAnimated = YES;
    viewModel.animationDuration = 0.7;
    view.wf_viewModel = viewModel;

    expect(view.layer.animationKeys).to.equal(@[@"transition"]);
    expect([view.layer animationForKey:@"transition"].duration).to.equal(0.7);
  });
});

context(@"UIImageView highlightedImage bug", ^{
  it(@"should show new highlighted image when image view is already in highlighted state", ^{
    WFFakeImageViewModel *viewModel = [[WFFakeImageViewModel alloc] init];
    viewModel.image = WFCreateSolidImage(1, 1, [UIColor redColor]);
    viewModel.highlightedImage = WFCreateSolidImage(1, 1, [UIColor blueColor]);

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    imageView.highlighted = YES;

    imageView.wf_viewModel = viewModel;
    [imageView layoutIfNeeded];

    UIColor *highlightedColor = WFGetPixelColor(WFTakeViewSnapshot(imageView), 0, 0);
    expect(highlightedColor).to.equal([UIColor blueColor]);

    viewModel.highlightedImage = WFCreateSolidImage(1, 1, [UIColor greenColor]);

    UIColor *updatedHighlightedColor = WFGetPixelColor(WFTakeViewSnapshot(imageView), 0, 0);
    expect(updatedHighlightedColor).to.equal([UIColor greenColor]);

    viewModel.highlightedImage = nil;

    UIColor *imageColor = WFGetPixelColor(WFTakeViewSnapshot(imageView), 0, 0);
    expect(imageColor).to.equal([UIColor redColor]);
  });
});

SpecEnd
