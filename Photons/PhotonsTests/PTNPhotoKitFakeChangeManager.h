// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitChangeManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PTNAlbumDescriptor, PTNDescriptor;

@class PHAssetChangeRequest;

/// Fake \c PTNPhotoKitChangeManager used for testing, calling the given update block, registering
/// all change requests and calling the given completion block with the set values.
///
/// @important Requesting changes not within a change request block will result in an assertion.
/// see \c PTNPhotoKitChangeManager for more information regarding a change request block.
///
/// @important This \c PTNPhotoKitChangeManager supports request made from a single thread and using
/// it concurrently will result in unexpected behavior.
@interface PTNPhotoKitFakeChangeManager : NSObject <PTNPhotoKitChangeManager>

/// Asset requested to be created by the manager. This includes assets of all supported media types.
@property (readonly, nonatomic) NSArray *assetCreationRequests;

/// Asset requested to be deleted by the manager.
@property (readonly, nonatomic) NSArray *assetDeleteRequests;

/// Asset collections requested to be deleted by the manager.
@property (readonly, nonatomic) NSArray *assetCollectionDeleteRequests;

/// Collection lists requested to be deleted by the manager.
@property (readonly, nonatomic) NSArray *collectionListDeleteRequests;

/// Mapping of assets removed from an album in the form <localIdentifier, removed assets>.
@property (readonly, nonatomic) NSDictionary<NSString *, NSArray<id<PTNDescriptor>> *>
    *assetsRemovedFromAlbumRequests;

/// Mapping of asset collections removed from an album in the form
/// <localIdentifier, removed asset collections>.
@property (readonly, nonatomic) NSDictionary<NSString *, NSArray<id<PTNDescriptor>> *>
    *assetCollectionsRemovedFromAlbumRequests;

/// Mapping of assets added to an album in the form <localIdentifier, added assets>.
@property (readonly, nonatomic) NSDictionary<NSString *, NSArray<id<PTNDescriptor>> *>
    *assetsAddedToAlbumRequests;

/// Current assets favorited by the manager.
@property (readonly, nonatomic) NSArray *favoriteAssets;

/// Titles of the asset collections requested to be created by the manager.
@property (readonly, nonatomic) NSArray *assetCollectionCreationRequests;

/// Success value retuned at the change request completion block.
@property (nonatomic) BOOL success;

/// Error returned at the change request completion block.
@property (strong, nonatomic, nullable) NSError *error;

/// \c PHCacheRequest returned by change methods that return a change request. Default value is
/// \c nil.
@property (strong, nonatomic, nullable) PHAssetChangeRequest *changeRequest;

@end

NS_ASSUME_NONNULL_END
