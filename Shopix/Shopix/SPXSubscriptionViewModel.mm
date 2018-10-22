// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewModel.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRReceiptModel.h>
#import <LTKit/LTTimer.h>
#import <LTKit/NSArray+Functional.h>

#import "SPXColorScheme.h"
#import "SPXPurchaseSubscriptionEvent.h"
#import "SPXRestorePurchasesButtonPressedEvent.h"
#import "SPXRestorePurchasesEvent.h"
#import "SPXSubscriptionButtonPressedEvent.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionManager.h"
#import "SPXSubscriptionTermsViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionViewModel () <SPXSubscriptionManagerDelegate>

/// Manager used to handle products information fetching, subscription purchasing and restoration.
@property (readonly, nonatomic) SPXSubscriptionManager *subscriptionManager;

/// Signal that sends a page index that the view should scroll to.
@property (readonly, nonatomic) RACSubject<NSNumber *> *pagingViewScrollRequestedSubject;

/// Subject that sends an alert view model when requested to show an alert to the user on success or
/// failure. The receiver should present an alert with the given \c id<SPXAlertViewModel> and invoke
/// the action block on each button press event.
@property (readonly, nonatomic) RACSubject<id<SPXAlertViewModel>> *alertRequestedSubject;

/// Subject that sends value when requested to show a mail composer to the user. The \c value is
/// a \c LTVoidBlock that should called when the mail composer is dismissed.
@property (readonly, nonatomic) RACSubject<LTVoidBlock> *feedbackComposerRequestedSubject;

/// \c YES if the activity indicator is visible, \c NO otherwise.
@property (nonatomic) BOOL shouldShowActivityIndicator;

/// Page index that is currently active.
@property (nonatomic) NSUInteger activePageIndex;

/// Subject used to send events with.
@property (readonly, nonatomic) RACSubject<LTValueObject *> *eventsSubject;

@end

@implementation SPXSubscriptionViewModel

@synthesize subscriptionDescriptors = _subscriptionDescriptors;
@synthesize preferredProductIndex = _preferredProductIndex;
@synthesize pageViewModels = _pageViewModels;
@synthesize termsViewModel = _termsViewModel;
@synthesize colorScheme = _colorScheme;
@synthesize pagingViewScrollRequested = _pagingViewScrollRequested;
@synthesize alertRequested = _alertRequested;
@synthesize dismissRequested = _dismissRequested;
@synthesize feedbackComposerRequested = _feedbackComposerRequested;
@synthesize events = _events;

- (instancetype)
    initWithSubscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
              preferredProductIndex:(nullable NSNumber *)preferredProductIndex
                     pageViewModels:(NSArray<id<SPXSubscriptionVideoPageViewModel>> *)pageViewModels
                     termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel {
  SPXColorScheme *colorScheme = nn([JSObjection defaultInjector][[SPXColorScheme class]]);
  return [self initWithSubscriptionDescriptors:subscriptionDescriptors
                         preferredProductIndex:preferredProductIndex
                                pageViewModels:pageViewModels
                                termsViewModel:termsViewModel
                                   colorScheme:colorScheme
                           subscriptionManager:[[SPXSubscriptionManager alloc] init]];
}

- (instancetype)
    initWithSubscriptionDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors
              preferredProductIndex:(nullable NSNumber *)preferredProductIndex
                     pageViewModels:(NSArray<id<SPXSubscriptionVideoPageViewModel>> *)pageViewModels
                     termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel
                        colorScheme:(SPXColorScheme *)colorScheme
                subscriptionManager:(SPXSubscriptionManager *)subscriptionManager {
  LTParameterAssert(preferredProductIndex.unsignedIntegerValue < subscriptionDescriptors.count,
                    @"Highlighted button index (%lu) must be lower than the number of buttons "
                    "(%lu)", (unsigned long)preferredProductIndex.unsignedIntegerValue,
                    (unsigned long)subscriptionDescriptors.count);
  if (self = [super init]) {
    _subscriptionDescriptors = [subscriptionDescriptors copy];
    _preferredProductIndex = preferredProductIndex;
    _pageViewModels = [pageViewModels copy];
    _termsViewModel = termsViewModel;
    _colorScheme = colorScheme;
    _subscriptionManager = subscriptionManager;
    _pagingViewScrollRequestedSubject = [RACSubject subject];
    _pagingViewScrollRequested = [self.pagingViewScrollRequestedSubject
                                  takeUntil:[self rac_willDeallocSignal]];
    _alertRequestedSubject = [RACSubject subject];
    _alertRequested = [self.alertRequestedSubject takeUntil:[self rac_willDeallocSignal]];
    _feedbackComposerRequestedSubject = [RACSubject subject];
    _feedbackComposerRequested = [self.feedbackComposerRequestedSubject
                                  takeUntil:[self rac_willDeallocSignal]];
    _eventsSubject = [RACSubject subject];
    _events = self.eventsSubject;
    _dismissRequested = [[self rac_signalForSelector:@selector(requestDismiss)]
                         mapReplace:[RACUnit defaultUnit]];
    subscriptionManager.delegate = self;
  }
  return self;
}

