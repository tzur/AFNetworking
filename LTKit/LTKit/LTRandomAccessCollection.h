// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Implemented by collections that can be accessed in a random access pattern. Such collections can
/// be stored completely in memory such as \c NSArray, or to be lazily evaluated, by partially
/// loading the objects in the collection and not having a complete representation in memory. In
/// addition to basic enumeration provided by \c NSFastEnumeration, these collections also provide
/// random access to objects based on their index, and the total number of items in the collection.
@protocol LTRandomAccessCollection <NSCopying, NSFastEnumeration, NSObject>

/// Returns a Boolean value that indicates whether a given \c object is present in the collection.
- (BOOL)containsObject:(id)object;

/// Returns the object located at the specified index. If index is beyond the end of the collection
/// (that is, if index is greater than or equal to the value returned by \c count), an exception is
/// raised.
- (id)objectAtIndex:(NSUInteger)idx;

/// Returns the object located at the specified index.
///
/// @note an \c NSRangeException is raised if \c idx is beyond the end of the fetch result (that is,
/// greater than or equal to the value of the \c count property).
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

/// Returns the lowest index whose corresponding array value is equal to a given object. If none of
/// the objects in the array is equal to \c anObject, returns \c NSNotFound.
- (NSUInteger)indexOfObject:(id)anObject;

/// The first object in the collection, or \c nil if the collection is empty.
@property (readonly, nonatomic, nullable) id firstObject;

/// The last object in the collection, or \c nil if the collection is empty.
@property (readonly, nonatomic, nullable) id lastObject;

/// Number of objects in the collection.
@property (readonly, nonatomic) NSUInteger count;

@end

/// Marks \c NSArray as an implementer of \c LTRandomAccessCollection.
@interface NSArray<__covariant ObjectType> (LTRandomAccessCollection) <LTRandomAccessCollection>
@end

/// Marks \c NSOrderedSet as an implementer of \c LTRandomAccessCollection.
@interface NSOrderedSet<__covariant ObjectType> (LTRandomAccessCollection)
    <LTRandomAccessCollection>
@end

NS_ASSUME_NONNULL_END
