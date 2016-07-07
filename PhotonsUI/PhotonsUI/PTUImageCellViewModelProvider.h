// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAssetManager, PTNDescriptor, PTUImageCellViewModel;

@class PTNImageFetchOptions;

/// Protocol for providers of image cell view models.
@protocol PTUImageCellViewModelProvider <NSObject>

/// Creates and returns a \c PTUImageCellViewModel conforming object that represents \c descriptor.
- (id<PTUImageCellViewModel>)viewModelForDescriptor:(id<PTNDescriptor>)descriptor;

@end

/// \c PTUImageCellViewModelProvider default implementation, using the default implementation of
/// \c PTUImageCellViewModel.
@interface PTUImageCellViewModelProvider : NSObject <PTUImageCellViewModelProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c assetManager and \c PTNImageFetchOptions used when creating view models
/// using the default \c PTUImageCellViewModel implementation.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager
                   imageFetchOptions:(PTNImageFetchOptions *)imageFetchOptions
    NS_DESIGNATED_INITIALIZER;

/// Initializes with \c assetManager to use when creating view models using the default
/// \c PTUImageCellViewModel implementation, using a \c PTNImageFetchOptions object with
/// \c PTNImageDeliveryModeOpportunistic and \c PTNImageResizeModeFast.
- (instancetype)initWithAssetManager:(id<PTNAssetManager>)assetManager;

@end

NS_ASSUME_NONNULL_END
