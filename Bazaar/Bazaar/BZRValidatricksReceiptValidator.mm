// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidator.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPClientProvider.h>
#import <Fiber/RACSignal+Fiber.h>

#import "BZREvent+AdditionalInfo.h"
#import "BZRMultiHostValidatricksClientProvider.h"
#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRReceiptValidationStatus.h"
#import "NSErrorCodes+Bazaar.h"
#import "RACSignal+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatricksReceiptValidator ()

/// Provider used to provide HTTP clients.
@property (readonly, nonatomic) id<FBRHTTPClientProvider> clientProvider;

/// HTTP client used to send validation requests to Validatricks server.
@property (strong, nonatomic, nullable) FBRHTTPClient *client;

/// The other end of \c eventsSignal;
@property (readonly, nonatomic) RACSubject<BZREvent *> *eventsSubject;

@end

@implementation BZRValidatricksReceiptValidator

/// Receipt validation endpoint of the Validatricks server.
static NSString * const kReceiptValidationEndpoint = @"validateReceipt";

+ (NSString *)receiptValidationEndpoint {
  return kReceiptValidationEndpoint;
}

- (instancetype)init {
  return [self initWithHTTPClientProvider:[[BZRMultiHostValidatricksClientProvider alloc] init]];
}

- (instancetype)initWithHTTPClientProvider:(id<FBRHTTPClientProvider>)clientProvider {
  if (self = [super init]) {
    _clientProvider = clientProvider;
    _eventsSubject = [RACSubject subject];
  }
  return self;
}

#pragma mark -
#pragma mark BZRReceiptValidator
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)
    validateReceiptWithParameters:(BZRReceiptValidationParameters *)parameters {
  @synchronized (self) {
    if (!self.client) {
      self.client =  [self.clientProvider HTTPClient];
    }

    @weakify(self);
    FBRHTTPRequestParameters *requestParameters = parameters.validatricksRequestParameters;
    return [[[[[self.client
        POST:kReceiptValidationEndpoint withParameters:requestParameters headers:nil]
        fbr_deserializeJSON]
        bzr_deserializeModel:[BZRReceiptValidationStatus class]]
        doError:^(NSError *) {
          @strongify(self);
          @synchronized (self) {
            self.client = nil;
          }
        }]
        doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
          @strongify(self);
          [self.eventsSubject sendNext:
           [BZREvent receiptValidationStatusReceivedEvent:receiptValidationStatus
                                                requestId:receiptValidationStatus.requestId]];
        }];
  }
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return [self.eventsSubject takeUntil:[self rac_willDeallocSignal]];
}

@end

NS_ASSUME_NONNULL_END
