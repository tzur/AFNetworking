// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXMultiSubscriptionViewModel.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRReceiptModel.h>
#import <LTKit/LTTimer.h>
#import <LTKit/NSArray+Functional.h>

#import "SPXAlertViewModel+ShopixPresets.h"
#import "SPXColorScheme.h"
#import "SPXPurchaseSubscriptionEvent.h"
#import "SPXRestorePurchasesButtonPressedEvent.h"
#import "SPXRestorePurchasesEvent.h"
#import "SPXSubscriptionButtonPressedEvent.h"
#import "SPXSubscriptionButtonsPageViewModel.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionManager.h"
#import "SPXSubscriptionTermsViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXMultiSubscriptionViewModel () <SPXSubscriptionManagerDelegate>

/// Manager used to handle products information fetching, subscription purchasing and restoration.
@property (readonly, nonatomic) SPXSubscriptionManager *subscriptionManager;

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

@implementation SPXMultiSubscriptionViewModel

@synthesize pageViewModels = _pageViewModels;
@synthesize activePageIndex = _activePageIndex;
@synthesize termsViewModel = _termsViewModel;
@synthesize colorScheme = _colorScheme;
@synthesize alertRequested = _alertRequested;
@synthesize dismissRequested = _dismissRequested;
@synthesize feedbackComposerRequested = _feedbackComposerRequested;
@synthesize events = _events;

- (instancetype)initWithPages:(NSArray<id<SPXSubscriptionButtonsPageViewModel>> *)pageViewModels
             initialPageIndex:(NSUInteger)initialPageIndex
               termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel {
  return [self initWithPages:pageViewModels initialPageIndex:initialPageIndex
              termsViewModel:termsViewModel
                 colorScheme:nn([JSObjection defaultInjector][[SPXColorScheme class]])
         subscriptionManager:[[SPXSubscriptionManager alloc] init]];
}

- (instancetype)initWithPages:(NSArray<id<SPXSubscriptionButtonsPageViewModel>> *)pageViewModels
             initialPageIndex:(NSUInteger)initialPageIndex
               termsViewModel:(id<SPXSubscriptionTermsViewModel>)termsViewModel
                  colorScheme:(SPXColorScheme *)colorScheme
          subscriptionManager:(SPXSubscriptionManager *)subscriptionManager {
  LTParameterAssert(initialPageIndex < pageViewModels.count,
                    @"Initial page index (%lu) must be lower than the number of pages "
                    "(%lu)", (unsigned long)initialPageIndex,
                    (unsigned long)pageViewModels.count);

  if (self = [super init]) {
    _pageViewModels = [pageViewModels copy];
    _activePageIndex = initialPageIndex;
    _termsViewModel = termsViewModel;
    _colorScheme = colorScheme;
    _subscriptionManager = subscriptionManager;
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

- (void)viewDidSetup {
  [self fetchProductsInfo];
  [self pageViewBecameActive:self.activePageIndex];
}

- (void)pageViewBecameActive:(NSUInteger)pageViewModelIndex {
  [self.pageViewModels[pageViewModelIndex] playVideo];
}

- (void)fetchProductsInfo {
  self.shouldShowActivityIndicator = YES;

  @weakify(self);
  [self.subscriptionManager fetchProductsInfo:[self allPagesProductIdentifiers].lt_set
                            completionHandler:^(NSDictionary<NSString *, BZRProduct *> *products,
                                                NSError * _Nullable error) {
      @strongify(self);
      if (error) {
        [self requestDismiss];
        return;
      }

      for (id<SPXSubscriptionButtonsPageViewModel> page in self.pageViewModels) {
        for (SPXSubscriptionDescriptor *subscriptionDescriptor in page.subscriptionDescriptors) {
          subscriptionDescriptor.priceInfo =
              products[subscriptionDescriptor.productIdentifier].priceInfo;
        }
      }

      self.shouldShowActivityIndicator = NO;
    }];
}

- (NSArray<NSString *> *)allPagesProductIdentifiers {
  return [self.pageViewModels
      lt_reduce:^NSArray<NSString *> *(NSArray<NSString *> *productsUntilNow,
                                       id<SPXSubscriptionButtonsPageViewModel> pageViewModel) {
        auto productIdentifiers = [pageViewModel.subscriptionDescriptors
                                   lt_map:^NSString *(SPXSubscriptionDescriptor *descriptor) {
                                     return descriptor.productIdentifier;
                                   }];
        return [productsUntilNow arrayByAddingObjectsFromArray:productIdentifiers];
      }
      initial:@[]];
}

- (void)subscriptionButtonPressed:(NSUInteger)buttonIndex atPageIndex:(NSUInteger)pageIndex {
  LTParameterAssert(buttonIndex < self.pageViewModels[pageIndex].subscriptionDescriptors.count,
                    @"Pressed button index (%lu) in page number (%lu) "
                    "is greater than the number of buttons (%lu)", (unsigned long)buttonIndex,
                    (unsigned long)pageIndex,
                    (unsigned long)self.pageViewModels[pageIndex].subscriptionDescriptors.count);

  self.shouldShowActivityIndicator = YES;

  auto buttonDescriptor = self.pageViewModels[pageIndex].subscriptionDescriptors[buttonIndex];
  [self.eventsSubject sendNext:[[SPXSubscriptionButtonPressedEvent alloc]
                                initWithSubscriptionDescriptor:buttonDescriptor]];

  auto timer = [[LTTimer alloc] init];
  [timer start];

  auto eventsSubject = self.eventsSubject;
  @weakify(self);
  [self.subscriptionManager purchaseSubscription:buttonDescriptor.productIdentifier
      completionHandler:^(BZRReceiptSubscriptionInfo * _Nullable subscriptionInfo,
                          NSError * _Nullable error) {
     @strongify(self);
     self.shouldShowActivityIndicator = NO;

     [eventsSubject sendNext:[[SPXPurchaseSubscriptionEvent alloc]
                              initWithSubscriptionDescriptor:buttonDescriptor
                              successfulPurchase:error == nil
                              receiptInfo:subscriptionInfo
                              purchaseDuration:[timer stop]
                              error:error]];

     if (subscriptionInfo) {
       if (!self.subscriptionManager.userID) {
         [self sendNoICloudAccountAlertRequest];
       } else {
         [self requestDismiss];
       }
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
       if (!self.subscriptionManager.userID) {
         [self sendNoICloudAccountAlertRequest];
       } else {
         [self requestDismiss];
       }
     }
   }];
}

- (void)sendNoICloudAccountAlertRequest {
  id<SPXAlertViewModel> iCloudAlertViewModel =
      [SPXAlertViewModel noICloudAccountAlertWithSettingsAction:^{
        [self requestDismiss];
      } cancelAction:^{
        [self requestDismiss];
      }];
  [self.alertRequestedSubject sendNext:iCloudAlertViewModel];
}

- (void)scrolledToPosition:(CGFloat)position {
  NSUInteger newPageIndex = std::round(std::clamp(position, 0., self.pageViewModels.count - 1.));

  if (self.activePageIndex != newPageIndex) {
    [self.pageViewModels[self.activePageIndex] stopVideo];
    [self pageViewBecameActive:newPageIndex];
    self.activePageIndex = newPageIndex;
  }
}

- (void)dismissButtonPressed {
  [self requestDismiss];
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
