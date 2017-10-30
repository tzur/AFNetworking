// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "NSErrorCodes+Laboratory.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSError (Laboratory)

/// Creates an error with Lightricks' domain, given error code and the associated experiment.
+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(nullable NSString *)associatedExperiment;

/// Creates an error with Lightricks' domain, given error code, the associated experiment and
/// underlying error.
+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(nullable NSString *)associatedExperiment
                  underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code and the associated variant.
+ (instancetype)lab_errorWithCode:(NSInteger)code
                associatedVariant:(nullable NSString *)associatedVariant;

/// Creates an error with Lightricks' domain, given error code, the associated variant and
/// underlying error.
+ (instancetype)lab_errorWithCode:(NSInteger)code
                associatedVariant:(nullable NSString *)associatedVariant
                  underlyingError:(nullable NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code and the associated assignment key.
+ (instancetype)lab_errorWithCode:(NSInteger)code
          associatedAssignmentKey:(nullable  NSString *)associatedAssignmentKey;

/// Creates an error with Lightricks' domain, given error code, the associated experiment and the
/// associated variant.
+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(nullable NSString *)associatedExperiment
                associatedVariant:(nullable NSString *)associatedVariant;

/// Creates an error with Lightricks' domain, given error code, the associated experiment, the
/// associated variant and underlying error.
+ (instancetype)lab_errorWithCode:(NSInteger)code
             associatedExperiment:(nullable NSString *)associatedExperiment
                associatedVariant:(nullable NSString *)associatedVariant
                  underlyingError:(nullable NSError *)underlyingError;

/// Expriment associated with the error.
@property (readonly, nonatomic, nullable) NSString *lab_associatedExperiment;

/// Variant associated with the error.
@property (readonly, nonatomic, nullable) NSString *lab_associatedVariant;

/// Assignment key associated with the error.
@property (readonly, nonatomic, nullable) NSString *lab_associatedAssignmentKey;

@end

NS_ASSUME_NONNULL_END
