// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class LABAssignment;

@protocol LTEnum;

/// Value class containing an \c assignment and its \c value transformed to class \c ObjectType. The
/// two are grouped together for easy access to assignment value, and reporting the user has been
/// affected by the assignment using the classes that implement the \c LABAssignmentManager
/// protocol.
///
/// Users of this class use the same instance of this object (or equal objects) when applying an
/// assignment, and reporting that the user has been affected by the \c assignment.
@interface LABAssignmentValue<__covariant ObjectType: id<NSCoding>> : LTValueObject <NSCoding>

/// Returns \c LABAssignmentValue containing the given \c assignment and its value as \c enumClass.
/// The \c value is created by taking the \c NSString \c value of \c assignment and transforming it
/// to an \c enumClass object.
///
/// Returns \c nil if:
///   1. \c value of \c assignment is not \c NSString.
///   2. \c value of \c assignment doesn't exist in \c enumClass.
///   3. \c assignment is \c nil.
///
/// Raises \c NSInvalidArgumentException if \c enumClass does not conform to \c LTEnum.
+ (nullable LABAssignmentValue<id<LTEnum>> *)
    enumValueForAssignment:(nullable LABAssignment *)assignment enumClass:(Class)enumClass;

/// Returns \c LABAssignmentValue containing the given \c assignment and its value as \c NSString.
/// Returns \c nil if the \c value of \c assignment is not \c NSString or if \c assignment is
/// \c nil.
+ (nullable LABAssignmentValue<NSString *> *)
    stringValueForAssignment:(nullable LABAssignment *)assignment;

/// Returns \c LABAssignmentValue containing the given \c assignment and its value as \c NSNumber.
/// Returns \c nil if the \c value of \c assignment is not \c NSNumber or if \c assignment is
/// \c nil.
+ (nullable LABAssignmentValue<NSNumber *> *)
    numberValueForAssignment:(nullable LABAssignment *)assignment;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c value as the transformed value of the assignment and \c assignment
/// as the originating assignment of \c value.
- (instancetype)initWithValue:(ObjectType)value andAssignment:(LABAssignment *)assignment
    NS_DESIGNATED_INITIALIZER;

/// \c value of \c assignment transformed to \c ObjectType.
@property (readonly, nonatomic) ObjectType value;

/// Assignment, containing its origin data, used to report that the user has been affected by this
/// assignment.
@property (readonly, nonatomic) LABAssignment *assignment;

@end

NS_ASSUME_NONNULL_END
