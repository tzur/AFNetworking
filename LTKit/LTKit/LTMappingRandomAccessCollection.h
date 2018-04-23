// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "LTRandomAccessCollection.h"

NS_ASSUME_NONNULL_BEGIN

/// An \c LTRandomAccessCollection that maps its values with the given \c LTMapBlock. The collection
/// is evaluated lazily, so the mapped objects are created on the fly.
///
/// @note the source collection is referenced and strongly held by this collection, but the
/// collection is not considered as an owner of the source. Therefore, it is not copied and it can
/// be changed after the collection has been created. When copying this collection the source is
/// copied in order to be on par with expected collection behavior.
@interface LTMappingRandomAccessCollection : NSObject <LTRandomAccessCollection>

- (instancetype)init NS_UNAVAILABLE;

/// Block for mapping values in this collection to transformed values or mapping transformed values
/// back to the original values held by the underlying collection.
typedef id _Nullable(^LTRandomAccessCollectionMappingBlock)(id value);

/// Initializes a new mapping collection with the given underlying \c collection, which serves as
/// the objects to be mapped in the returned collection. The collection holds a reference to the
/// source, but it is not being copied. Additional changes to the \c source after the collection's
/// initialization will be reflected on the collection as well. The value of each object in the
/// collection will be determined lazily by the given \c forwardMap, which should only depend on the
/// value of the original object or fixed values. \c reverseMap is used to map objects returned by
/// the receiver back to the original objects of the underlying collection. This mapping is used
/// for performing actions on the collection itself, such as getting the index of a given object.
///
/// Although collections can't contain nullable entries, the \c LTRandomAccessCollectionMappingBlock
/// can return \c nil to support a scenario where \c indexOfObject should return \c NSNotFound
/// i.e. where the \c reverseMap should map to a "non-existing" asset.
///
/// @note It must hold that <tt>[reverseMap(forwardMap(object)) isEqual:object]</tt> for every
/// object in the input space of \c forwardMap.
- (instancetype)initWithCollection:(id<LTRandomAccessCollection>)collection
                   forwardMapBlock:(LTRandomAccessCollectionMappingBlock)forwardMap
                   reverseMapBlock:(LTRandomAccessCollectionMappingBlock)reverseMap
    NS_DESIGNATED_INITIALIZER;

/// Underlying collection held by this mapping collection.
@property (readonly, nonatomic) id<LTRandomAccessCollection> collection;

@end

NS_ASSUME_NONNULL_END
