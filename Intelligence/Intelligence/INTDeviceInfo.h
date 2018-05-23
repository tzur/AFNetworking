// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Represents a devices info at some point in time.
@interface INTDeviceInfo : MTLModel

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given parameters. Please refer to properties docs for each of the given
/// parameters.
- (instancetype)initWithIdentifierForVendor:(NSUUID *)identifierForVendor
                              advertisingID:(NSUUID *)advertisingID
                 advertisingTrackingEnabled:(BOOL)advertisingTrackingEnabled
                                 deviceKind:(NSString *)deviceKind
                                 iosVersion:(NSString *)iosVersion appVersion:(NSString *)appVersion
                            appVersionShort:(NSString *)appVersionShort
                                   timeZone:(NSString *)timeZone
                                    country:(nullable NSString *)country
                          preferredLanguage:(nullable NSString *)preferredLanguage
                         currentAppLanguage:(nullable NSString *)currentAppLanguage
                            purchaseReceipt:(nullable NSData *)purchaseReceipt
                            appStoreCountry:(nullable NSString *)appStoreCountry
                             inLowPowerMode:(nullable NSNumber *)inLowPowerMode
                                 firmwareID:(nullable NSString *)firmwareID
                        usageEventsDisabled:(nullable NSNumber *)usageEventsDisabled
    NS_DESIGNATED_INITIALIZER;

/// Returns a new instance of \c INTDeviceInfo whith all properties as the receivers' and
/// \c identifierForVendor property is set to the given \c identifierForVendor.
- (instancetype)deviceInfoWithIdentifierForVendor:(NSUUID *)identifierForVendor;

/// ID for vendor, provided by Apple. This ID is consistent as long as any Lightricks app is
/// installed. This ID is a zero UUID if no \c identifierForVendor was available before the creation
/// of the receiver, and <tt>-[UIDevice identifierForVendor]</tt> is \c nil.
///
/// @see -[UIDevice identifierForVendor]
@property (readonly, nonatomic) NSUUID *identifierForVendor;

/// Advertising ID, provided by Apple. in iOS 10.0 and above this ID is a zero UUID
/// \c advertisingTrackingEnabled is \c NO.
///
/// @see -[ASIdentifierManager advertisingIdentifier]
@property (readonly, nonatomic) NSUUID *advertisingID;

/// \c NO means that \c advertisingID should be used only for the following purposes: frequency
/// capping, attribution, conversion events, estimating the number of unique users, advertising
/// fraud detection, and debugging.
///
/// @see -[ASIdentifierManager isAdvertisingTrackingEnabled]
@property (readonly, nonatomic) BOOL advertisingTrackingEnabled;

/// String representation of the device kind the app runs on.

/// @see -[UIDevice lt_deviceKindString]
@property (readonly, nonatomic) NSString *deviceKind;

/// Current iOS version.
@property (readonly, nonatomic) NSString *iosVersion;

/// Current app version (bundle version). Corresponds with the value for \c kCFBundleVersionKey
/// in the app bundle.
@property (readonly, nonatomic) NSString *appVersion;

/// Current app version (bundle version), short string. Corresponds with the value for
/// "CFBundleShortVersionString" in the app bundle.
@property (readonly, nonatomic) NSString *appVersionShort;

/// The geopolitical region ID that the device is located in. The format of the string is
/// <tt>Continent/City</tt>, and is an Apple defined format.
/// <tt>+[NSTimeZone knownTimeZoneNames]</tt> contains the available time zone strings.
@property (readonly, nonatomic) NSString *timeZone;

/// English short name of the current country of the device, as defined by ISO 3166-1, if available.
/// If the name is unavailable, then the Alpha-2 code (i.e. HK, US, IL), as defined by ISO 3166-1 is
/// used. \c nil if nither the name or the county code is available.
@property (readonly, nonatomic, nullable) NSString *country;

/// Preferred language for the current device. This is the current iOS interface language, the one
/// appearing on top of the list in Settings-General-Language & Region. The format of the string is
/// a canonicalized IETF BCP 47 representation of the preferred language. \c nil if the language is
/// unavailable.
@property (readonly, nonatomic, nullable) NSString *preferredLanguage;

/// Language the app is currently using. In case a localization of the preferred language is not
/// available, the best available language will be selected (according to the order of the languages
/// in Settings-General-Language & Region). The format of the string is a canonicalized IETF BCP 47
/// representation of the preferred language. \c nil if the language is unavailable.
@property (readonly, nonatomic, nullable) NSString *currentAppLanguage;

/// Purchase receipt of this app, provided by Apple.
@property (readonly, nonatomic, nullable) NSData *purchaseReceipt;

/// The Alpha-2 name (i.e. HK, US, IL) of the current country of the App store the device is
/// associated with, as defined by ISO 3166-1. \c nil if the country is unavailable, for example,
/// when there is no internet connection.
@property (readonly, nonatomic, nullable) NSString *appStoreCountry;

/// \c @YES if the device is jailbroken. \c nil if the information is unavailable or the instance is
/// of an older version.
/// @note property name does not resemble real meaning, to obscure from malicious sources.
@property (readonly, nonatomic, nullable) NSNumber *inLowPowerMode;

/// Team identifier that signed the app binary, or \c nil if no signing exists, no team identifier
/// exists (old signing info) or fetching the signing info failed.
/// @note property name does not resemble real meaning, to obscure from malicious sources.
@property (readonly, nonatomic, nullable) NSString *firmwareID;

/// \c @YES if usage events are disabled. \c nil if the information is unavailable or the
/// instance is of an older version.
@property (readonly, nonatomic, nullable) NSNumber *usageEventsDisabled;

@end

NS_ASSUME_NONNULL_END
