// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRValidatricksRobustClient.h"

#import <Fiber/FBRHTTPClient.h>
#import <LTKit/NSArray+Functional.h>
#import <Milkshake/SHKTweakInline.h>

#import "BZREvent.h"
#import "BZRReceiptEnvironment.h"
#import "BZRValidatricksSessionConfigurationProvider.h"
#import "NSErrorCodes+Bazaar.h"
#import "RACSignal+Bazaar.h"

/// Latest version of Validatricks receipt validator.
static NSString * const kLatestValidatorVersion = @"v1";

/// A block that invokes one of the methods of the protocol \c BZRValidatricksClient and returns its
/// result.
typedef RACSignal *(^BZRValidatricksClientCallBlock)(id<BZRValidatricksClient> client);

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatricksRobustClient ()

/// Maximum number of delayed retry attempts.
@property (readonly, nonatomic) NSUInteger delayedRetries;

/// Initial backoff delay.
@property (readonly, nonatomic) NSTimeInterval initialBackoffDelay;

/// Maximum number of retries between delayed retries. These retries will occur immediately one
/// after the other.
@property (readonly, nonatomic) NSInteger immediateRetries;

/// List of underlying clients that can be used.
@property (readonly, nonatomic) NSArray<id<BZRValidatricksClient>> *underlyingClients;

/// Index of the \c currentUnderlyingClient in the \c underlyingClients array.
@property (readwrite, nonatomic) NSNumber *currentClientIndex;

/// The other end of \c eventsSignal;
@property (readonly, nonatomic) RACSubject<BZREvent *> *eventsSubject;

@end

@implementation BZRValidatricksRobustClient

/// Validatricks default servers host names.
static NSArray<NSString *> * const kDefaultValidatricksHostNames = @[
  @"oregon-api.lightricks.com",
  @"virginia-api.lightricks.com",

  // Validatricks Hong-Kong server used to simply redirect all HTTP request to the Tokyo server by
  // sending the client an HTTP 301 response. This is problematic since Chinese clients (in some
  // regions in China) may have issues accessing cloud services outside of China. The desired
  // behavior is that the server will actively proxy requests to the Tokyo server and forward the
  // responses to clients. Replacing the HTTP redirection mechanism with proxy may break clients
  // using older versions of Bazaar due to the SSL pinning that did not contain the HK server
  // certificate. In order to not affect users with old versions of Bazaar a specialized route was
  // added to the HK server - "/proxy/*", which performs the proxying while all other routes still
  // perform the HTTP redirection. Bazaar should revert to using the default route once it will be
  // changed to perform proxying instead of redirection, which should happen when the adoption of
  // newer Bazaar revisions, that contain the HK server certificate, is high enough.
  @"hk-api.lightricks.com/proxy",
  @"frankfurt-api.lightricks.com",
  @"ireland-api.lightricks.com",
  @"tokyo-api.lightricks.com",
  @"sydney-api.lightricks.com"
];

/// Validatricks staging servers host names.
static NSArray<NSString *> * const kStagingValidatricksHostNames = @[
  @"oregon-api.stg.lightricks.com",
  @"frankfurt-api.stg.lightricks.com",
  @"ireland-api.stg.lightricks.com",
  @"tokyo-api.stg.lightricks.com",
  @"sydney-api.stg.lightricks.com"
];

- (instancetype)init {
  return [self initWithHostNames:kDefaultValidatricksHostNames delayedRetries:2
             initialBackoffDelay:0.25 immediateRetries:kDefaultValidatricksHostNames.count - 1];
}

- (instancetype)initWithHostNames:(NSArray<NSString *> *)hostNames
                   delayedRetries:(NSUInteger)delayedRetries
              initialBackoffDelay:(NSTimeInterval)initialBackoffDelay
                 immediateRetries:(NSUInteger)immediateRetries {
  auto sessionConfigurationProvider = [[BZRValidatricksSessionConfigurationProvider alloc] init];
  auto sessionConfiguration = [sessionConfigurationProvider HTTPSessionConfiguration];
  auto clients =
      [self clientsArrayFromHostNames:hostNames sessionConfiguration:sessionConfiguration];
  return [self initWithClients:clients
                delayedRetries:delayedRetries
           initialBackoffDelay:initialBackoffDelay
              immediateRetries:immediateRetries];
}

- (NSArray<id<BZRValidatricksClient>> *)
    clientsArrayFromHostNames:(NSArray<NSString *> *)hostNames
         sessionConfiguration:(FBRHTTPSessionConfiguration *)sessionConfiguration {
  return [hostNames lt_map:^id<BZRValidatricksClient>(NSString *hostName) {
    auto HTTPClient =
        [FBRHTTPClient clientWithSessionConfiguration:sessionConfiguration
                                              baseURL:[self serverURLFromHostName:hostName]];
    return [[BZRValidatricksClient alloc] initWithHTTPClient:HTTPClient];
  }];
}

- (NSURL *)serverURLFromHostName:(NSString *)hostName {
  return [NSURL URLWithString:
      [NSString stringWithFormat:@"https://%@/store/%@/", hostName, kLatestValidatorVersion]];
}

