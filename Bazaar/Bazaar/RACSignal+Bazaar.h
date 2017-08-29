// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds signal operators that are commonly used in Bazaar.
@interface RACSignal (Bazaar)

/// Deserializes instances of the given \c modelClass from JSON dictionary values. The \c modelClass
/// must be a subclass of \c BZRModel and conform to the \c MTLJSONSerializing protocol, otherwise
/// an \c NSInvalidArgumentException is raised.
///
/// The receiver is assumed to send \c NSDictionary values representing serialized instances of
/// \c modelClass in JSON format.
///
/// The returned signal sends instances of \c modelClass deserialzied from the underlying signal
/// JSON dictionaries. It completes when the underlying signal completes. It errs when the
/// underlying signal errs. If the underlying signal sends a value that fails deserialization,
/// including \c nil, non-dictionary objects and dictionaries that are not serialized instances
/// of the \c modelClass, the returned signal errs.
///
/// @see BZRModel, MTLJSONSerializing.
- (RACSignal *)bzr_deserializeModel:(Class)modelClass;

/// Deserializes instances of the given \c modelClass from JSON array values. The \c modelClass
/// must be a subclass of \c BZRModel and conform to the \c MTLJSONSerializing protocol, otherwise
/// an \c NSInvalidArgumentException is raised.
///
/// The receiver is assumed to send \c NSArray values containing \c NSDictionary objects each
/// represents a serialized instance of \c modelClass in JSON format
///
/// The returned signal sends an \c NSArray containing instances of \c modelClass deserialzied from
/// the underlying signal JSON array. It completes when the underlying signal completes and errs if
/// the underlying signal errs or if a value sent by the underlying signal is not an \c NSArray
/// containing serialized instances of \c modelClass
///
/// @see BZRModel, MTLJSONSerializing.
- (RACSignal *)bzr_deserializeArrayOfModels:(Class)modelClass;

/// Resubscribes to the receiving signal if an error occurs for an additional number of
/// \c retryCount. The first retry starts \c initialDelay seconds after the first error. The delay
/// is doubled every retry. The signal completes if the original signal completed on any try. The
/// signal errs if the all the retries failed.
///
/// @note If \c retryCount is \c 0, the signal keeps retrying until completion.
- (RACSignal *)bzr_delayedRetry:(NSUInteger)retryCount initialDelay:(NSTimeInterval)initialDelay;

@end

NS_ASSUME_NONNULL_END
