// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "TLProperties.h"

NS_ASSUME_NONNULL_BEGIN

/// Provides access to Taplytics configuration.
///
/// Impersonates the undocumented \c TLManager class. The implementation for this object is in the
/// Taplytics SDK framework. No \c @implementation block should be created to this class.
@interface TLManager : NSObject

/// Returns the singleton object for this class.
+ (TLManager *)sharedManager;

/// Block to be used when calling the \c getPropertiesFromServer:returnBlock: method.
typedef void (^LABTLGetPropertiesFromServerBlock)
(TLProperties * _Nullable properties, BOOL unknown, NSError * _Nullable error);

/// Request the \c LABLTProperties object from Taplytics servers for a given \c variationConfig.
/// \c variationConfig should contain the following keys and values:
/// @code
/// @{
///   @"exp": experimentID,
///   @"sid": sessionID,
///   @"var": variantID
/// };
/// @endcode
///
/// \c completionBlock is invoked with the returned \c LABTLProperties for the given
/// \c variationConfig. If \c variationConfig is \c nil, \c completionBlock is invoked with the
/// default \c LABTLProperties for this device.
///
/// @note \c variationConfig states only one variant.
- (void)getPropertiesFromServer:(nullable NSDictionary *)variationConfig
                    returnBlock:(LABTLGetPropertiesFromServerBlock)completionBlock;

/// Block to be used when calling the \c performLoadPropertiesFromServer:returnBlock: method.
typedef void (^LABTLLoadPropertiesFromServerBlock)(BOOL success);

/// Performs an update to the local Taplytics configuration according to \c variationConfig. This
/// method will request the \c LABTLProperties of the given \c variationConfig from Taplytics
/// servers and set \c tlProperties to it.
///
/// \c completion block is called with the result of the request.
///
/// @note If \c completionBlock returns a successful result, \c tlProperties is updated.
- (void)performLoadPropertiesFromServer:(nullable NSDictionary *)variationConfig
                            returnBlock:(LABTLLoadPropertiesFromServerBlock)completionBlock;

/// Object containing the entire state of the Taplytics SDK.
///
/// @note This property is KVO-Compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) TLProperties *tlProperties;

@end

NS_ASSUME_NONNULL_END
