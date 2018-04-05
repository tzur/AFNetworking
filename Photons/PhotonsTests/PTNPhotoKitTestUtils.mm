// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitTestUtils.h"

#import <LTKit/NSArray+NSSet.h>
#import <Photos/Photos.h>

#import "NSURL+PhotoKit.h"
#import "PTNDescriptor.h"
#import "PhotoKit+Photons.h"

NS_ASSUME_NONNULL_BEGIN

PHAssetCollection *PTNPhotoKitCreateAssetCollection(NSString * _Nullable localIdentifier) {
  PHAssetCollection *assetCollection = OCMClassMock([PHAssetCollection class]);
  OCMStub([assetCollection localIdentifier]).andReturn(localIdentifier);
  OCMStub([assetCollection albumDescriptorCapabilities])
      .andReturn(PTNAlbumDescriptorCapabilityRemoveContent);
  return assetCollection;
}

PHAssetCollection *PTNPhotoKitCreateAssetCollection(NSString * _Nullable localIdentifier,
                                                    PHAssetCollectionSubtype subtype) {
  PHAssetCollection *assetCollection = PTNPhotoKitCreateAssetCollection(localIdentifier);
  OCMStub(assetCollection.assetCollectionSubtype).andReturn(subtype);
  return assetCollection;
}

PHAsset *PTNPhotoKitCreateAsset(NSString * _Nullable localIdentifier = nil) {
  PHAsset *asset = OCMClassMock([PHAsset class]);
  OCMStub(asset.localIdentifier).andReturn(localIdentifier ?: @"LTIdentifier");
  OCMStub(asset.ptn_identifier).andReturn([NSURL ptn_photoKitAssetURLWithAsset:asset]);
  return asset;
}

PHAsset *PTNPhotoKitCreateAsset(NSString * _Nullable localIdentifier, NSArray<NSString *> *traits) {
  PHAsset *asset = PTNPhotoKitCreateAsset(localIdentifier);
  OCMStub([asset descriptorTraits]).andReturn([traits lt_set]);
  return asset;
}

PHAsset *PTNPhotoKitCreateAsset(NSString * _Nullable localIdentifier, CGSize size) {
  PHAsset *asset = PTNPhotoKitCreateAsset(localIdentifier);
  OCMStub([asset pixelWidth]).andReturn(size.width);
  OCMStub([asset pixelHeight]).andReturn(size.height);

  return asset;
}

PHCollectionList *PTNPhotoKitCreateCollectionList(NSString * _Nullable localIdentifier) {
  PHCollectionList *collectionList = OCMClassMock([PHCollectionList class]);
  OCMStub([collectionList localIdentifier]).andReturn(localIdentifier);
  OCMStub([collectionList albumDescriptorCapabilities])
      .andReturn(PTNAlbumDescriptorCapabilityRemoveContent);
  return collectionList;
}

PHAsset *PTNPhotoKitCreateAssetForContentEditing(NSString *localIdentifier,
    PHContentEditingInput * _Nullable contentEditingInput,
    NSDictionary * _Nullable contentEditingInfo, PHContentEditingInputRequestID requestID) {
  PHAsset *asset = PTNPhotoKitCreateAsset(localIdentifier);
  id blockInvoker = [OCMArg invokeBlockWithArgs:contentEditingInput ?: [NSNull null],
                                                contentEditingInfo ?: @{}, nil];
  OCMStub([asset requestContentEditingInputWithOptions:OCMOCK_ANY completionHandler:blockInvoker])
      .andReturn(requestID);
  return asset;
}

PHContentEditingInput *PTNPhotoKitCreateImageContentEditingInput(NSURL * _Nullable
                                                                 fullSizeImageURL) {
  PHContentEditingInput *contentEditingInput = OCMClassMock([PHContentEditingInput class]);
  OCMStub(contentEditingInput.fullSizeImageURL).andReturn(fullSizeImageURL);
  OCMStub(contentEditingInput.mediaType).andReturn(PHAssetMediaTypeImage);
  return contentEditingInput;
}

PHContentEditingInput *PTNPhotoKitCreateVideoContentEditingInput(AVAsset * _Nullable avAsset) {
  PHContentEditingInput *contentEditingInput = OCMClassMock([PHContentEditingInput class]);
  OCMStub(contentEditingInput.audiovisualAsset).andReturn(avAsset);
  OCMStub(contentEditingInput.mediaType).andReturn(PHAssetMediaTypeVideo);
  return contentEditingInput;
}

PHFetchResultChangeDetails *PTNPhotoKitCreateChangeDetailsForAssets(NSArray<PHAsset *> *assets) {
  id changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);
  OCMStub([changeDetails fetchResultAfterChanges]).andReturn(assets);
  OCMStub([changeDetails fetchResultBeforeChanges]).andReturn(@[]);
  return changeDetails;
}

PHObjectChangeDetails *PTNPhotoKitCreateChangeDetailsForAsset(PHAsset *asset) {
  id changeDetails = OCMClassMock([PHObjectChangeDetails class]);
  OCMStub([changeDetails objectAfterChanges]).andReturn(asset);
  return changeDetails;
}

PHChange *PTNPhotoKitCreateChangeForFetchDetails(PHFetchResultChangeDetails *changeDetails) {
  id change = OCMClassMock([PHChange class]);
  OCMStub([change changeDetailsForFetchResult:OCMOCK_ANY]).andReturn(changeDetails);
  return change;
}

PHChange *PTNPhotoKitCreateChangeForObjectDetails(PHObjectChangeDetails *changeDetails) {
  id change = OCMClassMock([PHChange class]);
  OCMStub([change changeDetailsForObject:OCMOCK_ANY]).andReturn(changeDetails);
  return change;
}

PHAssetResource *PTNPhotoKitCreateAssetResource(NSString *assetLocalIdentifier,
    PHAssetResourceType type, NSString *uniformTypeIdentifier,
    NSString * _Nullable originalFilename) {
  PHAssetResource *resource = OCMClassMock([PHAssetResource class]);
  OCMStub([resource assetLocalIdentifier]).andReturn(assetLocalIdentifier);
  OCMStub([resource type]).andReturn(type);
  OCMStub([resource uniformTypeIdentifier]).andReturn(uniformTypeIdentifier);
  OCMStub([resource originalFilename]).andReturn(originalFilename);
  return resource;
}

NS_ASSUME_NONNULL_END
