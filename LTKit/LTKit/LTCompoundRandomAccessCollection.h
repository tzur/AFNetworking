// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTRandomAccessCollection.h"

NS_ASSUME_NONNULL_BEGIN

/// An \c LTRandomAccessCollection that concatenates a given array of \c LTRandomAccessCollection
/// conforming objects, creating a single collection that contains all the objects of the given
/// collections. The collection is evaluated lazily, so the access to objects in the underlying
/// collections is done on the fly as they are required.
///
/// @note the source collections are referenced and strongly held by this collection, but the
/// collection is not considered as an owner of the source. Therefore, they are not copied and can
/// be changed after the collection has been created. When copying this collection the source is
/// copied in order to be on par with expected collection behavior.
@interface LTCompoundRandomAccessCollection : NSObject <LTRandomAccessCollection>

/// Initializes a new compound collection with the given underlying \c collections array, by
/// concatenating the objects of each collection into a single collection. The returned collection
/// holds a reference to these collections, but they are not being copied. Changes to underlying
/// \c collections after initialization will be reflected on the receiver as well.
- (instancetype)initWithCollections:(NSArray<id<LTRandomAccessCollection>> *)collections
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
