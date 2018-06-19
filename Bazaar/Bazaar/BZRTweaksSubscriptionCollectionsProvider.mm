// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweaksSubscriptionCollectionsProvider.h"

#import <FBTweak/FBTweak.h>
#import <FBTweak/FBTweakCollection.h>
#import <LTKit/NSArray+Functional.h>
#import <Milkshake/FBMutableTweak+RACSignalSupport.h>

#import "BZRProductsInfoProvider.h"
#import "BZRReceiptModel+GenericSubscription.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Consts
#pragma mark -

static const NSInteger kKeypathIndex = 0;
static const NSInteger kNameIndex = 1;

/// Array of keypath sand their respective display strings used to create the subscription
/// info tweaks.
static auto const kTweaksKeypathsAndNames = @[
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId),
    @"Product ID"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired),
    @"Is expired?"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId),
    @"Original transaction ID"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime),
    @"Original purchase date"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, lastPurchaseDateTime),
    @"Last purchase date"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime),
    @"Expiration date"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime),
    @"Cancellation date"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.willAutoRenew),
    @"Pending: Will auto renew"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.expectedRenewalProductId),
    @"Pending: Auto renew product ID"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo,pendingRenewalInfo.isPendingPriceIncreaseConsent),
    @"Pending: Consents to pending increase"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.expirationReason),
    @"Pending: Expiration reason"
  ],
  @[
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo.isInBillingRetryPeriod),
    @"Pending: is in billing retry period"
  ]
];

#pragma mark -
#pragma mark FBPersistentTweak keypath extension.
#pragma mark -

/// Extension to \c FBPersistentTweak which allows initialization with a keypath which is used to
/// create a  \c title. This keypath is visible as a property.
@interface FBPersistentTweak (SubscriptionInfoKeypath)

/// Initialize the \c FBPersistentTweak using \c keyPath which is used to generate an identifier,
/// \c name is used to set the title and with \c defaultValue which is the initial value of the
/// tweak.
- (instancetype)initWithKeypath:(NSString *)keyPath name:(NSString *)name
                   defaultValue:(FBTweakValue)defaultValue;

/// The keypath given in the initializer. \c nil in case the keypath can't be extracted from the
/// tweak's identifier.
@property (readonly, nonatomic, nullable) NSString *bzr_subscriptionInfoKeypath;

@end

@implementation FBPersistentTweak (SubscriptionInfoKeypath)

- (instancetype)initWithKeypath:(NSString *)keyPath name:(NSString *)name
                   defaultValue:(FBTweakValue)defaultValue {
  auto identifier = [self bzr_identifierForKeyPath:keyPath];
  return [self initWithIdentifier:identifier name:name defaultValue:defaultValue];
}

- (NSString *)bzr_identifierForKeyPath:(NSString *)keypath {
  return [NSString stringWithFormat:@"%@.%@", [self bzr_editTweakIdentifierPrefix], keypath];
}

- (NSString *)bzr_editTweakIdentifierPrefix {
  return [NSString stringWithFormat:@"%@.subscriptionEdit", kBZRTweakIdentifierPrefix];
}

- (nullable NSString *)bzr_subscriptionInfoKeypath {
  auto prefixRange = [self.identifier rangeOfString:[self bzr_editTweakIdentifierPrefix]];
  if (prefixRange.location == NSNotFound) {
    return nil;
  }
  auto keypathStartIndex = prefixRange.location + prefixRange.length + 1;
  return [self.identifier substringFromIndex:keypathStartIndex];
}

@end

#pragma mark -
#pragma mark BZRTweaksSubscriptionCollectionsProvider
#pragma mark -

@interface BZRTweaksSubscriptionCollectionsProvider ()

/// Underlying provider used to provide the original subscription info.
@property (readonly, nonatomic) id<BZRProductsInfoProvider> productInfoProvider;

/// Tweak used to choose the subscription source.
@property (readonly, nonatomic) FBPersistentTweak *chooseSubscriptionSourceTweak;

/// List of overriding subscription tweaks. The tweaks values will persist between runs of the
/// application.
@property (strong, nonatomic) NSArray<FBPersistentTweak *> *overrideSubscriptionInfoTweaks;

/// Redeclare as readwrite.
@property (strong, readwrite, nonatomic) BZRReceiptSubscriptionInfo *overridingSubscription;

@end

@implementation BZRTweaksSubscriptionCollectionsProvider

@synthesize collections = _collections;
@synthesize subscriptionSourceSignal = _subscriptionSourceSignal;

- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider {
  if (self = [super init]) {
    _productInfoProvider = productsInfoProvider;
    _chooseSubscriptionSourceTweak = [self createChooseSubscriptionSourceTweak];
    _subscriptionSourceSignal = [self createSubscriptionSourceSignal];
    _overrideSubscriptionInfoTweaks = [self createOverrideSubscriptionInfoTweaks];
    _overridingSubscription =
        [BZRReceiptSubscriptionInfo genericActiveSubscriptionWithPendingRenewalInfo];
    [self bindOverridingSubscriptionToTweaks];
    [self setupCollections];
  }
  return self;
}

