// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

#import <LTKit/LTRandomAccessCollection.h>
#import <Photons/PTNAlbum.h>
#import <Photons/PTNImageAsset.h>
#import <Photons/PTNImageFetchOptions.h>
#import <Photons/PTNProgress.h>
#import <Photons/PTNResizingStrategy.h>

#import "PTNFakeAssetManager.h"
#import "PTNTestUtils.h"
#import "PTUImageCellViewModel.h"

SpecBegin(PTUImageCellViewModel)

__block PTNFakeAssetManager *assetManager;
__block PTNImageFetchOptions *options;
__block NSURL *url;
__block CGSize cellSize;

beforeEach(^{
  assetManager = [[PTNFakeAssetManager alloc] init];
  url = [NSURL URLWithString:@"http://www.foo.com"];
  options = [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeHighQuality
                                               resizeMode:PTNImageResizeModeExact];
  cellSize = CGSizeMake(10, 10);
});

context(@"PTNDescriptor", ^{
  __block id<PTNDescriptor> descriptor;
  __block id<PTUImageCellViewModel> viewModel;

  beforeEach(^{
    descriptor = PTNCreateDescriptor(url, @"foo", 0);
    viewModel = [[PTUImageCellViewModel alloc] initWithAssetManager:assetManager
                                                         descriptor:descriptor
                                                  imageFetchOptions:options];
  });

  it(@"should return the descriptor's localized title as a title signal", ^{
    expect(viewModel.titleSignal).to.sendValues(@[@"foo"]);
  });

  it(@"should fetch the descriptor's image as an image signal", ^{
    LLSignalTestRecorder *values = [[viewModel imageSignalForCellSize:cellSize] testRecorder];

    PTNImageRequest *request = [[PTNImageRequest alloc] initWithDescriptor:descriptor
        resizingStrategy:[PTNResizingStrategy aspectFill:cellSize] options:options];
    UIImage *image = [[UIImage alloc] init];
    id<PTNImageAsset> asset = OCMProtocolMock(@protocol(PTNImageAsset));
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);
    [assetManager serveImageRequest:request withProgress:@[@0.25, @0.5, @0.75] imageAsset:asset];

    expect(values).to.sendValues(@[image]);
  });

  it(@"should deliver updates to descriptor's image", ^{
    LLSignalTestRecorder *values = [[viewModel imageSignalForCellSize:cellSize] testRecorder];

    PTNImageRequest *request = [[PTNImageRequest alloc] initWithDescriptor:descriptor
        resizingStrategy:[PTNResizingStrategy aspectFill:cellSize] options:options];

    UIImage *image = [[UIImage alloc] init];
    id<PTNImageAsset> asset = OCMProtocolMock(@protocol(PTNImageAsset));
    OCMStub([asset fetchImage]).andReturn([RACSignal return:image]);

    UIImage *otherImage = [[UIImage alloc] init];
    id<PTNImageAsset> otherAsset = OCMProtocolMock(@protocol(PTNImageAsset));
    OCMStub([otherAsset fetchImage]).andReturn([RACSignal return:otherImage]);

    [assetManager serveImageRequest:request withProgressObjects:@[
      [[PTNProgress alloc] initWithResult:asset],
      [[PTNProgress alloc] initWithResult:otherAsset]
    ]];

    expect(values).will.sendValues(@[image, otherImage]);
  });
});

context(@"PTNAlbumDescriptor", ^{
  it(@"should populate subtitle with asset count if available", ^{
    id<PTNAlbumDescriptor> albumDescriptor = PTNCreateAlbumDescriptor(url, @"bar", 0, 7, 0);
    id<PTUImageCellViewModel> viewModel =
        [[PTUImageCellViewModel alloc] initWithAssetManager:assetManager descriptor:albumDescriptor
                                          imageFetchOptions:options];

    expect(viewModel.subtitleSignal).to.sendValuesWithCount(1);
  });

  it(@"should populate subtitle with using album if asset count is unavailable", ^{
    id<PTNAlbumDescriptor> albumDescriptor =
        PTNCreateAlbumDescriptor(url, @"bar", 0, PTNNotFound, 0);
    id<PTUImageCellViewModel> viewModel =
        [[PTUImageCellViewModel alloc] initWithAssetManager:assetManager descriptor:albumDescriptor
                                          imageFetchOptions:options];

    LLSignalTestRecorder *values = [viewModel.subtitleSignal testRecorder];

    id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:@[@1, @2, @3]];
    [assetManager serveAlbumURL:url withAlbum:album];

    expect(values).to.sendValuesWithCount(1);
  });

  it(@"should deliver updates descriptor's album", ^{
    id<PTNAlbumDescriptor> albumDescriptor =
        PTNCreateAlbumDescriptor(url, @"bar", 0, PTNNotFound, 0);
    id<PTUImageCellViewModel> viewModel =
        [[PTUImageCellViewModel alloc] initWithAssetManager:assetManager descriptor:albumDescriptor
                                          imageFetchOptions:options];
    LLSignalTestRecorder *values = [viewModel.subtitleSignal testRecorder];

    id<PTNAlbum> album = [[PTNAlbum alloc] initWithURL:url subalbums:@[] assets:@[@1, @2, @3]];
    [assetManager serveAlbumURL:url withAlbum:album];
    [assetManager serveAlbumURL:url withAlbum:album];

    expect(values).to.sendValuesWithCount(2);
  });
});

SpecEnd
