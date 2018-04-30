// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexingTestUtils.h"

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

id<PTNAssetManager> PTNCreateRejectingManager() {
  id manager = OCMProtocolMock(@protocol(PTNAssetManager));
  [[manager reject] fetchAlbumWithURL:OCMOCK_ANY];
  [[manager reject] fetchDescriptorWithURL:OCMOCK_ANY];
  [[manager reject] fetchImageWithDescriptor:OCMOCK_ANY resizingStrategy:OCMOCK_ANY
                                     options:OCMOCK_ANY];
  [[manager reject] fetchAVAssetWithDescriptor:OCMOCK_ANY options:OCMOCK_ANY];
  [[manager reject] fetchImageDataWithDescriptor:OCMOCK_ANY];
  [[manager reject] fetchAVPreviewWithDescriptor:OCMOCK_ANY options:OCMOCK_ANY];
  [[manager reject] fetchAVDataWithDescriptor:OCMOCK_ANY];
  [[manager reject] deleteDescriptors:OCMOCK_ANY];
  [[manager reject] removeDescriptors:OCMOCK_ANY fromAlbum:OCMOCK_ANY];
  [[[manager reject] ignoringNonObjectArgs] favoriteDescriptors:OCMOCK_ANY favorite:YES];
  return manager;
}

id<PTNAssetManager> PTNCreateAcceptingManager(RACSignal * _Nullable value) {
  id manager = OCMProtocolMock(@protocol(PTNAssetManager));
  OCMStub([manager fetchAlbumWithURL:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchDescriptorWithURL:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchImageWithDescriptor:OCMOCK_ANY resizingStrategy:OCMOCK_ANY
                                    options:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchAVAssetWithDescriptor:OCMOCK_ANY options:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchImageDataWithDescriptor:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchAVPreviewWithDescriptor:OCMOCK_ANY options:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchAVDataWithDescriptor:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager deleteDescriptors:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager removeDescriptors:OCMOCK_ANY fromAlbum:OCMOCK_ANY]).andReturn(value);
  [[[[manager stub] ignoringNonObjectArgs] andReturn:value]
      favoriteDescriptors:OCMOCK_ANY favorite:YES];

  return manager;
}

NS_ASSUME_NONNULL_END
