// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

NS_ENUM(NSUInteger) {
  /// Defines a value that indicates that an item requested couldn’t be found or doesn’t exist.
  PTNNotFound = NSUIntegerMax
};

/// Capabilities possibly supported by a Photons descriptor.
typedef NS_OPTIONS(NSUInteger, PTNDescriptorCapabilities) {
  PTNDescriptorCapabilityNone = 0,
  /// Permanently delete from the source.
  PTNDescriptorCapabilityDelete = 1 << 0,
  /// Move to another location that supports adding content to.
  PTNDescriptorCapabilityMove = 1 << 2,
};

/// Capabilities possibly supported by a Photons asset.
typedef NS_OPTIONS(NSUInteger, PTNAssetDescriptorCapabilities) {
  PTNAssetDescriptorCapabilityNone = 0,
  /// Favorite within the source, adding an internal marker to the asset backed by this descriptor.
  PTNAssetDescriptorCapabilityFavorite = 1 << 0,
};

/// Capabilities possibly supported by a Photons album.
typedef NS_OPTIONS(NSUInteger, PTNAlbumDescriptorCapabilities) {
  PTNAlbumDescriptorCapabilityNone = 0,
  /// Remove asset or album references from this album without permanently deleting them.
  PTNAlbumDescriptorCapabilityRemoveContent = 1 << 0,
  /// Add asset or album references to this album without creating an actual copy.
  PTNAlbumDescriptorCapabilityAddContent = 1 << 1,
};

/// Descriptor that represents an editing session.
extern NSString * const kPTNDescriptorTraitSessionKey;

/// Descriptor that represents an asset that is backed by remote network storage. Note that the
/// asset might be already downloaded and cached by the client.
extern NSString * const kPTNDescriptorTraitCloudBasedKey;

/// Descriptor that acts as a reference to a heavy object. The heavy object is either costly to
/// fetch or to store in memory. Each descriptor has an identifier, which uniquely identifies the
/// heavy object across all Photons' objects, and allows re-fetching the descriptor when needed, as
/// the descriptor itself may contain transient data and is not serializable.
@protocol PTNDescriptor <NSObject>

/// Identifier of the Photons object.
@property (readonly, nonatomic) NSURL *ptn_identifier;

/// Localized title of the descriptor or \c nil if no such title is available.
@property (readonly, nonatomic, nullable) NSString *localizedTitle;

/// Capabilities supported by this descriptor.
@property (readonly, nonatomic) PTNDescriptorCapabilities descriptorCapabilities;

/// Traits associated with this descriptor.
///
/// @see PTNDecriptor.h for the default descriptor trait keys.
@property (readonly, nonatomic) NSSet<NSString *> *descriptorTraits;

@end

/// Descriptor for album objects, which is used to fetch the actual album contents.
@protocol PTNAlbumDescriptor <PTNDescriptor>

/// Number of assets contained in the album as \c NSUInteger, or \c PTNNotFound if no such count is
/// available.
@property (readonly, nonatomic) NSUInteger assetCount;

/// Capabilities supported by the album backed by this descriptor.
@property (readonly, nonatomic) PTNAlbumDescriptorCapabilities albumDescriptorCapabilities;

@end

/// Descriptor for asset objects, which is used to fetch the actual asset contents.
@protocol PTNAssetDescriptor <PTNDescriptor>

/// Date at which the asset identified by this descriptor was originally created or \c nil if that
/// information is unavailable.
@property (readonly, nonatomic, nullable) NSDate *creationDate;

/// Date at which the asset identified by this descriptor was last modified or \c nil if that
/// information is unavailable.
@property (readonly, nonatomic, nullable) NSDate *modificationDate;

/// Capabilities supported by the asset backed by this descriptor.
@property (readonly, nonatomic) PTNAssetDescriptorCapabilities assetDescriptorCapabilities;

@optional

/// Current favorite status of the asset backed by this descriptor. This property must be available
/// on any \c PTNDescriptor with \c PTNAssetDescriptorCapabilityFavorite in its
/// \c PTNAssetDescriptorCapabilities.
@property (readonly, nonatomic) BOOL isFavorite;

@end

NS_ASSUME_NONNULL_END
