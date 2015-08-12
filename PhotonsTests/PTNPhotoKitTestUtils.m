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

PHFetchResultChangeDetails *PTNPhotoKitCreateChangeDetailsForAssets(NSArray *assets) {
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
