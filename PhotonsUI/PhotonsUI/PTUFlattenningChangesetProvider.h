// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Adapter to a \c PTUChangesetProvider instance, flattening its sections into a single section of
/// the concatenated items of each section from the underlying provider. Updates are mapped to
/// reflect the new positions of each item.
@interface PTUFlattenningChangesetProvider : NSObject <PTUChangesetProvider>

/// Initializes with \c changesetProvider as underlying changeset provider who's content and updates
/// will be flattened by the receiver.
- (instancetype)initWithChangesetProvider:(id<PTUChangesetProvider>)changesetProvider
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
