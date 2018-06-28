// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for \c Warehouse testing.
@interface WHSProjectSnapshot (Tests)

/// Creates and returns a new dummy \c WHSProjectSnapshot object. The created dummy project contains
/// steps after the \c stepCursor, its stepCursor is non-zero, and its \c stepsIDs is not \c nil.
/// The returned snapshot does not represent a project in a real storage.
+ (instancetype)dummyProject;

/// Creates and returns a new dummy \c WHSProjectSnapshot object. The created dummy project's
/// stepCursor is non-zero, and its \c stepsIDs is \c nil. The returned snapshot does not represent
/// a project in a real storage.
+ (instancetype)dummyProjectWithNilStepsIDs;

/// Creates and returns a new dummy \c WHSProjectSnapshot object. The created dummy project doesn't
/// contain steps after the \c stepCursor, its stepCursor is non-zero, and its \c stepsIDs is not
/// \c nil. The returned snapshot does not represent a project in a real storage.
+ (instancetype)dummyProjectWithNoStepsAfterCursor;

/// Creates and returns a new dummy \c WHSProjectSnapshot object. The created dummy project contains
/// steps after the \c stepCursor, its stepCursor is zero, and its \c stepsIDs is not \c nil. The
/// returned snapshot does not represent a project in a real storage.
+ (instancetype)dummyProjectWithZeroStepCursor;

/// Array of the step IDs that are after the \c stepCursor in the \c stepsIDs of this snapshot.
/// \c nil if the \c stepsIDs of this snapshot is \c nil.
@property (readonly, nonatomic, nullable) NSArray<NSUUID *> *stepsIDsAfterCursor;

@end

NS_ASSUME_NONNULL_END
