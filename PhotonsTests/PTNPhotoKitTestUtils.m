// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNPhotoKitTestUtils.h"

#import <Photos/Photos.h>

id PTNPhotoKitCreateAssetCollection(NSString *localIdentifier) {
  id assetCollection = OCMClassMock([PHAssetCollection class]);
  OCMStub([assetCollection localIdentifier]).andReturn(localIdentifier);
  return assetCollection;
}

id PTNPhotoKitCreateAsset(NSString *localIdentifier) {
  id asset = OCMClassMock([PHAsset class]);
  OCMStub([asset localIdentifier]).andReturn(localIdentifier);

  return asset;
}

id PTNPhotoKitCreateAssetWithSize(NSString *localIdentifier, CGSize size) {
  id asset = PTNPhotoKitCreateAsset(localIdentifier);
  OCMStub([asset pixelWidth]).andReturn(size.width);
  OCMStub([asset pixelHeight]).andReturn(size.height);

  return asset;
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
