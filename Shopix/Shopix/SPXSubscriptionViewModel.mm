// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewModel.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRReceiptModel.h>
#import <LTKit/NSArray+Functional.h>

#import "SPXColorScheme.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionViewModel () <SPXSubscriptionManagerDelegate>

/// Identifiers of the subscription products.
@property (readonly, nonatomic) NSArray<NSString *> *productIdentifiers;

/// Manager used to handle products information fetching, subscription purchasing and restoration.
@property (readonly, nonatomic) SPXSubscriptionManager *subscriptionManager;

/// Subject that sends an alert view model when requested to show an alert to the user on success or
/// failure. The receiver should present an alert with the given \c id<SPXAlertViewModel> and invoke
/// the action block on each button press event.
@property (readwrite, nonatomic) RACSubject<id<SPXAlertViewModel>> *alertRequested;

/// Subject that sends value when requested to show a mail composer to the user. The \c value is
/// a \c LTVoidBlock that should called when the mail composer is dismissed.
@property (readwrite, nonatomic) RACSubject<LTVoidBlock> *feedbackComposerRequested;

/// \c YES if the activity indicator is visible, \c NO otherwise.
@property (nonatomic) BOOL shouldShowActivityIndicator;

@end

@implementation SPXSubscriptionViewModel

@synthesize subscriptionDescriptors = _subscriptionDescriptors;
@synthesize preferredProductIndex = _preferredProductIndex;
@synthesize pageViewModels = _pageViewModels;
@synthesize termsViewModel = _termsViewModel;
@synthesize colorScheme = _colorScheme;
@synthesize alertRequested = _alertRequested;
@synthesize dismissRequested = _dismissRequested;
@synthesize feedbackComposerRequested = _feedbackComposerRequested;

- (instancetype)initWithProducts:(NSArray<NSString *> *)productIdentifiers
           preferredProductIndex:(nullable NSNumber *)preferredProductIndex
                  pageViewModels:(NSArray<id<SPXSubscriptionVideoPageViewModel>> *)pageViewModels
                  termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel
                     colorScheme:(SPXColorScheme *)colorScheme
             subscriptionManager:(SPXSubscriptionManager *)subscriptionManager {
  LTParameterAssert(preferredProductIndex.unsignedIntegerValue < productIdentifiers.count,
                    @"Highlighted button index (%lu) must be lower than the number of buttons "
                    "(%lu)", (unsigned long)preferredProductIndex.unsignedIntegerValue,
                    (unsigned long)productIdentifiers.count);
  if (self = [super init]) {
    _productIdentifiers = [productIdentifiers copy];
    _subscriptionDescriptors = [productIdentifiers
        lt_map:^SPXSubscriptionDescriptor *(NSString *productIdentifier) {
          return [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:productIdentifier];
        }];
    _preferredProductIndex = preferredProductIndex;
    _pageViewModels = [pageViewModels copy];
    _termsViewModel = termsViewModel;
    _colorScheme = colorScheme;
    _subscriptionManager = subscriptionManager;
    _alertRequested = [RACSubject subject];
    _feedbackComposerRequested = [RACSubject subject];
    _dismissRequested = [[self rac_signalForSelector:@selector(requestDismiss)]
                         mapReplace:[RACUnit defaultUnit]];
    subscriptionManager.delegate = self;
  }
  return self;
}

- (instancetype)initWithProducts:(NSArray<NSString *> *)productIdentifiers
           preferredProductIndex:(nullable NSNumber *)preferredProductIndex
                  pageViewModels:(NSArray<id<SPXSubscriptionVideoPageViewModel>> *)pageViewModels
                  termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel {
  return [self initWithProducts:productIdentifiers preferredProductIndex:preferredProductIndex
                 pageViewModels:pageViewModels termsViewModel:termsViewModel
                    colorScheme:nn([JSObjection defaultInjector][[SPXColorScheme class]])
            subscriptionManager:[[SPXSubscriptionManager alloc] init]];
}

- (void)fetchProductsInfo {
  self.shouldShowActivityIndicator = YES;

  @weakify(self);
  [self.subscriptionManager fetchProductsInfo:[self.productIdentifiers lt_set]
                            completionHandler:^(NSDictionary<NSString *, BZRProduct *> *products,
                                                NSError * _Nullable error) {
    @strongify(self);
    if (error) {
      [self requestDismiss];
      return;
    }
    for (SPXSubscriptionDescriptor *subscriptionDescriptor in self.subscriptionDescriptors) {
      subscriptionDescriptor.priceInfo =
          products[subscriptionDescriptor.productIdentifier].priceInfo;
    }
    self.shouldShowActivityIndicator = NO;
  }];
}

- (void)subscriptionButtonPressed:(NSUInteger)buttonIndex {
  LTParameterAssert(buttonIndex < self.subscriptionDescriptors.count, @"Pressed button index (%lu) "
                    "is greater than the number of buttons (%lu)", (unsigned long)buttonIndex,
                    (unsigned long)self.subscriptionDescriptors.count);
  self.shouldShowActivityIndicator = YES;
  NSString *subscriptionIdentifier = self.subscriptionDescriptors[buttonIndex].productIdentifier;

  @weakify(self);
  [self.subscriptionManager purchaseSubscription:subscriptionIdentifier completionHandler:
   ^(BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo, NSError *) {
    @strongify(self);
    self.shouldShowActivityIndicator = NO;
    if (subscriptionInfo) {
      [self requestDismiss];
    }
  }];
}

- (void)restorePurchasesButtonPressed {
  self.shouldShowActivityIndicator = YES;
  @weakify(self);
  [self.subscriptionManager
   restorePurchasesWithCompletionHandler:^(BZRReceiptInfo * _Nullable receiptInfo, NSError *) {
    @strongify(self);
    self.shouldShowActivityIndicator = NO;
    if (receiptInfo.subscription && !receiptInfo.subscription.isExpired) {
      [self requestDismiss];
    }
  }];
}

- (void)requestDismiss {
  // This method is handled using rac_signalForSelector.
}

#pragma mark -
#pragma mark SPXSubscriptionManagerDelegate
#pragma mark -

- (void)presentAlertWithViewModel:(id<SPXAlertViewModel>)viewModel {
  [self.alertRequested sendNext:viewModel];
}

- (void)presentFeedbackMailComposerWithCompletionHandler:(LTVoidBlock)completionHandler {
  [self.feedbackComposerRequested sendNext:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
