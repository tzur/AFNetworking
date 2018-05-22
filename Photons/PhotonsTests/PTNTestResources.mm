// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "PTNTestResources.h"

#import <LTKit/NSBundle+Path.h>

NS_ASSUME_NONNULL_BEGIN

static NSURL *PTNURLForResourceFileName(NSString *filename) {
  auto _Nullable path = [NSBundle.lt_testBundle lt_pathForResource:filename];
  return [NSURL fileURLWithPath:nn(path)];
}

NSURL *PTNOneSecondVideoURL() {
  return PTNURLForResourceFileName(@"OneSecondVideo16x16.mp4");
}

NSURL *PTNSmallImageURL() {
  return PTNURLForResourceFileName(@"PTNImageAsset.jpg");
}

NSURL *PTNTextFileURL() {
  return PTNURLForResourceFileName(@"PTNImageAsset.txt");
}

NSURL *PTNImageWithMetadataURL() {
  return PTNURLForResourceFileName(@"PTNImageMetadataImage.jpg");
}

NSURL *PTNOceanSearchResponseJSONURL() {
  return PTNURLForResourceFileName(@"OceanFakeSearchResponse.json");
}

NSURL *PTNOceanSearchResponseLastPageJSONURL() {
  return PTNURLForResourceFileName(@"OceanFakeSearchResponseLastPage.json");
}

NSURL *PTNOceanPhotoAssetDescriptorJSONURL() {
  return PTNURLForResourceFileName(@"OceanFakePhotoAssetResponse.json");
}

NSURL *PTNOceanVideoAssetDescriptorJSONURL() {
  return PTNURLForResourceFileName(@"OceanFakeVideoAssetResponse.json");
}

NSURL *PTNOceanPartialVideoAssetDescriptorJSONURL() {
  return PTNURLForResourceFileName(@"OceanFakeVideoAssetPartialResponse.json");
}

NSURL *PTNOceanNoDownloadVideoAssetDescriptorJSONURL(void) {
  return PTNURLForResourceFileName(@"OceanFakeVideoAssetNoDownloadResponse.json");
}

NSURL *PTNOceanNoStreamingVideoAssetDescriptorJSONURL(void) {
  return PTNURLForResourceFileName(@"OceanFakeVideoAssetNoStreamingResponse.json");
}

NS_ASSUME_NONNULL_END
