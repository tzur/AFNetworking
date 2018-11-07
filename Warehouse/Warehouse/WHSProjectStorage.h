// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@class WHSProjectSnapshot, WHSProjectStorage, WHSProjectUpdateRequest, WHSStep;

/// Possible project properties that projects can be sorted by.
LTEnumDeclare(NSUInteger, WHSProjectSortProperty,
  /// Sorted by the modification date of the projects.
  WHSProjectModificationDate,
  /// Sorted by the creation date of the projects.
  WHSProjectCreationDate
);

/// Possible project snapshot fetch flags. Some properties of the project snapshot are potentially
/// large, meaning their size is not bound by \c Warehouse and is usage dependent. For better
/// performance in cases these properties are large and not needed for a specific fetch, these
/// properties are not fetched by default. For each of these properties exists a fetching option
/// that should be passed to the fetching method in order to fetch it.
typedef NS_OPTIONS(NSUInteger, WHSProjectFetchOptions) {
  /// Fetch the step IDs array of the project.
  WHSProjectFetchOptionsFetchStepIDs = 1 << 0,
  /// Fetch the user data of the project.
  WHSProjectFetchOptionsFetchUserData = 1 << 1,
  /// Fetch all the properties of the project.
  WHSProjectFetchOptionsFetchAll =
      WHSProjectFetchOptionsFetchStepIDs | WHSProjectFetchOptionsFetchUserData
};

/// Protocol for handling notifications from the storage. Each observer that is added to a storage
/// is notified by the storage about each operation that changes the storage state if it implements
/// the relevant method for this operation.
@protocol WHSProjectStorageObserver <NSObject>

@optional

/// Called after a new project has been created with its \c projectID.
- (void)storage:(WHSProjectStorage *)storage createdProjectWithID:(NSUUID *)projectID;

/// Called after a project has been updated with its \c projectID.
- (void)storage:(WHSProjectStorage *)storage updatedProjectWithID:(NSUUID *)projectID;

/// Called after a project has been deleted with its \c projectID.
- (void)storage:(WHSProjectStorage *)storage deletedProjectWithID:(NSUUID *)projectID;

/// Called after a project has been duplicated with its ID as \c sourceProjectID, and the new
/// project's ID as \c destinationProjectID.
- (void)storage:(WHSProjectStorage *)storage duplicatedProjectWithID:(NSUUID *)sourceProjectID
  destinationID:(NSUUID *)destinationProjectID;

@end

/// Object for storing projects in the file system.
///
/// A Project is a mutable entity. Its state is stored in the storage and can change with time by
/// the application using the update method of this object. A \c WHSProjectSnapshot object is an
/// immutable object that contains the state of the project at the time of fetching it using the
/// fecth method of this object. See \c WHSProjectSnapshot for more information about the state of
/// a project.
///
/// The storage is not thread safe. In addition, each storage that is initialized with the same
/// \c baseURL is using the same file system location. It is the application's responsiblity to
/// synchronize the usage all the storages with the same \c baseURL. However, it is possible to use
/// several storages with a different \c baseURL concurrently as they don't share resources.
@interface WHSProjectStorage : NSObject

/// Initializes with the main bundle ID as \c bundleID, and the \c Warehouse subdirectory in the
/// Library directory inside the application's sandbox as \c baseURL.
- (instancetype)init;

/// Initializes with the \c bundleID of the application that is using this object, and with a
/// \c baseURL inside the application's sandbox for the storage to be located under. If \c baseURL
/// doesn't exist in the file system it is created by the initializer.
- (instancetype)initWithBundleID:(NSString *)bundleID baseURL:(NSURL *)baseURL
    NS_DESIGNATED_INITIALIZER;

/// Allocates storage location for a project under the \c baseURL, and returns the created project
/// ID. The created project has no steps, and its step cursor is zero. The user data is an empty
/// dictionary.
///
/// In case of failure, \c nil is returned and \c error is populated with
/// \c WHSErrorCodeWriteFailed.
- (nullable NSUUID *)createProjectWithError:(NSError **)error;

/// Returns an array of the IDs of the projects in this storage, sorted by the given
/// \c sortProperty. If \c descending is \c YES, sorts in descending order, otherwise sorts in
/// ascending order.
///
/// In case of failure, \c nil is returned and \c error is populated with
/// \c WHSErrorCodeFetchFailed.
- (nullable NSArray<NSUUID *> *)projectsIDsSortedBy:(WHSProjectSortProperty *)sortProperty
                                         descending:(BOOL)descending error:(NSError **)error;

/// Fetches the current \c WHSProjectSnapshot of the project with the given \c projectID according
/// to the given \c fetchOptions.
///
/// Properties fetched only if explicitly requested by \c fetchOptions will be \c nil in the
/// returned snapshot if not requested.
///
/// In case of failure, \c nil is returned and \c error is populated with
/// \c WHSErrorCodeFetchFailed.
- (nullable WHSProjectSnapshot *)fetchSnapshotOfProjectWithID:(NSUUID *)projectID
                                                      options:(WHSProjectFetchOptions)fetchOptions
                                                        error:(NSError **)error;

