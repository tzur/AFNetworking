// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModel.h"

#import <AVFoundation/AVAsset.h>
#import <LTKit/LTRandomAccessCollection.h>
#import <Photons/PTNAVAssetFetchOptions.h>
#import <Photons/PTNAlbum.h>
#import <Photons/PTNImageAsset.h>
#import <Photons/PTNImageFetchOptions.h>
#import <Photons/PTNProgress.h>
#import <Photons/PTNResizingStrategy.h>

#import "PTNFakeAssetManager.h"
#import "PTNTestUtils.h"
#import "PTUTimeFormatter.h"

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
    descriptor = PTNCreateDescriptor(url, @"foo", 0, nil);
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

  context(@"traits", ^{
    it(@"should expose session trait if underlying descriptor has session trait", ^{
      expect(viewModel.traits).to.equal([NSSet set]);

      id<PTNDescriptor> sessionAsset = PTNCreateDescriptor(nil, @"foo", 0,
          [NSSet setWithObject:kPTNDescriptorTraitSessionKey]);
      PTUImageCellViewModel *sessionViewModel = [[PTUImageCellViewModel alloc]
                                                 initWithAssetManager:assetManager
                                                 descriptor:sessionAsset
                                                 imageFetchOptions:options];
      expect(sessionViewModel.traits).to.contain(kPTUImageCellViewModelTraitSessionKey);
    });

    it(@"should expose cloud based trait if underlying descriptor has cloud based trait", ^{
      id<PTNDescriptor> cloudAsset = PTNCreateDescriptor(nil, @"foo", 0,
          [NSSet setWithObject:kPTNDescriptorTraitCloudBasedKey]);
      PTUImageCellViewModel *cloudViewModel = [[PTUImageCellViewModel alloc]
                                               initWithAssetManager:assetManager
                                               descriptor:cloudAsset
                                               imageFetchOptions:options];
      expect(cloudViewModel.traits).to.contain(kPTUImageCellViewModelTraitCloudBasedKey);
    });

    it(@"should expose video trait if underlying descriptor has video trait", ^{
      id<PTNDescriptor> videoAsset = PTNCreateDescriptor(nil, @"foo", 0,
          [NSSet setWithObject:kPTNDescriptorTraitAudiovisualKey]);
      PTUImageCellViewModel *videoViewModel = [[PTUImageCellViewModel alloc]
                                               initWithAssetManager:assetManager
                                               descriptor:videoAsset
                                               imageFetchOptions:options];
      expect(videoViewModel.traits).to.contain(kPTUImageCellViewModelTraitVideoKey);
    });

    it(@"should expose raw trait if underlying descriptor has raw trait", ^{
      id<PTNDescriptor> rawAsset = PTNCreateDescriptor(nil, @"foo", 0,
          [NSSet setWithObject:kPTNDescriptorTraitRawKey]);
      PTUImageCellViewModel *rawViewModel = [[PTUImageCellViewModel alloc]
                                             initWithAssetManager:assetManager
                                             descriptor:rawAsset
                                             imageFetchOptions:options];
      expect(rawViewModel.traits).to.contain(kPTUImageCellViewModelTraitRawKey);
    });

    it(@"should expose GIF trait if underlying descriptor has GIF trait", ^{
      id<PTNDescriptor> gifAsset = PTNCreateDescriptor(nil, @"foo", 0,
          [NSSet setWithObject:kPTNDescriptorTraitGIFKey]);
      PTUImageCellViewModel *gifViewModel = [[PTUImageCellViewModel alloc]
                                             initWithAssetManager:assetManager
                                             descriptor:gifAsset
                                             imageFetchOptions:options];
      expect(gifViewModel.traits).to.contain(kPTUImageCellViewModelTraitGIFKey);
    });

    it(@"should expose multiple traits", ^{
      id<PTNDescriptor> multiTraitsAsset =
        PTNCreateDescriptor(nil, @"foo", 0, [NSSet setWithArray:@[
          kPTNDescriptorTraitSessionKey,
          kPTNDescriptorTraitCloudBasedKey,
          kPTNDescriptorTraitAudiovisualKey,
          kPTNDescriptorTraitRawKey,
          kPTNDescriptorTraitGIFKey
        ]]);
      PTUImageCellViewModel *multiTraitsViewModel = [[PTUImageCellViewModel alloc]
                                                     initWithAssetManager:assetManager
                                                     descriptor:multiTraitsAsset
                                                     imageFetchOptions:options];
      expect(multiTraitsViewModel.traits).to.contain(kPTUImageCellViewModelTraitSessionKey);
      expect(multiTraitsViewModel.traits).to.contain(kPTUImageCellViewModelTraitCloudBasedKey);
      expect(multiTraitsViewModel.traits).to.contain(kPTUImageCellViewModelTraitVideoKey);
      expect(multiTraitsViewModel.traits).to.contain(kPTUImageCellViewModelTraitRawKey);
      expect(multiTraitsViewModel.traits).to.contain(kPTUImageCellViewModelTraitGIFKey);
    });
  });
});

context(@"PTNAlbumDescriptor", ^{
  it(@"should populate subtitle with asset count if available", ^{
    id<PTNAlbumDescriptor> albumDescriptor = PTNCreateAlbumDescriptor(url, @"bar", 0, nil, 7, 0);
    id<PTUImageCellViewModel> viewModel =
        [[PTUImageCellViewModel alloc] initWithAssetManager:assetManager descriptor:albumDescriptor
                                          imageFetchOptions:options];

    expect(viewModel.subtitleSignal).to.sendValuesWithCount(1);
  });

  it(@"should populate subtitle with using album if asset count is unavailable", ^{
    id<PTNAlbumDescriptor> albumDescriptor =
        PTNCreateAlbumDescriptor(url, @"bar", 0, nil, PTNNotFound, 0);
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
        PTNCreateAlbumDescriptor(url, @"bar", 0, nil, PTNNotFound, 0);
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

context(@"video", ^{
  __block id<PTNDescriptor> videoDescriptor;
  __block PTUTimeFormatter *timeFormatter;
  __block NSTimeInterval duration;

  beforeEach(^{
    duration = 11;
    auto traitSet = [NSSet setWithObject:kPTNDescriptorTraitAudiovisualKey];
    videoDescriptor = PTNCreateAssetDescriptor(nil, @"foo", 0, traitSet, nil, nil, nil, duration,
                                               0);
    timeFormatter = [[PTUTimeFormatter alloc] init];
  });

  it(@"should deliver video duration string on subtitle signal", ^{
    PTUImageCellViewModel *videoViewModel =
        [[PTUImageCellViewModel alloc] initWithAssetManager:assetManager descriptor:videoDescriptor
                                          imageFetchOptions:options timeFormatter:timeFormatter];

    LLSignalTestRecorder *recorder = [videoViewModel.subtitleSignal testRecorder];

    expect(recorder.values).to.equal(@[[timeFormatter timeStringForTimeInterval:duration]]);
  });
});

SpecEnd
