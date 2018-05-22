// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <Mantle/Mantle.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNOceanAssetSource, PTNOceanAssetType;

/// Serializable model for an Ocean image asset info.
@interface PTNOceanImageAssetInfo : MTLModel <MTLJSONSerializing>

/// Height of the asset.
@property (readonly, nonatomic) NSUInteger height;

/// Width of the asset.
@property (readonly, nonatomic) NSUInteger width;

/// URL for downloading the content of the asset.
@property (readonly, nonatomic) NSURL *url;

@end

/// Serializable model for an Ocean video asset info.
@interface PTNOceanVideoAssetInfo : MTLModel <MTLJSONSerializing>

/// Height of the asset.
@property (readonly, nonatomic) NSUInteger height;

/// Width of the asset.
@property (readonly, nonatomic) NSUInteger width;

/// Size of the asset in bytes.
@property (readonly, nonatomic) NSUInteger size;

/// URL for downloading the content of the asset, if available.
@property (readonly, nonatomic, nullable) NSURL *url;

/// URL for streaming the content of the asset, if available.
@property (readonly, nonatomic, nullable) NSURL *streamURL;

@end

/// Serializable model for an Ocean asset descriptor.
@interface PTNOceanAssetDescriptor : MTLModel <MTLJSONSerializing, PTNAssetDescriptor>

/// ID of the asset.
@property (readonly, nonatomic) NSString *identifier;

/// Source of the asset.
@property (readonly, nonatomic) PTNOceanAssetSource *source;

/// Type of the asset.
@property (readonly, nonatomic) PTNOceanAssetType *type;

/// All the images available for this descriptor.
@property (readonly, nonatomic) NSArray<PTNOceanImageAssetInfo *> *images;

/// All the video assets available for this descriptor.
@property (readonly, nonatomic) NSArray<PTNOceanVideoAssetInfo *> *videos;

@end

NS_ASSUME_NONNULL_END