/// Returns the step with the given \c stepID, from the project with the given \c projectID.
///
/// In case of failure, \c nil is returned and \c error is populated with
/// \c WHSErrorCodeFetchFailed.
- (nullable WHSStep *)fetchStepWithID:(NSUUID *)stepID fromProjectWithID:(NSUUID *)projectID
                                error:(NSError **)error;

/// Deletes the project with the given \c projectID from this storage including all of its steps,
/// and the contents of each step's \c assetsURL. Deletes also the content that was written by the
/// application to the \c assetsURL of the project.
///
/// In case of failure, \c NO is returned, \c error is populated with \c WHSErrorCodeDeleteFailed
/// and the storage of the project does not change. Otherwise, \c YES is returned. A case where the
/// given \c projectID does not exist in the storage is considered a failure.
- (BOOL)deleteProjectWithID:(NSUUID *)projectID error:(NSError **)error;

/// Updates the storage of a project according to the instructions of the given \c request.
/// Properties that are \c nil in the given \c request are not updated.
///
/// The order of the update is as follows:
///
/// 1) New steps are created in the storage.
/// 2) The project metadata and user data is updated atomically. The project metadata is the
///    information about the project's state in the storage. It contains the list of steps of the
///    project.
/// 3) Steps are being deleted from the storage.
/// This order guarantees that the project is in a consistent state after the update even in case of
/// failure.
///
/// In case of failure, \c NO is returned, \c error is set and the storage of the project does not
/// change. Otherwise, \c YES is returned. Possible error codes:
///
/// 1) \c LTErrorCodeInvalidArgument if \c request instructions causes step cursor after the update
///    to be larger than the number of steps in the project after the update.
/// 2) \c WHSErrorCodeWriteFailed if failed for any other reason.
- (BOOL)updateProjectWithRequest:(WHSProjectUpdateRequest *)request error:(NSError **)error;

/// Duplicates the project with the given \c projectID, and returns the ID of the new project.
///
/// The ID of the project, the creation date and the modification date are not duplicated. All other
/// data, including user data and steps is duplicated. All assets, in the project itself and in its
/// steps are duplicated and the new project and steps point to the new assets.
///
/// In case of failure, \c nil is returned and \c error is populated with
/// \c WHSErrorCodeWriteFailed.
- (nullable NSUUID *)duplicateProjectWithID:(NSUUID *)projectID error:(NSError **)error;

/// Sets the creation date of the project with the given \c projectID to the given \c creationDate.
/// The creation date is set upon creation of the project, and does not have to be manually set.
///
/// In case of failure, \c NO is returned and \c error is populated with \c WHSErrorCodeWriteFailed.
/// Otherwise, \c YES is returned.
- (BOOL)setCreationDate:(NSDate *)creationDate toProjectWithID:(NSUUID *)projectID
                  error:(NSError **)error;

/// Sets the modification date of the project with the given \c projectID to the given
/// \c modificationDate. The modification date is set upon update of the project, and does not have
/// to be manually set.
///
/// In case of failure, \c NO is returned and \c error is populated with \c WHSErrorCodeWriteFailed.
/// Otherwise, \c YES is returned.
- (BOOL)setModificationDate:(NSDate *)modificationDate toProjectWithID:(NSUUID *)projectID
                      error:(NSError **)error;

/// Returns the total size in bytes of all the files in the base directory of the storage. The
/// returned \c NSNumber object is an \c unsigned \c long \c long value. In case of failure, \c nil
/// is returned and \c error is populated with \c WHSErrorCodeCalculateSizeFailed.
- (NSNumber *)storageSizeWithError:(NSError **)error;

/// Returns the size in bytes of the project with the given \c projectID. The returned \c NSNumber
/// object is an \c unsigned \c long \c long value. In case of failure, \c nil is returned and
/// \c error is populated with \c WHSErrorCodeCalculateSizeFailed.
- (NSNumber *)sizeOfProjectWithID:(NSUUID *)projectID error:(NSError **)error;

/// Adds the given \c observer to the receiver. The observer is notified after each operation
/// modifying the storage on the same thread the operation was invoked on by the application.
/// Multiple observers can be added to the same storage. The observer is held weakly by the
/// receiver.
- (void)addObserver:(id<WHSProjectStorageObserver>)observer;

/// Removes the given observer so that it will no longer recieve notifications. Silently ignores if
/// the given observer doesn't observe this storage.
- (void)removeObserver:(id<WHSProjectStorageObserver>)observer;

/// Bundle ID of the application that is using this object. The \c bundleID is stored with each
/// project created by this storage.
@property (readonly, nonatomic) NSString *bundleID;

/// A directory inside the application's sandbox where the storage is located.
@property (readonly, nonatomic) NSURL *baseURL;

@end

NS_ASSUME_NONNULL_END
