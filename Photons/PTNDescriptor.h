// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

NS_ENUM(NSUInteger) {
  /// Defines a value that indicates that an item requested couldn’t be found or doesn’t exist.
  PTNNotFound = NSUIntegerMax
};

/// Descriptor that acts as a reference to a heavy object. The heavy object is either costly to
/// fetch or to store in memory. Each descriptor has an identifier, which uniquely identifies the
/// heavy object across all Photons' objects, and allows re-fetching the descriptor when needed, as
/// the descriptor itself may contain transient data and is not serializable.
@protocol PTNDescriptor <NSObject>

/// Identifier of the Photons object.
@property (readonly, nonatomic) NSURL *ptn_identifier;

@end

/// Descriptor for album objects, which is used to fetch the actual album contents.
@protocol PTNAlbumDescriptor <PTNDescriptor>

/// Localized title of the album or \c nil if no such title is available.
@property (readonly, nonatomic, nullable) NSString *localizedTitle;

/// Number of assets contained in the album as \c NSUInteger, or \c PTNNotFound if no such count is
/// available.
@property (readonly, nonatomic) NSUInteger assetCount;

@end

/// Descriptor for asset objects, which is used to fetch the actual asset contents.
@protocol PTNAssetDescriptor <PTNDescriptor>

/// Localized title of the asset or \c nil if no such title is available.
@property (readonly, nonatomic, nullable) NSString *localizedTitle;

@end

NS_ASSUME_NONNULL_END
