// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Implemented by collections that are lazily evaluated (i.e. can partially load the objects in the
/// collection and not have a complete representation in memory). In addition to basic enumeration
/// provided by \c NSFastEnumeration, these collections also provide arbitrary access to objects
/// based on their index, and the total number of items in the collection.
@protocol PTNCollection <NSFastEnumeration, NSObject>

/// Returns the object located at the specified index.
- (id)objectAtIndex:(NSUInteger)idx;

/// Returns the object located at the specified index.
///
/// @note an \c NSRangeException is raised if \c idx is beyond the end of the fetch result (that is,
/// greater than or equal to the value of the \c count property).
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

/// The first object in the collection, or \c nil if the collection is empty.
@property (readonly, nonatomic, nullable) id firstObject;

/// The last object in the collection, or \c nil if the collection is empty.
@property (readonly, nonatomic, nullable) id lastObject;

/// Number of objects in the collection.
@property (readonly, nonatomic) NSUInteger count;

@end

@interface NSArray () <PTNCollection>
@end

NS_ASSUME_NONNULL_END
