// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Immutable object that represents a snapshot of a project. A snapshot of a project is the state
/// of the project in the storage at a certain point of time. The state of a project changes with
/// time when the project is updated, and thus snapshot is up to date only until the next update.
///
/// There are two kinds of application specific data accesible from the snapshot. The first is the
/// \c userData that is an \c NSData object that the application can write when updating the
/// project, and the second is assets that can be stored manually by the application in the
/// directory the \c assetsURL is pointing to. The \c userData is part of the snapshot and
/// changes atomically with the other properties of the project during update, where the assets can
/// be changed manually at any time by the user and these changes does not change any property of
/// the snapshot, they are only affecting the content of the directory the \c assetsURL is pointing
/// to. The \c userData is appropriate for small amount of data because it cannot be partially
/// updated. The assets directory is appropriate for larger amount of data such as images, video, or
/// other binary data, and is managed by the application.
@interface WHSProjectSnapshot : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given properties.
- (instancetype)initWithID:(NSUUID *)ID bundleID:(NSString *)bundleID
              creationDate:(NSDate *)creationDate modificationDate:(NSDate *)modificationDate
                   stepIDs:(nullable NSArray<NSUUID *> *)stepIDs stepCursor:(NSUInteger)stepCursor
                  userData:(nullable NSData *)userData
                 assetsURL:(NSURL *)assetsURL NS_DESIGNATED_INITIALIZER;

/// ID of the project.
@property (readonly, nonatomic) NSUUID *ID;

/// Bundle ID of the application that created the project.
@property (readonly, nonatomic) NSString *bundleID;

/// Date the project was written to storage at the first time.
@property (readonly, nonatomic) NSDate *creationDate;

/// Date the project was last updated in the storage. Any modification to files or directories
/// in \c assetsURL of the project or in \c assetsURL of any of its steps does not affect the
/// modification date.
@property (readonly, nonatomic) NSDate *modificationDate;

/// Array containing the IDs of the steps of the project at this snapshot. The order of the IDs in
/// the array is the order of the steps in the project at this snapshot.
///
/// This property is \c nil only if it was fetched without the
/// \c WHSProjectFetchOptionsFetchStepIDs flag in \c fetchOptions.
@property (readonly, nonatomic, nullable) NSArray<NSUUID *> *stepIDs;

/// Index after the current step in the \c stepIDs array at this snapshot.
@property (readonly, nonatomic) NSUInteger stepCursor;

/// Data that is application specific for this project snapshot. Can be different between snapshots
/// of the same project.
///
/// This property is \c nil only if it was fetched without the
/// \c WHSProjectFetchOptionsFetchUserData flag in \c fetchOptions.
@property (readonly, nonatomic, nullable) NSData *userData;

/// Application-managed directory containing assets related to the project, the data in the
/// directory is not modified by this library, except when a project is deleted, at which point the
/// directory and all of its content are deleted.
@property (readonly, nonatomic) NSURL *assetsURL;

@end

/// Category for getting the availability of operations on the project.
@interface WHSProjectSnapshot (AvailableOperations)

/// \c YES if undo operation can be done on the project. The property refers to the first operation
/// after the snapshot was fetched. If any operation was done on the project after this snapshot was
/// fetched, this property is invalid.
@property (readonly, nonatomic) BOOL canUndo;

/// \c YES if redo operation can be done on the project. The property refers to the first operation
/// after the snapshot was fetched. If any operation was done on the project after this snapshot was
/// fetched, this property is invalid. If \c stepIDs is \c nil always returns \c NO.
@property (readonly, nonatomic) BOOL canRedo;

@end

/// Immutable object that represents a step of a project.
@interface WHSStep : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given properties.
- (instancetype)initWithID:(NSUUID *)ID projectID:(NSUUID *)projectID userData:(NSData *)userData
                 assetsURL:(NSURL *)assetsURL NS_DESIGNATED_INITIALIZER;

/// ID of this step.
@property (readonly, nonatomic) NSUUID *ID;

/// ID of the project containing this step.
@property (readonly, nonatomic) NSUUID *projectID;

/// Data that is application specific for this step.
@property (readonly, nonatomic) NSData *userData;

/// Directory containing assets related to the step. When the step is deleted, the directory and all
/// of its content are deleted.
@property (readonly, nonatomic) NSURL *assetsURL;

@end

NS_ASSUME_NONNULL_END
