// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedValueObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Mutable object representing a univariately parameterized object constituting a stack of
/// parameterized objects. The stack consists of at least one parameterized object at any given
/// moment. Two consecutive parameterized objects \c P and \c Q must ensure that the
/// \c maxParametricValue of \c P equals the \c minParametricValue of \c Q. The intrinsic parametric
/// range of this object equals [\c a, \c b], where \c a is the \c minParametricValue of the first
/// object in \c parameterizedObjects and \c b is the \c maxParametricValue of the last object in
/// \c parameterizedObjects. Queries are delegated to the corresponding parameterized object.
/// Queries at parametric values equaling the \c maxParametricValue and \c minParametricValue,
/// respectively, of two adjacent parameterized objects are delegated to parameterized object with
/// greater \c minParametricValue.
///
/// @important this class is not thread safe.
@interface LTParameterizedObjectStack : NSObject <LTParameterizedObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c parameterizedObject. The \c parameterizedObject is added to the
/// \c parameterizedObjects. The \c minParametricValue and \c maxParametricValue of the initialized
/// object is set to the ones of the given \c parameterizedObject.
- (instancetype)initWithParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject
    NS_DESIGNATED_INITIALIZER;

/// Pushes the given \c parameterizedObject at the end of the \c parameterizedObjects currently held
/// by this instance. The \c parameterizationKeys of the \c parameterizedObject must equal those of
/// the \c parameterizedObjects. The \c minParametricValue of the given \c parameterizedObject must
/// equal the \c maxParametricValue of the last object in \c parameterizedObjects. The
/// \c minParametricValue and the \c maxParametricValue of this instance are updated accordingly.
///
/// Time complexity: \c O(n), where \c n is the number of elements in \c parameterizedObjects.
- (void)pushParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject;

/// Replaces the given \c objectToReplace with the given \c newObject. The \c objectToReplace must
/// be in the \c parameterizedObjects of this instance and its \c minParametricValue and
/// \c maxParametricValue must equal those of the \c newObject.
///
/// Time complexity: time complexity of \c NSMutableArray to perform \c indexOfObject: and
/// \c replaceObjectAtIndex:withObject:.
- (void)replaceParameterizedObject:(id<LTParameterizedValueObject>)objectToReplace
                          byObject:(id<LTParameterizedValueObject>)newObject;

/// Pops the most recently added parameterized objects from \c parameterizedObjects. The removed
/// object is returned. The \c minParametricValue and the \c maxParametricValue of this instance are
/// updated accordingly. Does nothing and returns \c nil if \c parameterizedObjects consists of a
/// single object.
///
/// Time complexity: \c O(n), where \c n is the number of elements in \c parameterizedObjects.
- (nullable id<LTParameterizedValueObject>)popParameterizedObject;

/// Returns the number of parameterized objects held by this object.
///
/// Time complexity: \c O(1)
@property (readonly, nonatomic) NSUInteger count;

/// Ordered collection of parameterized objects constituting this object.
///
/// Time complexity: \c O(n), where \c n is the number of elements in \c parameterizedObjects, for
/// the first call after an update (pushing, replacing, popping), and \c O(1) for additional calls.
@property (readonly, nonatomic) NSArray<id<LTParameterizedValueObject>> *parameterizedObjects;

@end

NS_ASSUME_NONNULL_END
