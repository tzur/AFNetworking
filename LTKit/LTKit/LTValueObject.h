// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

NS_ASSUME_NONNULL_BEGIN

/// Returns a description of the object by iterating the class property list, and concatenating a
/// string in the format of <tt><[class name]: [pointer value], [p1 name]:
/// [p1 description](, ...)></tt> where <tt>(, ...)</tt> represents one or more additional
/// properties in the format <tt>, [p name]: [p description]</tt>, and \c description indicates the
/// property's \c description method.
///
/// @note The properties of \c object must all respond to \c -description.
NSString *LTValueObjectDescription(NSObject *object);

/// Returns \c YES if \c first points to \c second or if \c first's class is kind of \c second's
/// class and \c first's properties are equal to \c second's.
///
/// Returns \c NO if either \c first or \c second is \c nil.
///
/// @note The properties of both \c first and \c second must all respond to \c -isEqual:.
BOOL LTValueObjectIsEqual(NSObject * _Nullable first, NSObject * _Nullable second);

/// Returns the hash value of the \c object by iterating the class property list, and performing
/// \c lt::hash_combine on each property's \c hash value.
///
/// @note The properties of \c object must all respond to \c -hash.
NSUInteger LTValueObjectHash(NSObject *object);

/// An abstract base class for value objects, using reflection to provide sensible default
/// behaviors.
///
/// This class should be treated an implementation detail, i.e. <tt>LTValueObject *</tt> should
/// never be used. The class provides default implementations for \c description, \c isEqual: and
/// \c hash based on the object's ivars. Properties that are not backed by ivars are ignored as they
/// are not part of the value object itself, but rather inferred from existing properties.
///
/// Please refer to \c LTValueObjectDescription, \c LTValueObjectIsEqual and \c LTValueObjectHash
/// for the implementation details of the implemented methods.
///
/// If any of these implementation do not suffice and require more specific behavior the relevant
/// method must be overridden. This includes but does not limit to requiring \c std::hash instead of
/// \c hash, requiring a more robust description of structs such as \c CGSize or requiring only some
/// properties to be compared, hashed or described.
///
/// @note The properties of classes inheriting from this class must all respond to \c isEqual:,
/// \c hash and \c description themselves, or do so in their boxed form if they are primitive.
///
/// @important This class uses reflection to operate which may come with a performance cost. You
/// must not inherit from this class if a class requires performant implementations of these
/// methods.
///
/// @important This class does not support \c weak properties. You must not inherit from this class
/// if a class contains any \c weak properties. Attepting to use the methods provided by this class
/// in a class with \c weak properties will raise an \c NSInternalInconsistencyException.
///
/// @important This class assumes no dynamic alteration, i.e. adding or removing properties of
/// during runtime. You must not inherit from this class if a class is expected to dynamically alter
/// during runtime.
@interface LTValueObject : NSObject
@end

NS_ASSUME_NONNULL_END
