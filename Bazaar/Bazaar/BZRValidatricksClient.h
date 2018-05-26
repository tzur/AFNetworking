// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksModels.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationParameters, BZRReceiptValidationStatus, FBRHTTPClient;

/// Client providing convenience methods to make requests to Validatricks server over HTTP.
@interface BZRValidatricksClient : NSObject

/// Initializes the client with \c HTTPClient used to make the HTTP requests to the server.
///
/// @note Requests made by \c BZRValidatricksClient are to relative paths, so the given
/// \c HTTPClient should be configured with a base server URL.
- (instancetype)initWithHTTPClient:(FBRHTTPClient *)HTTPClient;

/// Validate the authenticity and the integrity of the receipt provided in \c parameters and get
/// its content.
///
/// Returns a signal that sends the request to Validatricks server with the specified parameters
/// upon subscription, delivers the response as a single \c BZRReceiptValidationStatus instance and
/// then completes. The signal errs with \c BZRErrorCodeValidatricksRequestFailed code for any type
/// of failure. The error will contain the underlying error (or errors) if any. In case the server
/// returned an HTTP error response corresponding to \c BZRValidatricksErrorInfo format the error
/// information will be provided under the error's \c bzr_validatricksErrorInfo property.
- (RACSignal<BZRReceiptValidationStatus *> *)
    validateReceipt:(BZRReceiptValidationParameters *)parameters;

/// Get the balance of credit of type \c creditType for the user identified by \c userId.
///
/// Returns a signal that sends the request to Validatricks server with the specified parameters
/// upon subscription, delivers the response as a single \c BZRUserCreditStatus instance and then
/// completes. The signal errs with \c BZRErrorCodeValidatricksRequestFailed code for any type of
/// failure. The error will contain the underlying error (or errors) if any. In case the server
/// returned an HTTP error response corresponding to \c BZRValidatricksErrorInfo format the error
/// information will be provided under the error's \c bzr_validatricksErrorInfo property.
- (RACSignal<BZRUserCreditStatus *> *)getCreditOfType:(NSString *)creditType
                                              forUser:(NSString *)userId;

/// Get the prices of consumables of the specified \c consumableTypes in credit units of type
/// \c creditType.
///
/// Returns a signal that sends the request to Validatricks server with the specified parameters
/// upon subscription, delivers the response as a single \c BZRConsumableTypesPriceInfo instance and
/// then completes. The signal errs with \c BZRErrorCodeValidatricksRequestFailed code for any type
/// of failure. The error will contain the underlying error (or errors) if any. In case the server
/// returned an HTTP error response corresponding to \c BZRValidatricksErrorInfo format the error
/// information will be provided under the error's \c bzr_validatricksErrorInfo property.
- (RACSignal<BZRConsumableTypesPriceInfo *> *)getPricesInCreditType:(NSString *)creditType
    forConsumableTypes:(NSArray<NSString *> *)consumableTypes;

/// Redeem a collection of \c consumableItems, i.e. mark the user identified by \c userId as
/// eligible for these items while deducting credit of type \c creditType from the user's balance.
/// The amount of credit to deduct is determined by the type of of consumable as specified by the
/// consumable item's \c consumableType property. For consumable items that the user has already
/// redeemed in the past no credit will be deducted.
///
/// Returns a signal that sends the request to Validatricks server with the specified parameters
/// upon subscription, delivers the response as a single \c BZRRedeemConsumablesStatus instance and
/// then completes. The signal errs with \c BZRErrorCodeValidatricksRequestFailed code for any type
/// of failure. The error will contain the underlying error (or errors) if any. In case the server
/// returned an HTTP error response corresponding to \c BZRValidatricksErrorInfo format the error
/// information will be provided under the error's \c bzr_validatricksErrorInfo property.
///
/// @note In case the user does not have enough credit to complete the request, the signal will err,
/// the error's \c bzr_validatricksErrorInfo.error will be \c kBZRValidatricksNotEnoughCreditError
/// and \c bzr_validatricksErrorInfo will be of type \c BZRValidatricksNotEnoughCreditErrorInfo,
/// providing additional error information.
- (RACSignal<BZRRedeemConsumablesStatus *> *)
    redeemConsumableItems:(NSArray<BZRConsumableItemDescriptor *> *)consumableItems
    ofCreditType:(NSString *)creditType userId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
