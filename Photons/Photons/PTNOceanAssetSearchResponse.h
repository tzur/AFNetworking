// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@class PTNOceanAssetDescriptor;

/// Serializable model for an Ocean search response.
@interface PTNOceanAssetSearchResponse : MTLModel <MTLJSONSerializing>

/// Page of this response.
@property (readonly, nonatomic) NSUInteger page;

/// Number of assets in the \c page.
@property (readonly, nonatomic) NSUInteger count;

/// Total number of pages.
@property (readonly, nonatomic) NSUInteger pagesCount;

/// Number of assets in all pages.
@property (readonly, nonatomic) NSUInteger totalCount;

/// Descriptors of assets that are associated with the \c page.
@property (readonly, nonatomic) NSArray<PTNOceanAssetDescriptor *> *results;

@end

NS_ASSUME_NONNULL_END
