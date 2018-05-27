// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Category for creating \c NSError objects for \c Warehouse failures.
@interface NSError (Warehouse)

/// Creates an error with Lightricks' domain, given error code, the associated project ID and
/// description.
+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                      description:(nullable NSString *)description, ... NS_FORMAT_FUNCTION(3, 4);

/// Creates an error with Lightricks' domain, given error code, the associated project ID,
/// description and underlying error.
+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description, ... NS_FORMAT_FUNCTION(4, 5);

/// Creates an error with Lightricks' domain, given error code and the associated project ID,
/// associated step ID, and description.
+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                 associatedStepID:(nullable NSUUID *)associatedStepID
                      description:(nullable NSString *)description, ... NS_FORMAT_FUNCTION(4, 5);

/// Creates an error with Lightricks' domain, given error code and the associated project ID,
/// associated step ID, description, and underlying error.
+ (instancetype)whs_errorWithCode:(NSInteger)code
              associatedProjectID:(nullable NSUUID *)associatedProjectID
                 associatedStepID:(nullable NSUUID *)associatedStepID
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description, ... NS_FORMAT_FUNCTION(5, 6);

/// Project ID associated with the error.
@property (readonly, nonatomic, nullable) NSUUID *whs_associatedProjectID;

/// Step ID associated with the error.
@property (readonly, nonatomic, nullable) NSUUID *whs_associatedStepID;

@end

NS_ASSUME_NONNULL_END
