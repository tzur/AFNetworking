// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct, BZRReceiptSubscriptionInfo;

/// Enum for Enlight ecosystem applications that the subscription management componen supports.
LTEnumDeclare(NSUInteger, EUISMApplication,
  EUISMApplicationPhotofox,
  EUISMApplicationVideoleap,
  EUISMApplicationQuickshot,
  EUISMApplicationPixaloop
);

/// Category providing properties for a \c EUISMApplication enum value.
@interface EUISMApplication (Properties)

/// Full name of the application in human readable format.
@property (readonly, nonatomic) NSString *fullName;

/// Application bundle ID.
@property (readonly, nonatomic) NSString *bundleID;

/// The URL scheme to use for deep linking into the application
@property (readonly, nonatomic) NSString *urlScheme;

/// URL of the application thumbnail
@property (readonly, nonatomic) NSURL *thumbnailURL;

@end

/// Possible subscription types.
typedef NS_ENUM(NSUInteger, EUISMSubscriptionType) {
  EUISMSubscriptionTypeSingleApp,
  EUISMSubscriptionTypeEcoSystem
};

/// Information about a subscription product. This value object is a wrapper for \c BZRProduct
/// objects that are subscription products and enriches them with properties that are useful for the
/// subscription management component.
@interface EUISMProductInfo : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given properties.
- (instancetype)initWithProduct:(BZRProduct *)subscriptionProduct
               subscriptionType:(EUISMSubscriptionType)subscriptionType
    NS_DESIGNATED_INITIALIZER;

/// The Bazaar subscription product this object wraps.
@property (readonly, nonatomic) BZRProduct *product;

/// The type of the subscription product.
@property (readonly, nonatomic) EUISMSubscriptionType subscriptionType;

@end

/// The main model for the subscription management component.
@interface EUISMModel : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given properties. The given \c subscriptionGroupProductsInfo must not
/// include the given \c currentProductInfo and the given \c pendingProductInfo.
- (instancetype)initWithCurrentApplication:(EUISMApplication *)currentApplication
    currentSubscriptionInfo:(nullable BZRReceiptSubscriptionInfo *)currentSubscriptionInfo
    currentProductInfo:(nullable EUISMProductInfo *)currentProductInfo
    pendingProductInfo:(nullable EUISMProductInfo *)pendingProductInfo
    subscriptionGroupProductsInfo:(NSSet<EUISMProductInfo *> *)subscriptionGroupProductsInfo
    NS_DESIGNATED_INITIALIZER;

/// The application that this component is currently used from.
@property (readonly, nonatomic) EUISMApplication *currentApplication;

/// Information about the current subscription of the user.
@property (readonly, nonatomic, nullable) BZRReceiptSubscriptionInfo *currentSubscriptionInfo;

/// Information about the current subscription product the user is subscribed to.
@property (readonly, nonatomic, nullable) EUISMProductInfo *currentProductInfo;

/// Information about the subscription product the user will be subscribd to after the next renewal.
@property (readonly, nonatomic, nullable) EUISMProductInfo *pendingProductInfo;

/// Information about the subscription products that are in the same subscription group of the
/// current product.
@property (readonly, nonatomic) NSSet<EUISMProductInfo *> *subscriptionGroupProductsInfo;

@end

NS_ASSUME_NONNULL_END
