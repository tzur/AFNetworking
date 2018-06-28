// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "NSError+WHSProjectStorage.h"

#import "WHSProjectUpdateRequest.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSError (WHSProjectStorage)

+ (instancetype)whs_errorCreatingProjectWithID:(NSUUID *)projectID
                               underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeWriteFailed associatedProjectID:projectID
                    underlyingError:underlyingError description:@"Failed to create project"];
}

+ (instancetype)whs_errorFetchingProjectsIDsSortedBy:(WHSProjectSortProperty *)sortProperty
                                     underlyingError:(nullable NSError *)underlyingError {
  return [NSError lt_errorWithCode:WHSErrorCodeFetchFailed underlyingError:underlyingError
                       description:@"Failed to fetch projects IDs sorted by %@", sortProperty.name];
}

+ (instancetype)whs_errorFetchingProjectWithID:(NSUUID *)projectID
                               underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeFetchFailed associatedProjectID:projectID
                    underlyingError:underlyingError description:@"Failed to fetch project"];
}

+ (instancetype)whs_errorFetchingStepWithID:(NSUUID *)stepID fromProjectWithID:(NSUUID *)projectID
                            underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeFetchFailed associatedProjectID:projectID
                   associatedStepID:stepID underlyingError:underlyingError
                        description:@"Failed to fetch step"];
}

+ (instancetype)whs_errorDeletingProjectWithID:(NSUUID *)projectID
                               underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeDeleteFailed associatedProjectID:projectID
                    underlyingError:underlyingError description:@"Failed to delete project"];
}

+ (instancetype)whs_errorUpdatingProjectWithRequest:(WHSProjectUpdateRequest *)request
                                    underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeWriteFailed associatedProjectID:request.projectID
                    underlyingError:underlyingError
                        description:@"Failed to update project with request %@", request];
}

+ (instancetype)whs_errorSettingCreationDate:(NSDate *)creationDate
                             toProjectWithID:(NSUUID *)projectID
                             underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeWriteFailed associatedProjectID:projectID
                    underlyingError:underlyingError
                        description:@"Failed to set creation date %@", creationDate];
}

+ (instancetype)whs_errorSettingModificationDate:(NSDate *)modificationDate
                                 toProjectWithID:(NSUUID *)projectID
                                 underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeWriteFailed associatedProjectID:projectID
                    underlyingError:underlyingError
                        description:@"Failed to set modification date %@", modificationDate];
}

+ (instancetype)whs_errorDuplicatingProjectWithID:(NSUUID *)projectID
                                  underlyingError:(nullable NSError *)underlyingError {
  return [NSError whs_errorWithCode:WHSErrorCodeWriteFailed associatedProjectID:projectID
                    underlyingError:underlyingError description:@"Failed to duplicate project"];
}

@end

NS_ASSUME_NONNULL_END
