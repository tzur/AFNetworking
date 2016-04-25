// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNTestUtils.h"

#import "PTNAlbum.h"
#import "PTNFakeDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<LTRandomAccessCollection> _Nullable assets,
                            id<LTRandomAccessCollection> _Nullable subalbums) {
  return [[PTNAlbum alloc] initWithURL:url subalbums:subalbums assets:assets];
}

id<PTNDescriptor> PTNCreateDescriptor(NSURL * _Nullable identifier,
                                      NSString * _Nullable localizedTitle,
                                      PTNDescriptorCapabilities capabilites) {
  return [[PTNFakeDescriptor alloc] initWithIdentifier:identifier localizedTitle:localizedTitle
                                descriptorCapabilities:capabilites];
}

NS_ASSUME_NONNULL_END
