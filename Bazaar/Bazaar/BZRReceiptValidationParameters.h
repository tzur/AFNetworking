// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Value object representing the set of parameters required by \c BZRReceiptValidator in order
/// to validate a receipt.
@interface BZRReceiptValidationParameters : NSObject

/// Initializes the receipt validation parameters with default values. \c receiptData and
/// \c applicationBundleId are taken from the main application bundle and \c deviceId will be the
/// ID for vendor of the current device.
/// @note If the application receipt is missing or can not be read for any reason then
/// initialization fails and \c nil is returned.
+ (nullable instancetype)defaultParameters;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the request parameters with the specified \c receiptData \c applicationBundleId and
/// \c deviceId. If either \c receiptData or \c applicationBundleId are \c nil an
/// \c NSInvalidArgumentException is raised.
- (instancetype)initWithReceiptData:(NSData *)receiptData
                applicationBundleId:(NSString *)applicationBundleId
                           deviceId:(nullable NSUUID *)deviceId NS_DESIGNATED_INITIALIZER;

/// Content of the receipt to validate.
@property (readonly, nonatomic) NSData *receiptData;

/// Expected application identifier that the receipt was issued for.
@property (readonly, nonatomic) NSString *applicationBundleId;

/// Expected device identifier that the receipt was issued for.
@property (readonly, nonatomic, nullable) NSUUID *deviceId;

@end

NS_ASSUME_NONNULL_END
