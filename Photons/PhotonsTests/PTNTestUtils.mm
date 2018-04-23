// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNTestUtils.h"

#import <LTKit/LTRandomAccessCollection.h>

#import "PTNAlbum.h"
#import "PTNDisposableRetainingSignal.h"
#import "PTNFakeAlbumDescriptor.h"
#import "PTNFakeAssetDescriptor.h"
#import "PTNFakeDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

id<PTNAlbum> PTNCreateAlbum(NSURL * _Nullable url, id<LTRandomAccessCollection> _Nullable assets,
                            id<LTRandomAccessCollection> _Nullable subalbums) {
  return [[PTNAlbum alloc] initWithURL:url ?: [NSURL URLWithString:@"foo://bar.baz"]
                             subalbums:subalbums ?: @[] assets:assets ?: @[]];
}

id<PTNDescriptor> PTNCreateDescriptor(NSURL * _Nullable identifier,
                                      NSString * _Nullable localizedTitle,
                                      PTNDescriptorCapabilities capabilities,
                                      NSSet<NSString *> * _Nullable traits) {
  return [[PTNFakeDescriptor alloc]
          initWithIdentifier:identifier ?: [NSURL URLWithString:@"fake://descriptor"]
          localizedTitle:localizedTitle ?: @""
          descriptorCapabilities:capabilities
          descriptorTraits:traits ?: [NSSet set]];
}

id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilities,
                                                NSSet<NSString *> * _Nullable traits,
                                                NSDate * _Nullable creationDate,
                                                NSDate * _Nullable modificationDate,
                                                NSString * _Nullable filename,
                                                PTNAssetDescriptorCapabilities assetCapabilities) {
  return [[PTNFakeAssetDescriptor alloc]
          initWithIdentifier:identifier ?: [NSURL URLWithString:@"fake://descriptor.asset"]
          localizedTitle:localizedTitle
          descriptorCapabilities:capabilities
          descriptorTraits:traits ?: [NSSet set]
          creationDate:creationDate
          modificationDate:modificationDate
          filename:filename
          assetDescriptorCapabilities:assetCapabilities];
}

id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilities,
                                                NSSet<NSString *> * _Nullable traits,
                                                NSDate * _Nullable creationDate,
                                                NSDate * _Nullable modificationDate,
                                                NSString * _Nullable filename,
                                                NSTimeInterval duration,
                                                PTNAssetDescriptorCapabilities assetCapabilities) {
  return [[PTNFakeAssetDescriptor alloc]
          initWithIdentifier:identifier ?: [NSURL URLWithString:@"fake://descriptor.asset"]
          localizedTitle:localizedTitle
          descriptorCapabilities:capabilities
          descriptorTraits:traits ?: [NSSet set]
          creationDate:creationDate
          modificationDate:modificationDate
          filename:filename
          duration:duration
          assetDescriptorCapabilities:assetCapabilities];
}

id<PTNAlbumDescriptor> PTNCreateAlbumDescriptor(NSURL * _Nullable identifier,
                                                NSString * _Nullable localizedTitle,
                                                PTNDescriptorCapabilities capabilities,
                                                NSSet<NSString *> * _Nullable traits,
                                                NSUInteger assetCount,
                                                PTNAlbumDescriptorCapabilities albumCapabilities) {
  return [[PTNFakeAlbumDescriptor alloc]
          initWithIdentifier:identifier ?: [NSURL URLWithString:@"fake://descriptor.album"]
          localizedTitle:localizedTitle
          descriptorCapabilities:capabilities
          descriptorTraits:traits ?: [NSSet set]
          assetCount:assetCount
          albumDescriptorCapabilities:albumCapabilities];
}

id<PTNDescriptor> PTNCreateDescriptor(NSString *localizedTitle) {
  return PTNCreateDescriptor(nil, localizedTitle, 0, nil);
}

id<PTNAssetDescriptor> PTNCreateAssetDescriptor(NSString *localizedTitle) {
  return PTNCreateAssetDescriptor(nil, localizedTitle, 0, nil, nil, nil, nil, 0);
}

id<PTNAlbumDescriptor> PTNCreateAlbumDescriptor(NSString *localizedTitle, NSUInteger assetCount) {
  return PTNCreateAlbumDescriptor(nil, localizedTitle, 0, nil, assetCount, 0);
}

PTNDisposableRetainingSignal *PTNCreateDisposableRetainingSignal() {
  return [[PTNDisposableRetainingSignal alloc] init];
}

NS_ASSUME_NONNULL_END
