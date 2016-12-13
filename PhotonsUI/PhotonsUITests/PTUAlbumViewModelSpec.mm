// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTUAlbumViewModel.h"

SpecBegin(PTUAlbumViewModel)

it(@"should correctly initialize", ^{
  RACSignal *dataSourceProvider = [RACSignal empty];
  RACSignal *selectedAssets = [RACSignal empty];
  RACSignal *scrollToAsset = [RACSignal empty];
  NSURL *url = [NSURL URLWithString:@"http://www.foo.bar"];

  PTUAlbumViewModel *viewModel = [[PTUAlbumViewModel alloc]
                                  initWithDataSourceProvider:dataSourceProvider
                                  selectedAssets:selectedAssets scrollToAsset:scrollToAsset
                                  defaultTitle:@"foo" url:url];

  expect(viewModel.dataSourceProvider).to.equal(dataSourceProvider);
  expect(viewModel.selectedAssets).to.equal(selectedAssets);
  expect(viewModel.scrollToAsset).to.equal(scrollToAsset);
  expect(viewModel.defaultTitle).to.equal(@"foo");
  expect(viewModel.url).to.equal(url);
});

SpecEnd
