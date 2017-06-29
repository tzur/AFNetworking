// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaQueryProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class MPMediaItem, MPMediaItemCollection;

/// Implementation of \c PTNMediaQuery with functionality which allows precise control over the
/// return values from \c PTNMediaQuery's methods. Used for testing.
@interface PTNFakeMediaQuery : NSObject <PTNMediaQuery>

/// Initializes with the given \c items, which will be retuned when reading the \c items property.
- (instancetype)initWithItems:(nullable NSArray<MPMediaItem *> *)items;

/// Initializes with the given \c sequence. Each \c items property read will return the next element
/// in the \c sequence array (in cyclic manner), starting from \c sequence.firstObject.
- (instancetype)initWithItemsSequence:(nullable NSArray<NSArray<MPMediaItem *> *> *)sequence;

/// Initializes with the given \c sequence. Each \c collections property read will return the next
/// element in the \c sequence array (in cyclic manner), starting from \c sequence.firstObject.
- (instancetype)initWithCollectionsSequence:
    (nullable NSArray<NSArray<MPMediaItemCollection *> *> *)sequence;

@end

NS_ASSUME_NONNULL_END
