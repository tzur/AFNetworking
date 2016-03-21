// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayTestUtils.h"

#import "NSURL+Gateway.h"
#import "PTNGatewayAlbumDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

PTNGatewayAlbumDescriptor *PTNGatewayCreateAlbumDescriptor(NSString *key,
                                                           RACSignal * _Nullable albumSignal,
                                                           RACSignal * _Nullable imageSignal) {
  PTNGatewayAlbumDescriptor *descriptor = OCMClassMock([PTNGatewayAlbumDescriptor class]);
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:key];
  OCMStub(descriptor.ptn_identifier).andReturn(identifier);
  OCMStub(descriptor.albumSignal).andReturn(albumSignal);
  OCMStub(descriptor.imageSignal).andReturn(imageSignal);
  return descriptor;
}

NS_ASSUME_NONNULL_END
