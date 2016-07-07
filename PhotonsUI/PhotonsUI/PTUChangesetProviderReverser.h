// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Adapter to a \c PTUChangesetProvider instance, reversing specified sections and their
/// corresponding updates.
///
/// @note This reverser assumes valid incremental updates without inter-section moves. 
@interface PTUChangesetProviderReverser : NSObject <PTUChangesetProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c provider as underlying changeset provider and \c sectionToReverse as a set
/// of sections who's content and updates will be reversed by this adapter.
- (instancetype)initWithProvider:(id<PTUChangesetProvider>)provider
               sectionsToReverse:(NSIndexSet *)sectionsToReverse NS_DESIGNATED_INITIALIZER;

/// Initializes with \c provider as underlying changeset provider reversing the contents and updates
/// made to all sections.
- (instancetype)initWithProvider:(id<PTUChangesetProvider>)provider;

@end

NS_ASSUME_NONNULL_END
