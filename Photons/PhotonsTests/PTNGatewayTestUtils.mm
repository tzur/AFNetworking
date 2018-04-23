// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNGatewayTestUtils.h"

#import "NSURL+Gateway.h"
#import "PTNGatewayAlbumDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

PTNGatewayAlbumDescriptor *PTNGatewayCreateAlbumDescriptorWithSignal(NSString *key,
                                                                     RACSignal *albumSignal,
                                                                     RACSignal *imageSignal) {
  return PTNGatewayCreateAlbumDescriptor(key, albumSignal, ^RACSignal *(id<PTNResizingStrategy>,
                                                                        PTNImageFetchOptions *) {
    return imageSignal;
  });
}

PTNGatewayAlbumDescriptor *PTNGatewayCreateAlbumDescriptor(NSString *key, RACSignal *albumSignal,
  PTNGatewayImageSignalBlock imageSignalBlock) {
  PTNGatewayAlbumDescriptor *descriptor = OCMClassMock([PTNGatewayAlbumDescriptor class]);
  NSURL *identifier = [NSURL ptn_gatewayAlbumURLWithKey:key];
  OCMStub(descriptor.ptn_identifier).andReturn(identifier);
  OCMStub(descriptor.albumSignal).andReturn(albumSignal);
  OCMStub(descriptor.imageSignalBlock).andReturn([imageSignalBlock copy]);
  OCMStub(descriptor.localizedTitle).andReturn(@"Foo");
  return descriptor;
}

NS_ASSUME_NONNULL_END
