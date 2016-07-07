// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUImageCellViewModelProvider.h"

#import <Photons/PTNImageFetchOptions.h>

#import "PTUImageCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PTUImageCellViewModelProvider ()

/// Asset manager used to fetch images and albums of given \c PTNDescriptor objects.
@property (readonly, nonatomic) id<PTNAssetManager> assetManager;

/// Image fetch options used for creating \c PTUImageCellViewModel objects.
@property (readonly, nonatomic) PTNImageFetchOptions *imageFetchOptions;

@end

@implementation PTUImageCellViewModelProvider

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions {
  if (self = [super init]) {
    _assetManager = assetManager;
    _imageFetchOptions = imageFetchOptions;
  }
  return self;
}

- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager {
  PTNImageFetchOptions *options =
      [PTNImageFetchOptions optionsWithDeliveryMode:PTNImageDeliveryModeOpportunistic
                                         resizeMode:PTNImageResizeModeFast];
  return [self initWithAssetManager:assetManager imageFetchOptions:options];
}

#pragma mark -
#pragma mark PTUImageCellViewModelProvider
#pragma mark -

- (PTUImageCellViewModel *)viewModelForDescriptor:(id<PTNDescriptor>)descriptor {
  return [[PTUImageCellViewModel alloc] initWithAssetManager:self.assetManager descriptor:descriptor
                                           imageFetchOptions:self.imageFetchOptions];
}

@end

NS_ASSUME_NONNULL_END
