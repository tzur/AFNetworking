// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@class TLManager;

/// Taplytics experiment properties. Contains the \c activeExperimentsAndVariations,
/// \c activeDynamicVariables and \c allExperiments. Since assignment and experiment data can change
/// over time, this protocol groups this information in order to capture the state of the properties
/// in a specific point in time.
@protocol LABTaplyticsProperties <NSObject>

/// Dictionary mapping all active experiments to their selected variation.
@property (readonly, nonatomic)
    NSDictionary<NSString *, NSString *> *activeExperimentsToVariations;

/// Currently active dynamic variables. The dynamic variables are the assignments for all the active
/// experiments.
@property (readonly, nonatomic) NSDictionary<NSString *, id> *activeDynamicVariables;

/// All experiments in the source, both active and inactive, mapped to their possible variations.
@property (readonly, nonatomic)
    NSDictionary<NSString *, NSSet<NSString *> *> *allExperimentsToVariations;

@end

/// Implementers of this protocol provide access to Taplytics API.
@protocol LABTaplytics <NSObject>

/// Starts Taplytics service with the given \c apiKey and \c options.
///
/// @see <tt> +[Taplytics startTaplyticsAPIKey:options]</tt> for available options.
- (void)startTaplyticsWithAPIKey:(NSString *)apiKey options:(nullable NSDictionary *)options;

/// Logs an event with the given \c name, \c value and \c properties. \c value is used by
/// \c Taplytics automatically for aggregation purposes. \c properties must be a flat dictionary
/// with only \c NSString and \c NSNumber objects.
- (void)logEventWithName:(NSString *)name value:(nullable NSNumber *)value
              properties:(nullable NSDictionary *)properties;

/// Sets the given \c userAttributes to send to Taplytics servers in order to filter experiments
/// using this data.
///
/// @note This method must be called before the \v startTaplyticsWithAPIKey:options: method.
///
/// @see <tt>+[Taplytics setUserAttributes:]</tt> for the available user attributes fields.
- (void)setUserAttributes:(nullable NSDictionary *)userAttributes;

/// Block to be used when calling the \c propertiesLoadedWithCompletion: method.
typedef void (^LABTaplyticsPropertiesLoadedBlock)(BOOL success);

/// Calls \c completionBlock with \c YES when all Taplytics properties are done loading successfully
/// from the network, and \c NO otherwise. After \c completionBlock is called the method
/// \c fetchRunningExperimentsAndVariationsWithCompletion: executes synchronously.
- (void)propertiesLoadedWithCompletion:(LABTaplyticsPropertiesLoadedBlock)completionBlock;

/// Block to be used when calling the \c refreshPropertiesInBackground: method.
typedef void (^LABTaplyticsBackgroundFetchBlock)(UIBackgroundFetchResult result);

/// Fetches the latest properties from Taplytics servers in the background and uses that
/// configuration as the local configuration. \c completionBlock is called with the results of the
/// fetch.
///
/// This method should be called from the
/// <tt>-[UIApplicationDelegate application:performFetchWithCompletionHandler:]</tt> callback.
- (void)refreshPropertiesInBackground:(LABTaplyticsBackgroundFetchBlock)completionBlock;

/// Block to be used when calling the \c performLoadPropertiesFromServer: method.
typedef void (^LABTaplyticsLoadPropertiesFromServerBlock)(BOOL success);

/// Block to be used when calling the \c fetchPropertiesWithCompletion: and
/// \c fetchPropertiesForExperiment:withVariation:completion: methods. It is guaranteed that either
/// \c properties or \c error will be present.
typedef void (^LABTaplyticsFetchPropertiesBlock)
    (id<LABTaplyticsProperties> _Nullable properties, NSError * _Nullable error);

/// Fetches the latest properties from Taplytics servers and uses that configuration as the local
/// configuration. \c completionBlock is called with the results of the fetch.
- (void)performLoadPropertiesFromServer:(LABTaplyticsLoadPropertiesFromServerBlock)completionBlock;

/// Request the assignments for the given \c experiment and \c variation from Taplytics' servers.
/// \c completionBlock is called with the results of the fetch.
///
/// \c completionBlock is called with error if:
/// 1. The \c experiment doesn't exist or \c variation doesn't exist for \c experiment with
/// errorcode \c LABErrorCodeVariantForExperimentNotFound.
/// 2. There was an error in requesting the assignments with errorcode \c LABErrorCodeFetchFailed.
- (void)fetchPropertiesForExperiment:(NSString *)experiment
                       withVariation:(NSString *)variation
                          completion:(LABTaplyticsFetchPropertiesBlock)completionBlock;

/// Requests the latest properties for the current configuration from Taplytics servers. Unlike the
/// \c performLoadPropertiesFromServer: method, it does not update the state of the Taplytics SDK.
/// \c completionBlock is called with the results of the fetch.
- (void)fetchPropertiesWithCompletion:(LABTaplyticsFetchPropertiesBlock)completionBlock;

/// Current Taplytics properties. \c nil if the data was not yet fetched.
///
/// @note This property is KVO-Compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) id<LABTaplyticsProperties> properties;

@end

/// Default implementation of the \c LABTaplytics protocol. Uses the Taplytics SDK as the underlying
/// source.
@interface LABTaplytics : NSObject <LABTaplytics>

/// Initializes with the singleton object for \c TLManager,
///
/// @see +[TLManager sharedManager]
- (instancetype)init;

/// Initializes with the given \c tlManager to be used as the main Taplytics SDK object.
- (instancetype)initWithTLManager:(TLManager *)tlManager NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
