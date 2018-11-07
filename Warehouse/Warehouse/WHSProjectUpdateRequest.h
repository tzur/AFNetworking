// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

/// Object containing the information needed to create a new step for a project.
@interface WHSStepContent : LTValueObject

/// Creates and returns a \c WHSStepContent object with the given \c userData. \c assetsSourceURL is
/// \c nil.
+ (instancetype)stepContentWithUserData:(NSData *)userData;

/// Creates and returns a \c WHSStepContent object with the given \c userData and
/// \c assetsSourceURL.
+ (instancetype)stepContentWithUserData:(NSData *)userData
                        assetsSourceURL:(nullable NSURL *)assetsSourceURL;

/// Data that is application specific for this step.
@property (copy, nonatomic) NSData *userData;

/// Source directory containing step-related assets to move to the step storage. The resulting step
/// will contain the target directory. As part of the update request processing, the source
/// directory is deleted. If value is \c nil the assets directory of the step created from this
/// object is created empty.
@property (strong, nonatomic, nullable) NSURL *assetsSourceURL;

@end

/// Object containing the parameters needed to update a project.
@interface WHSProjectUpdateRequest : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c projectID.
- (instancetype)initWithProjectID:(NSUUID *)projectID NS_DESIGNATED_INITIALIZER;

/// Creates and returns a request to undo the current step of the project based on the given
/// \c projectSnapshot. Returns \c nil if an undo operation is not possible on the project according
/// to the given \c projectSnapshot.
+ (nullable WHSProjectUpdateRequest *)requestForUndo:(WHSProjectSnapshot *)projectSnapshot;

/// Creates and returns a request to redo the next step of the project based on the given
/// \c projectSnapshot. Returns \c nil if an redo operation is not possible on the project according
/// to the given \c projectSnapshot
+ (nullable WHSProjectUpdateRequest *)requestForRedo:(WHSProjectSnapshot *)projectSnapshot;

/// Creates and returns a request to add a step to the project based on the given
/// \c projectSnapshot. The operation includes deleting all steps after the step cursor, adding a
/// new step at the step cursor with the given \c stepContent as its content, and increment the step
/// cursor by one.
///
/// Returns \c nil if \c stepIDs is \c nil in the given \c projectSnapshot.
+ (nullable WHSProjectUpdateRequest *)requestForAddStep:(WHSProjectSnapshot *)projectSnapshot
                                            stepContent:(WHSStepContent *)stepContent;

/// ID of the project to update.
@property (readonly, nonatomic) NSUUID *projectID;

/// Requested step cursor of the project after the update. If value is \c nil the step cursor
/// will not change.
@property (strong, nonatomic, nullable) NSNumber *stepCursor;

/// Array containing the IDs of the steps to delete, if a step ID does not exist in the project, it
/// is ignored.
@property (copy, nonatomic) NSArray<NSUUID *> *stepIDsToDelete;

/// Array with the content of the steps to add. The order of the steps addition to the project is
/// the order of the array elements. The \c userData of the \c WHSStepContent is used as the user
/// data of the added step. The content of the directory that \c assetsSourceURL of the
/// \c WHSStepContent is pointing to is moved to the new step's storage and the directory itself is
/// deleted.
@property (copy, nonatomic) NSArray<WHSStepContent *> *stepsContentToAdd;

/// User data of the project after the update. If value is \c nil the project user data is not
/// changed.
@property (copy, nonatomic, nullable) NSData *userData;

@end

NS_ASSUME_NONNULL_END
