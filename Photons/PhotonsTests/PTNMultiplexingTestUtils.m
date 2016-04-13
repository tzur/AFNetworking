// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNMultiplexingTestUtils.h"

#import "PTNAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

id<PTNAssetManager> PTNCreateRejectingManager() {
  id manager = OCMProtocolMock(@protocol(PTNAssetManager));
  [[manager reject] fetchAlbumWithURL:OCMOCK_ANY];
  [[manager reject] fetchAssetWithURL:OCMOCK_ANY];
  [[manager reject] fetchImageWithDescriptor:OCMOCK_ANY resizingStrategy:OCMOCK_ANY
                                     options:OCMOCK_ANY];
  [[manager reject] deleteDescriptors:OCMOCK_ANY];
  [[manager reject] removeDescriptors:OCMOCK_ANY fromAlbum:OCMOCK_ANY];
  return manager;
}

id<PTNAssetManager> PTNCreateAcceptingManager(RACSignal * _Nullable value) {
  id manager = OCMProtocolMock(@protocol(PTNAssetManager));
  OCMStub([manager fetchAlbumWithURL:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchAssetWithURL:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager fetchImageWithDescriptor:OCMOCK_ANY resizingStrategy:OCMOCK_ANY
                                    options:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager deleteDescriptors:OCMOCK_ANY]).andReturn(value);
  OCMStub([manager removeDescriptors:OCMOCK_ANY fromAlbum:OCMOCK_ANY]).andReturn(value);
  return manager;
}

NS_ASSUME_NONNULL_END