- (instancetype)initWithClients:(NSArray<id<BZRValidatricksClient>> *)clients
                 delayedRetries:(NSUInteger)delayedRetries
            initialBackoffDelay:(NSTimeInterval)initialBackoffDelay
               immediateRetries:(NSUInteger)immediateRetries {
  if (self = [super init]) {

#ifdef DEBUG
    auto useStagingTweakSignal =
        SHKTweakSignal(@"Validatricks", @"Validatricks Client", @"Use Staging endpoint", @NO);
    auto stagingClients =
        [self clientsArrayFromHostNames:kStagingValidatricksHostNames
                   sessionConfiguration:[self sessionConfigurationWithoutCertificates]];
    RAC(self, underlyingClients) = [RACSignal if:useStagingTweakSignal
                                            then:[RACSignal return:stagingClients]
                                            else:[RACSignal return:clients]];
#else
    _underlyingClients = clients;
#endif

    _delayedRetries = delayedRetries;
    _initialBackoffDelay = initialBackoffDelay;
    _immediateRetries = immediateRetries;
    _currentClientIndex = @0;
    _eventsSubject = [[RACSubject alloc] init];
  }
  return self;
}

- (FBRHTTPSessionConfiguration *)sessionConfigurationWithoutCertificates {
  auto defaultSessionConfigurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc] init];
  auto sessionWithoutPinningConfigurationProvider =
      [[BZRValidatricksSessionConfigurationProvider alloc]
       initWithAPIKey:defaultSessionConfigurationProvider.APIKey
       pinnedCertificates:nil];
  return [sessionWithoutPinningConfigurationProvider HTTPSessionConfiguration];
}

- (RACSignal<BZREvent *> *)eventsSignal {
  auto underlyingEventSignals = [self.underlyingClients
      lt_map:^RACSignal<BZREvent *> *(id<BZRValidatricksClient> client) {
        return client.eventsSignal;
      }];
  return [[RACSignal
      merge:[underlyingEventSignals arrayByAddingObject:self.eventsSubject]]
      takeUntil:self.rac_willDeallocSignal];
}

- (RACSignal<BZRReceiptValidationStatus *> *)validateReceipt:
    (BZRReceiptValidationParameters *)parameters {
  auto receiptValidationBlock = ^RACSignal *(id<BZRValidatricksClient> innerClient) {
    return [innerClient validateReceipt:parameters];
  };
  return [self performClientCallWithRetries:receiptValidationBlock];
}

- (RACSignal<BZRUserCreditStatus *> *)getCreditOfType:(NSString *)creditType
                                              forUser:(NSString *)userId
                                          environment:(BZRReceiptEnvironment *)environment {
  auto getCreditBlock = ^RACSignal *(id<BZRValidatricksClient> innerClient) {
    return [innerClient getCreditOfType:creditType forUser:userId environment:environment];
  };
  return [self performClientCallWithRetries:getCreditBlock];
}

- (RACSignal<BZRConsumableTypesPriceInfo *> *)getPricesInCreditType:(NSString *)creditType
    forConsumableTypes:(NSArray<NSString *> *)consumableTypes {
  auto getPricesBlock = ^RACSignal *(id<BZRValidatricksClient> innerClient) {
    return [innerClient getPricesInCreditType:creditType forConsumableTypes:consumableTypes];
  };
  return [self performClientCallWithRetries:getPricesBlock];
}

- (RACSignal<BZRRedeemConsumablesStatus *> *)
    redeemConsumableItems:(NSArray<BZRConsumableItemDescriptor *> *)consumableItems
    ofCreditType:(NSString *)creditType userId:(NSString *)userId
    environment:(BZRReceiptEnvironment *)environment {
  auto redeemBlock = ^RACSignal *(id<BZRValidatricksClient> innerClient) {
    return [innerClient redeemConsumableItems:consumableItems ofCreditType:creditType
                                       userId:userId environment:environment];
  };
  return [self performClientCallWithRetries:redeemBlock];
}

- (RACSignal *)performClientCallWithRetries:(BZRValidatricksClientCallBlock)clientCallBlock {
  __block NSNumber *lastUsedClientIndex;
  @weakify(self);
  auto clientCallSignal = [[RACSignal
      defer:^{
        @strongify(self);
        @synchronized (self.currentClientIndex) {
          lastUsedClientIndex = self.currentClientIndex;
          return clientCallBlock(self.currentClient);
        }
      }]
      doError:^(NSError *error) {
        @strongify(self);
        [self sendInternalClientErrorEvent:error];
        /// We wish to prevent two threads that both failed in the same time, from modifying the
        /// current client twice, so before replacing the current client, we first check that the
        /// client was not changed already.
        @synchronized (self.currentClientIndex) {
          if ([self.currentClientIndex isEqualToNumber:lastUsedClientIndex]) {
            [self advanceToNextClient];
          }
        }
      }];

  if (self.immediateRetries) {
    clientCallSignal = [clientCallSignal retry:self.immediateRetries];
  }

  if (self.delayedRetries) {
    clientCallSignal = [clientCallSignal bzr_delayedRetry:self.delayedRetries
                                             initialDelay:self.initialBackoffDelay];
  }
  return clientCallSignal;
}

- (id<BZRValidatricksClient>)currentClient {
  return self.underlyingClients[self.currentClientIndex.unsignedIntegerValue];
}

- (void)advanceToNextClient {
  self.currentClientIndex =
      @((self.currentClientIndex.unsignedIntegerValue + 1) % self.underlyingClients.count);
}

- (void)sendInternalClientErrorEvent:(NSError *)error {
  auto errorEvent =
      [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error];
  [self.eventsSubject sendNext:errorEvent];
}

@end

NS_ASSUME_NONNULL_END
