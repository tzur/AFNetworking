// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTUChangesetProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class PTUChangesetMetadata;

/// Aggregator of \c PTUChangsetProvider instances, combining them into a single changeset provider
/// with updates from all underlying providers.
@interface PTUCompoundChangesetProvider : NSObject <PTUChangesetProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c changesetProviders as the structural representation of the newly created
/// changeset. The data signal of each \c PTUChangesetProvider in the array is fetched and used
/// to construct a new changeset in which all the sections of all the changesets are concatinated in
/// order. This means that \c changesetMetadata should take into account all the extra sections
/// created when supplying title indexes. e.g. For the input <tt>@[@[providerA, providerB]]</tt>
/// where each provider returns a changeset with two sections, the output of the receiver will be
/// <tt>@[sectionA1, sectionA2,  sectionB1, sectionB2]</tt> and as such a section title for
/// \c providerB should be made for section \c 2 with a \c nil section title for section \c 3.
///
/// Calls to \c fetchChangesetMetadata will deliver \c changesetMetadata on an arbitrary thread and
/// complete. These signals will not err.
///
/// Calls to \c fetchChangeset will return the latest concatenated data with mapped updates if given
/// by any of the underlying changesetProviders on an arbitary thread, complete once all underlying
/// data signals of complete and err if any of the underlying data signals err.
- (instancetype)initWithChangesetProviders:(NSArray<id<PTUChangesetProvider>> *)changesetProviders
                         changesetMetadata:(PTUChangesetMetadata *)changesetMetadata
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
