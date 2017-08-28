// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <Mantle/Mantle.h>

#import "PTNDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@class PTNOceanAssetSource, PTNOceanAssetType;

/// Serializable model for a Ocean asset size info.
@interface PTNOceanAssetSizeInfo : MTLModel <MTLJSONSerializing>

/// Height of the asset.
@property (readonly, nonatomic) NSUInteger height;

/// Width of the asset.
@property (readonly, nonatomic) NSUInteger width;

/// URL for downloading the content of the asset.
@property (readonly, nonatomic) NSURL *url;

@end

/// Serializable model for an Ocean asset descriptor.
@interface PTNOceanAssetDescriptor : MTLModel <MTLJSONSerializing, PTNAssetDescriptor>

/// ID of the asset.
@property (readonly, nonatomic) NSString *identifier;

/// Source of the asset.
@property (readonly, nonatomic) PTNOceanAssetSource *source;

/// Type of the asset.
@property (readonly, nonatomic) PTNOceanAssetType *type;

/// Array of \c PTNOceanAssetSizeInfo objects holding the available sizes for this descriptor.
@property (readonly, nonatomic) NSArray<PTNOceanAssetSizeInfo *> *sizes;

@end

NS_ASSUME_NONNULL_END