- (FBPersistentTweak *)createChooseSubscriptionSourceTweak {
  auto identifier =
      [self subscriptionSourceTweakIdentifierForTweakName:@"subscriptionSourceChoose"];
  auto chooseSubscriptionSourceTweak =
      [[FBPersistentTweak alloc] initWithIdentifier:identifier
                                               name:@"Choose subscription source"
                                       defaultValue:@(BZRTweaksSubscriptionSourceOnDevice)];
  chooseSubscriptionSourceTweak.possibleValues = @{
    @(BZRTweaksSubscriptionSourceOnDevice): @"From device",
    @(BZRTweaksSubscriptionSourceGenericActive): @"Generic valid subscription",
    @(BZRTweaksSubscriptionSourceNoSubscription): @"No subscription",
    @(BZRTweaksSubscriptionSourceCustomizedSubscription): @"Customizable subscription"
  };
  return chooseSubscriptionSourceTweak;
}

- (NSString *)subscriptionSourceTweakIdentifierForTweakName:(NSString *)tweakName {
  return [NSString stringWithFormat:@"%@.subscriptionSource.%@",
          kBZRTweakIdentifierPrefix, tweakName];
}

- (RACSignal<BZRTweaksSubscriptionSource *> *)createSubscriptionSourceSignal {
  id initialValue = [self shouldUseDefaultValueForTweak:self.chooseSubscriptionSourceTweak] ?
      self.chooseSubscriptionSourceTweak.defaultValue :
      self.chooseSubscriptionSourceTweak.currentValue;
  return [[[self.chooseSubscriptionSourceTweak shk_valueChanged]
      ignore:nil]
      startWith:initialValue];
}

- (BOOL)shouldUseDefaultValueForTweak:(FBPersistentTweak *)tweak {
  return tweak.currentValue == nil;
}

- (NSArray<FBPersistentTweak *> *)createOverrideSubscriptionInfoTweaks {
  auto genericActiveSubscription =
      [BZRReceiptSubscriptionInfo genericActiveSubscriptionWithPendingRenewalInfo];
  return [kTweaksKeypathsAndNames
      lt_map:^FBPersistentTweak *(NSArray *kepyathAndName) {
        auto tweak = [self createMutableTweakForKeypath:kepyathAndName[kKeypathIndex]
                                               withText:kepyathAndName[kNameIndex]];
        if (tweak.currentValue == nil) {
          tweak.currentValue =
              [genericActiveSubscription valueForKeyPath:kepyathAndName[kKeypathIndex]];
        }
        return tweak;
      }];
}

- (FBPersistentTweak *)createMutableTweakForKeypath:(NSString *)keypath withText:(NSString *)text {
  id _Nullable defaultValue = [self.productInfoProvider.subscriptionInfo valueForKeyPath:keypath];
  auto tweak =
      [[FBPersistentTweak alloc] initWithKeypath:keypath name:text defaultValue:defaultValue];
  if ([defaultValue conformsToProtocol:@protocol(LTEnum)]) {
    tweak.possibleValues = [self createValuesToNamesDictFromEnum:defaultValue];
  }

  return tweak;
}

- (NSDictionary *)createValuesToNamesDictFromEnum:(id<LTEnum>)sourceEnum {
  auto enumNamesToValues = [((id<LTEnum>)[sourceEnum class]) fieldNamesToValues];
  return [NSDictionary dictionaryWithObjects:enumNamesToValues.allKeys
                                     forKeys:enumNamesToValues.allValues];
}

- (void)bindOverridingSubscriptionToTweaks {
  for (FBPersistentTweak *tweak in self.overrideSubscriptionInfoTweaks) {
    [self registerOverridingSubscriptionForChangesByTweak:tweak];
  }
}

- (void)registerOverridingSubscriptionForChangesByTweak:(FBPersistentTweak *)tweak {
  @weakify(self)
  [[[tweak shk_valueChanged]
      ignore:nil]
      subscribeNext:^(FBTweakValue newValue) {
        @strongify(self)
        self.overridingSubscription = [self.overridingSubscription
            modelByOverridingPropertyAtKeypath:tweak.bzr_subscriptionInfoKeypath
                                     withValue:newValue];
      }];
}

- (void)setupCollections {
  RAC(self, collections) = [[RACSignal
      combineLatest:@[
        [self createSubscriptionSourceControlCollectionSignal],
        [self createSubscriptionDetailsCollectionSignal]
      ]]
      map:^NSArray<FBTweakCollection *> *(RACTuple *tupleOfCollections) {
        return [tupleOfCollections allObjects];
      }];
}

