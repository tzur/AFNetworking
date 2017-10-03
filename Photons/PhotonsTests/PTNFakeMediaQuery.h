// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class MPMediaItem, MPMediaItemCollection;

/// Implementation of \c PTNMediaQuery with functionality which allows precise control over the
/// return values from \c PTNMediaQuery's methods. Used for testing.
@interface PTNFakeMediaQuery : NSObject <PTNMediaQuery>

/// Initializes a default \c PTNFakeMediaQuery instance.
/// It's equivalent to:
///
/// @code
///     [[PTNFakeMediaQuery alloc] initWithItems:nil collections:nil];
/// @endcode
- (instancetype)init;

/// Initializes with the given \c items, which will be retuned when reading the \c items property.
/// It's equivalent to:
///
/// @code
///     [[PTNFakeMediaQuery alloc] initWithItems:items collections:nil];
/// @endcode
- (instancetype)initWithItems:(nullable NSArray<MPMediaItem *> *)items;

/// Initializes with the given \c collections, which will be retuned when reading the
/// \c collections property. It's equivalent to:
///
/// @code
///     [[PTNFakeMediaQuery alloc] initWithItems:nil collections:collections];
/// @endcode
- (instancetype)initWithCollections:(nullable NSArray<MPMediaItemCollection *> *)collections;

/// Initializes with the given \c items and \c collections.
- (instancetype)initWithItems:(nullable NSArray<MPMediaItem *> *)items
                  collections:(nullable NSArray<MPMediaItemCollection *> *)collections
    NS_DESIGNATED_INITIALIZER;

/// Array of media items.
@property (strong, nonatomic, nullable) NSArray<MPMediaItem *> *items;

/// Array of media item collections.
@property (strong, nonatomic, nullable) NSArray<MPMediaItemCollection *> *collections;

@end

NS_ASSUME_NONNULL_END
