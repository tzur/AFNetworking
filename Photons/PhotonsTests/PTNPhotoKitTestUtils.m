// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitTestUtils.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

PHAssetCollection *PTNPhotoKitCreateAssetCollection(NSString * _Nullable localIdentifier) {
  PHAssetCollection *assetCollection = OCMClassMock([PHAssetCollection class]);
  OCMStub([assetCollection localIdentifier]).andReturn(localIdentifier);
  return assetCollection;
}

PHAsset *PTNPhotoKitCreateAsset(NSString * _Nullable localIdentifier) {
  PHAsset *asset = OCMClassMock([PHAsset class]);
  OCMStub([asset localIdentifier]).andReturn(localIdentifier);

  return asset;
}

id PTNPhotoKitCreateAssetWithSize(NSString *localIdentifier, CGSize size) {
  id asset = PTNPhotoKitCreateAsset(localIdentifier);
  OCMStub([asset pixelWidth]).andReturn(size.width);
  OCMStub([asset pixelHeight]).andReturn(size.height);

  return asset;
}

PHAsset *PTNPhotoKitCreateAssetForContentEditing(NSString *localIdentifier,
    PHContentEditingInput * _Nullable contentEditingInput,
    NSDictionary * _Nullable contentEditingInfo, PHContentEditingInputRequestID requestID) {
  PHAsset *asset = PTNPhotoKitCreateAsset(localIdentifier);
  id blockInvoker = [OCMArg invokeBlockWithArgs:contentEditingInput ?: [NSNull null],
                                                contentEditingInfo ?: [NSNull null], nil];
  OCMStub([asset requestContentEditingInputWithOptions:OCMOCK_ANY completionHandler:blockInvoker])
      .andReturn(requestID);
  return asset;
}

PHContentEditingInput *PTNPhotoKitCreateContentEditingInput(NSURL * _Nullable fullSizeImageURL) {
  PHContentEditingInput *contentEditingInput = OCMClassMock([PHContentEditingInput class]);
  OCMStub(contentEditingInput.fullSizeImageURL).andReturn(fullSizeImageURL);
  return contentEditingInput;
}

PHFetchResultChangeDetails *PTNPhotoKitCreateChangeDetailsForAssets(NSArray<PHAsset *> *assets) {
  id changeDetails = OCMClassMock([PHFetchResultChangeDetails class]);
  OCMStub([changeDetails fetchResultAfterChanges]).andReturn(assets);
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

NS_ASSUME_NONNULL_END
