// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@class SPXBaseProductAxisValue, SPXBenefitAxisValue;

@protocol SPXProductAxisValue;

/// Value object defining which benefit axis values to apply on which base axis values.
@interface SPXCoupon : MTLModel <MTLJSONSerializing>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c baseProductValues as the values to apply \c benefitValues on.
/// \c benefitValues will be applied on *all* products with \c baseProductValues.
///
/// Any value is allowed in \c baseProductValues, even from the same axis. This allow creating
/// coupons that affect multiple products.
///
/// @note \c benefitValues must not specify multiple values for the same axis.
///
/// @important Any axis in the product matrix, but not in any value in \c baseProductValues, will
/// also have \c benefitValues applied on.
///
/// @example If the product matrix has 2 base product axes, A and B, with values X, Y and U, V
/// respectively, and \c baseProductValues is set to be X. Both products X.U and X.V will get
/// \c benefitValues.
- (instancetype)initWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                            benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues;

/// Returns a new coupon with \c baseProductValues as the values to apply \c benefitValues on.
///
/// @see \c initWithBaseProductValues:benefitValues:
+ (instancetype)couponWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                              benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues;

/// Registers the axis class specified by \c axis with the name specified by \c axisName for
/// serialization. Axes classes that were not registered will fail to pass
/// serialization/deserialization. Returns \c YES if the registeration succeeded and \c NO
/// otherwise.
///
/// @note If the class specified by \c axisClass doesn't conform to \c SPXProductAxis, \c NO will be
/// returned and \c error will be populated with an error containing the error code
/// \c SPXErrorCodeAxisRegisterationFailed.
///
/// @note If the axis is already registered or if \c axisName is already associated with a class,
/// \c NO will be returned and \c error will be populated with an error containing the error code
/// \c SPXErrorCodeAxisRegisterationFailed.
///
/// @note The following axes are pre-registered:
/// - SPXBenefitProductAxisDiscountLevel -> "DiscountLevel"
/// - SPXBenefitProductAxisFreeTrialDuration -> "FreeTrialDuration"
/// - SPXBaseProductAxisSubscriptionPeriod -> "SubscriptionPeriod"
+ (BOOL)registerAxisForSerialization:(Class)axisClass withName:(NSString *)axisName
                               error:(NSError * __autoreleasing *)error;

/// Deregisters the axis class specified by \c axis for serialization. After deserialization the
/// class won't be able to be deserialized/serialized. If the class specified by \c axisClass is not
/// registered the receiver will do nothing.
+ (void)deregisterAxisForSerialization:(Class)axisClass;

/// Product with these base product values will have \c benefitValues.
@property (readonly, nonatomic) NSArray<SPXBaseProductAxisValue *> *baseProductValues;

/// Benefit values to apply on products with \c baseProductValues.
@property (readonly, nonatomic) NSArray<SPXBenefitAxisValue *> *benefitValues;

@end

/// Value object containing coupons and expiry date grouped together to represent a single
/// voucher.
///
/// A voucher can be applied on base product values, to get a product descriptors.
/// @see [SPXProductDescriptorsFactory productDescriptorsWithVoucher:withError:]
@interface SPXVoucher : MTLModel <MTLJSONSerializing>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c name to identify the voucher, \c coupons to apply on base
/// products and \c expiryDate as the last date this voucher can be used (in UTC).
///
/// @note This class does not check for the validity of the \c coupons, as they can conflict.
/// Validity is checked when applying the coupon.
- (instancetype)initWithName:(NSString *)name coupons:(NSArray<SPXCoupon *> *)coupons
                  expiryDate:(NSDate *)expiryDate;

/// Creates a string that contains the encoded receiver and a signature based on the given \c key.
/// The voucher can be later recreated using the \c voucherWithSignedString:key: method, if
/// the same key is used.
///
/// The method performs these steps to encode the receiver:
/// 1. Serializes using Mantle's API to \c NSData.
/// 2. The data is compressed using ZLIB.
/// 3. The compressed data is encrypted using AES128 with MD5 of \c key as the key.
///
/// The encrypted data is then signed with HMAC-SHA256 using \c key and prepended to the encrypted
/// voucher. The entire buffer is then encoded with URL-safe-base64 and returned.
///
/// \c nil is returned and \c error is populated with SPXErrorCodeDeserializationFailed when any of
/// the above steps fail.
- (nullable NSString *)serializeAndSignWithKey:(NSString *)key error:(NSError **)error;

/// Creates a new voucher from the given \c serializedVoucher. It is expected that
/// \c serializedVoucher is a URL-safe-base64 encoded buffer containing a 256-bit signature
/// followed by an encrypted voucher.
///
/// Once the signature is decoded it is verified to match the encrypted voucher.
///
/// The method performs these steps to decode the voucher:
/// 1. Decrypts using AES128 using with MD5 of \c key as the key.
/// 2. Decompresses with decrypted data using ZILB.
/// 3. Deserialized the decompressed data using Mantle's API.
///
/// \c nil is returned and \c error is populated with the following error codes:
/// 1. SPXErrorCodeSignatureValidationFailed - The signature doesn't match the encoded voucher
///    using the given \c key.
/// 2. SPXErrorCodeDeserializationFailed - When any of the above steps fail.
+ (nullable instancetype)voucherWithSerializedString:(NSString *)string key:(NSString *)key
                                               error:(NSError **)error;

/// Name of the voucher.
@property (readonly, nonatomic) NSString *name;

/// All the coupons in this voucher.
@property (readonly, nonatomic) NSArray<SPXCoupon *> *coupons;

/// Expiry date for this voucher. The last date in UTC this voucher is valid.
@property (readonly, nonatomic) NSDate *expiryDate;

@end

NS_ASSUME_NONNULL_END
