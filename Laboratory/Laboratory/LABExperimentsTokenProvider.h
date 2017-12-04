// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@class LTRandom;

@protocol LTKeyValuePersistentStorage;

/// Token that determines whether an experiment is active or not. Some experiments are active
/// only when \c LABExperimentsToken falls within their "token range".
///
/// This token is passed to objects that implement the \c LABAssignmentsSource protocol. These
/// objects decide whether to expose or not expose experiments based the experiment's "token range"
/// and the given \c LABExperimentsToken.
///
/// The range of the token is [0, 1].
///
/// @see LABAssignmentsSource
typedef double LABExperimentsToken;

/// Provider of \c LABExperimentsToken objects.
@protocol LABExperimentsTokenProvider <NSObject>

/// Experiment token for this device.
@property (readonly, nonatomic) LABExperimentsToken experimentsToken;

@end

/// Default implementation of \c LABExperimentsTokenProvider. The token is generated once and stored
/// in \c storage. Subsequent runs will fetch the token from storage.
@interface LABExperimentsTokenProvider : NSObject <LABExperimentsTokenProvider>

/// Initializes with \c NSUserDefaults for \c storage and a new instance of \c LTRandom for
/// \c random.
- (instancetype)init;

/// Initializes with \c storage to store and load the \c LABExperimentsToken from and \c random
/// to generate random token if needed.
- (instancetype)initWithStorage:(id<LTKeyValuePersistentStorage>)storage random:(LTRandom *)random
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
