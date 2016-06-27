// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

SpecBegin(PTUImageCellViewModel)

__block PTUImageCellViewModel *viewModel;
__block RACSignal *imageSignal;
__block RACSignal *titleSignal;
__block RACSignal *subtitleSignal;

beforeEach(^{
  imageSignal = OCMClassMock([RACSignal class]);
  titleSignal = OCMClassMock([RACSignal class]);
  subtitleSignal = OCMClassMock([RACSignal class]);
  viewModel = [[PTUImageCellViewModel alloc] initWithImageSignal:imageSignal titleSignal:titleSignal
                                                  subtitleSignal:subtitleSignal];
});

it(@"should correctly initialize with signals", ^{
  expect(viewModel.imageSignal).to.equal(imageSignal);
  expect(viewModel.titleSignal).to.equal(titleSignal);
  expect(viewModel.subtitleSignal).to.equal(subtitleSignal);
});

SpecEnd