- (void)fetchProductsInfo {
  self.shouldShowActivityIndicator = YES;

  @weakify(self);
  auto fetchCompletionHandler =
      ^(NSDictionary<NSString *, BZRProduct *> * _Nullable products, NSError * _Nullable error) {
        @strongify(self);
        if (error) {
          [self requestDismiss];
          return;
        }
        for (SPXSubscriptionDescriptor *subscriptionDescriptor in self.subscriptionDescriptors) {
          auto subscriptionProduct = products[subscriptionDescriptor.productIdentifier];
          subscriptionDescriptor.priceInfo = subscriptionProduct.priceInfo;
          subscriptionDescriptor.introductoryDiscount =
              [self getDiscountOnProductIfEligible:subscriptionProduct];
        }
        self.shouldShowActivityIndicator = NO;
      };

  auto requestedProductIdentifiers = [self.subscriptionDescriptors
      lt_map:^NSString *(SPXSubscriptionDescriptor *descriptor) {
        return descriptor.productIdentifier;
      }].lt_set;
  [self.subscriptionManager fetchProductsInfo:requestedProductIdentifiers
                            completionHandler:fetchCompletionHandler];
}

- (nullable BZRSubscriptionIntroductoryDiscount *)
    getDiscountOnProductIfEligible:(BZRProduct *)product {
  if ([self.subscriptionManager eligibleForIntroductoryDiscountOnSubscription:product]) {
    return product.introductoryDiscount;
  }
  return nil;
}

- (void)subscriptionButtonPressed:(NSUInteger)buttonIndex {
  LTParameterAssert(buttonIndex < self.subscriptionDescriptors.count, @"Pressed button index (%lu) "
                    "is greater than the number of buttons (%lu)", (unsigned long)buttonIndex,
                    (unsigned long)self.subscriptionDescriptors.count);
  self.shouldShowActivityIndicator = YES;

  SPXSubscriptionDescriptor *descriptor = self.subscriptionDescriptors[buttonIndex];
  [self.eventsSubject sendNext:[[SPXSubscriptionButtonPressedEvent alloc]
                                initWithSubscriptionDescriptor:descriptor]];

  auto timer = [[LTTimer alloc] init];
  [timer start];

  auto eventsSubject = self.eventsSubject;
  @weakify(self);
  [self.subscriptionManager purchaseSubscription:descriptor.productIdentifier completionHandler:
   ^(BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo, NSError * _Nullable error) {
     @strongify(self);
     self.shouldShowActivityIndicator = NO;

     [eventsSubject sendNext:[[SPXPurchaseSubscriptionEvent alloc]
                              initWithSubscriptionDescriptor:descriptor
                              successfulPurchase:error == nil receiptInfo:subscriptionInfo
                              purchaseDuration:[timer stop] error:error]];

     if (subscriptionInfo) {
       [self requestDismiss];
     }
  }];
}

- (void)restorePurchasesButtonPressed {
  self.shouldShowActivityIndicator = YES;

  [self.eventsSubject sendNext:[[SPXRestorePurchasesButtonPressedEvent alloc] init]];

  auto timer = [[LTTimer alloc] init];
  [timer start];

  auto eventsSubject = self.eventsSubject;
  @weakify(self);
  [self.subscriptionManager
   restorePurchasesWithCompletionHandler:^(BZRReceiptInfo * _Nullable receiptInfo,
                                           NSError * _Nullable error) {
    @strongify(self);
     self.shouldShowActivityIndicator = NO;

     [eventsSubject sendNext:[[SPXRestorePurchasesEvent alloc]
                              initWithSuccessfulRestore:error == nil receiptInfo:receiptInfo
                              restoreDuration:[timer stop] error:error]];

     if (receiptInfo.subscription && !receiptInfo.subscription.isExpired) {
       [self requestDismiss];
     }
  }];
}

- (void)activePageDidFinishVideoPlayback {
  auto nextPageIndex = self.activePageIndex < self.pageViewModels.count - 1 ?
      self.activePageIndex + 1 : 0;
  [self.pagingViewScrollRequestedSubject sendNext:@(nextPageIndex)];
}

- (void)pagingViewScrolledToPosition:(CGFloat)position {
  self.activePageIndex = std::round(std::clamp(position, 0., self.pageViewModels.count - 1.));
}

- (void)requestDismiss {
  // This method is handled using rac_signalForSelector.
}

#pragma mark -
#pragma mark SPXSubscriptionManagerDelegate
#pragma mark -

- (void)presentAlertWithViewModel:(id<SPXAlertViewModel>)viewModel {
  [self.alertRequestedSubject sendNext:viewModel];
}

- (void)presentFeedbackMailComposerWithCompletionHandler:(LTVoidBlock)completionHandler {
  [self.feedbackComposerRequestedSubject sendNext:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
