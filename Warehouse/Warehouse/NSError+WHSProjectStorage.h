// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectStorage.h"

NS_ASSUME_NONNULL_BEGIN

/// Category for creating error objects for \c WHSProjectStorage failures.
@interface NSError (WHSProjectStorage)

/// Creates an error with the given \c underlyingError, describing failure to create the project
/// with the given \c projectID.
+ (instancetype)whs_errorCreatingProjectWithID:(NSUUID *)projectID
                               underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to fetch projects
/// IDs sorted by the given \c sortProperty.
+ (instancetype)whs_errorFetchingProjectsIDsSortedBy:(WHSProjectSortProperty *)sortProperty
                                     underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to fetch the project with
/// the given \c projectID.
+ (instancetype)whs_errorFetchingProjectWithID:(NSUUID *)projectID
                               underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to fetch the step with
/// the given \c stepID from the project with the given \c projectID.
+ (instancetype)whs_errorFetchingStepWithID:(NSUUID *)stepID fromProjectWithID:(NSUUID *)projectID
                            underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to delete the project
/// with the given \c projectID.
+ (instancetype)whs_errorDeletingProjectWithID:(NSUUID *)projectID
                               underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to update project with
/// the given \c request.
+ (instancetype)whs_errorUpdatingProjectWithRequest:(WHSProjectUpdateRequest *)request
                                    underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to set the given
/// \c creationDate to the project with the given \c projectID.
+ (instancetype)whs_errorSettingCreationDate:(NSDate *)creationDate
                             toProjectWithID:(NSUUID *)projectID
                             underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to set the given
/// \c modificationDate to the project with the given \c projectID.
+ (instancetype)whs_errorSettingModificationDate:(NSDate *)modificationDate
                                 toProjectWithID:(NSUUID *)projectID
                                 underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with the given \c underlyingError, describing failure to duplicate the project
/// with the given \c projectID.
+ (instancetype)whs_errorDuplicatingProjectWithID:(NSUUID *)projectID
                                  underlyingError:(nullable NSError *)underlyingError;
@end

NS_ASSUME_NONNULL_END
