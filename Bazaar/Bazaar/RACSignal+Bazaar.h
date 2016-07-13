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

@end

NS_ASSUME_NONNULL_END