- (RACSignal<FBTweakCollection *> *)createSubscriptionSourceControlCollectionSignal {
  auto reloadDataFromDeviceTweak = [self createReloadDataFromDeviceTweak];
  return [self.subscriptionSourceSignal
      map:^FBTweakCollection *(BZRTweaksSubscriptionSource *source) {
        auto tweaks = [self shouldAddReloadTweak:source] ?
            @[self.chooseSubscriptionSourceTweak, reloadDataFromDeviceTweak] :
            @[self.chooseSubscriptionSourceTweak];
        return [[FBTweakCollection alloc] initWithName:@"" tweaks:tweaks];
      }];
}

- (FBActionTweak *)createReloadDataFromDeviceTweak {
  return [[FBActionTweak alloc]
      initWithIdentifier:[self subscriptionSourceTweakIdentifierForTweakName:@"reloadData"]
                    name:@"Reload subscription data from device"
                   block:^{
                     [self reloadPersistentTweaksDataFromSubscription:
                      self.productInfoProvider.subscriptionInfo];
                   }];
}

- (void)reloadPersistentTweaksDataFromSubscription:(BZRReceiptSubscriptionInfo *)subscription {
  auto newPersistentTweaks = [self createOverrideSubscriptionInfoTweaks];
  for (FBPersistentTweak *tweak in newPersistentTweaks) {
    tweak.currentValue = [subscription valueForKeyPath:tweak.bzr_subscriptionInfoKeypath];
  }
  self.overrideSubscriptionInfoTweaks = newPersistentTweaks;
}

- (BOOL)shouldAddReloadTweak:(BZRTweaksSubscriptionSource *)subscriptionSource {
  return [subscriptionSource isEqual:@(BZRTweaksSubscriptionSourceCustomizedSubscription)];
}

- (RACSignal<FBTweakCollection *> *)createSubscriptionDetailsCollectionSignal {
  return  [RACSignal
      switch:self.subscriptionSourceSignal
       cases:@{
         @(BZRTweaksSubscriptionSourceOnDevice):
             [self createOnDeviceSubscriptionInfoCollectionSignal],
         @(BZRTweaksSubscriptionSourceCustomizedSubscription):
             [self createOverridingSubscriptionCollectionSignal]
       }
     default:[RACSignal return:[[FBTweakCollection alloc] initWithName:@"" tweaks:@[]]]
  ];
}

- (RACSignal<FBTweakCollection *> *)createOnDeviceSubscriptionInfoCollectionSignal {
  return [[RACObserve(self.productInfoProvider, subscriptionInfo)
      map:^NSArray<FBTweak *> *(BZRReceiptSubscriptionInfo * _Nullable info) {
        return [self createReadonlyTweaksForInfo:info];
      }]
      map:^FBTweakCollection *(NSArray<FBTweak *> *tweaks) {
        return [[FBTweakCollection alloc] initWithName:@"Subscription info" tweaks:tweaks];
      }];
}

- (NSArray<FBTweak *> *)createReadonlyTweaksForInfo:(nullable BZRReceiptSubscriptionInfo *)info {
  return [kTweaksKeypathsAndNames lt_map:^FBTweak *(NSArray *kepyathAndName) {
    return [self createReadonlyTweakForKeypath:kepyathAndName[kKeypathIndex]
                                      withText:kepyathAndName[kNameIndex]
                              subscriptionInfo:info];
  }];
}

- (FBTweak *)createReadonlyTweakForKeypath:(NSString *)keypath withText:(NSString *)text
                          subscriptionInfo:(nullable BZRReceiptSubscriptionInfo *)subscriptionInfo {
  id _Nullable currentValue = [subscriptionInfo valueForKeyPath:keypath];
  if ([currentValue conformsToProtocol:@protocol(LTEnum)]) {
    currentValue = [((id<LTEnum>)currentValue) name];
  } else if ([self isBooleanType:currentValue]) {
    currentValue = [currentValue boolValue] ? @"Yes" : @"No";
  }
  auto identifier = [self subscriptionInfoTweakIdentifierForKeypath:keypath];
  return [[FBTweak alloc] initWithIdentifier:identifier name:text currentValue:currentValue];
}

- (BOOL)isBooleanType:(id)value {
  return ([value isKindOfClass:NSNumber.class] && strcmp([value objCType], @encode(char)) == 0);
}

- (NSString *)subscriptionInfoTweakIdentifierForKeypath:(NSString *)keypath {
  return [NSString stringWithFormat:@"%@.subscriptionInfo.%@", kBZRTweakIdentifierPrefix, keypath];
}

- (RACSignal<FBTweakCollection *> *)createOverridingSubscriptionCollectionSignal {
  return [RACObserve(self, overrideSubscriptionInfoTweaks)
      map:^FBTweakCollection *(NSArray<FBPersistentTweak *> *tweaks) {
        return [[FBTweakCollection alloc] initWithName:@"Subscription info" tweaks:tweaks];
      }];
}

@end

NS_ASSUME_NONNULL_END
