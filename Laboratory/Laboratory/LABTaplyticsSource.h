// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABAssignmentsSource.h"

@class LABExperimentsTokenProvider;

@protocol LTKeyValuePersistentStorage, LABTaplytics;

NS_ASSUME_NONNULL_BEGIN

/// Custom data key for experiments token.
extern NSString * const kLABCustomDataExperimentsTokenKey;

/// Source providing assignments from Taplytics.
///
/// Taplytics experiment must be configured in a certain way in order to be exposed by this class.
/// By design, the Taplytics SDK does not provide the assignments of each active variant, and only
/// provides a list of active variants and a list of active assignments without any link between the
/// lists.
///
/// Due to this design, when setting up an experiment in Taplytics, another meta key should be added
/// to the list of keys in the experiment, specifying the names of the keys in the experiment.
/// This meta key should have the name "__Keys_<Experiment Name>" and it's value must be a JSON
/// array containing the names of the keys in the experiment (excluding other meta keys).
///
/// Also, any experiment having the prefix "__Remote_" is ignored by this source, as this prefix
/// marks the experiment as remote configuration, which is not supported by Laboratory.
///
/// When the \c stabilizeUserExperienceAssignments method is called for the first time, the source
/// stores the active variants and their assignments to \c storage. On subsequent runs, these stored
/// variants and assignemts are returned as the \c activeVariants. That means that new experiments
/// will not be exposed, and any change in the assigments or in the activity of the experiment, is
/// not exposed, up to the following exceptions:
///
/// 1. Experiemtns archived in Taplytics are removed from \c activeVariants.
/// 2. Assignments with overriden keys. To set overrriden keys create a meta key with the name
/// "__Override_<Experiment Name>" with a JOSN array value containing the names of the keys you want
/// to overide. In that case the string values in the array will be treated as keys that should not
/// be pulled from the storage, but their value should be pulled from the latest value in Taplytics.
/// 3. New experiments having "ExistingUsers" prefix are exposed, but do not change after the first
/// time.
///
/// You should use overriden key when certain keys for experiments need to be updated even though
/// \c stabilizeUserExperienceAssignments has been previously called.
///
/// Any Taplytics custom data can be added using the \c customData parameter. The given custom data
/// is augmented with the experiments token provided by the \c experimentsTokenProvider using
/// \c kLABCustomDataExperimentsTokenKey. You can use custom data to send applilcation specific data
///  to Taplytics, then you can use the data to distribute experiments to users with specific data.
///
/// @see https://taplytics.com/docs/guides/experiment-distribution#customData
@interface LABTaplyticsSource : NSObject <LABAssignmentsSource, LABExperimentsSource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c apiKey of the Taplytics SDK, \c customData to send to Taplytics
/// and \c experimentsTokenProvider to provide the token to send to Taplytics.
- (instancetype)initWithAPIKey:(NSString *)apiKey
      experimentsTokenProvider:(LABExperimentsTokenProvider *)experimentsTokenProvider
                    customData:(NSDictionary<NSString *, id> *)customData;

/// Initializes with the given \c apiKey of the Taplytics SDK, \c experimentsTokenProvider to
/// provide the token to send to Taplytics, \c customData to send to Taplytics, the \c taplytics SDK
/// object, and \c storage to store locked keys and assignments to.
- (instancetype)initWithAPIKey:(NSString *)apiKey
      experimentsTokenProvider:(LABExperimentsTokenProvider *)experimentsTokenProvider
                    customData:(NSDictionary<NSString *, id> *)customData
                     taplytics:(id<LABTaplytics>)taplytics
                       storage:(id<LTKeyValuePersistentStorage>)storage
    NS_DESIGNATED_INITIALIZER;

/// Underlying Taplytics SDK object. This object represents an already functional Taplytics service.
@property (readonly, nonatomic) id<LABTaplytics> taplytics;

@end

NS_ASSUME_NONNULL_END
