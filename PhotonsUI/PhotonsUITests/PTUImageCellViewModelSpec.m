// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

SpecBegin(PTUImageCellViewModel)

__block PTUImageCellViewModel *viewModel;
__block RACSubject *imageSignal;
__block RACSubject *titleSignal;
__block RACSubject *subtitleSignal;

beforeEach(^{
  imageSignal = [[RACSubject alloc] init];
  titleSignal = [[RACSubject alloc] init];
  subtitleSignal = [[RACSubject alloc] init];
  viewModel = [[PTUImageCellViewModel alloc] initWithImageSignal:imageSignal titleSignal:titleSignal
                                                  subtitleSignal:subtitleSignal];
});

context(@"title", ^{
  it(@"should set value", ^{
    [titleSignal sendNext:@"foo"];
    expect(viewModel.title).to.equal(@"foo");
  });

  it(@"should update value", ^{
    [titleSignal sendNext:@"foo"];
    expect(viewModel.title).to.equal(@"foo");
    [titleSignal sendNext:@"bar"];
    expect(viewModel.title).to.equal(@"bar");
  });

  it(@"should ignore errors in signal", ^{
    [titleSignal sendNext:@"foo"];
    [titleSignal sendError:[NSError lt_errorWithCode:1337]];
    expect(viewModel.title).to.equal(@"foo");
  });

  it(@"should ignore non string values", ^{
    [titleSignal sendNext:@"foo"];
    [titleSignal sendNext:@(1337)];
    expect(viewModel.title).to.equal(@"foo");
  });

  it(@"should change values on main thread", ^{
    RACSignal *values = RACObserve(viewModel, title);
    [titleSignal sendNext:@"foo"];
    expect(values).to.deliverValuesOnMainThread();
  });
});

context(@"subtitle", ^{
  it(@"should set value", ^{
    [subtitleSignal sendNext:@"foo"];
    expect(viewModel.subtitle).to.equal(@"foo");
  });

  it(@"should update value", ^{
    [subtitleSignal sendNext:@"foo"];
    expect(viewModel.subtitle).to.equal(@"foo");
    [subtitleSignal sendNext:@"bar"];
    expect(viewModel.subtitle).to.equal(@"bar");
  });

  it(@"should ignore errors in signal", ^{
    [subtitleSignal sendNext:@"foo"];
    [subtitleSignal sendError:[NSError lt_errorWithCode:1337]];
    expect(viewModel.subtitle).to.equal(@"foo");
  });

  it(@"should ignore non string values", ^{
    [subtitleSignal sendNext:@"foo"];
    [subtitleSignal sendNext:@(1337)];
    expect(viewModel.subtitle).to.equal(@"foo");
  });

  it(@"should change values on main thread", ^{
    RACSignal *values = RACObserve(viewModel, subtitle);
    [subtitleSignal sendNext:@"foo"];
    expect(values).to.deliverValuesOnMainThread();
  });
});

context(@"image", ^{
  __block UIImage *image;

  beforeEach(^{
    image = [[UIImage alloc] init];
  });

  it(@"should set value", ^{
    [imageSignal sendNext:image];
    expect(viewModel.image).to.equal(image);
  });

  it(@"should update value", ^{
    [imageSignal sendNext:image];
    expect(viewModel.image).to.equal(image);
    UIImage *otherImage = [[UIImage alloc] init];
    [imageSignal sendNext:otherImage];
    expect(viewModel.image).to.equal(otherImage);
  });

  it(@"should ignore errors in signal", ^{
    [imageSignal sendNext:image];
    [imageSignal sendError:[NSError lt_errorWithCode:1337]];
    expect(viewModel.image).to.equal(image);
  });

  it(@"should ignore non string values", ^{
    [imageSignal sendNext:image];
    [imageSignal sendNext:@(1337)];
    expect(viewModel.image).to.equal(image);
  });

  it(@"should change values on main thread", ^{
    RACSignal *values = RACObserve(viewModel, image);
    [imageSignal sendNext:image];
    expect(values).to.deliverValuesOnMainThread();
  });
});

SpecEnd
