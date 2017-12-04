// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionViewController.h"

#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsManager.h>
#import <LTKit/NSArray+Functional.h>
#import <MessageUI/MessageUI.h>

#import "MFMailComposeViewController+Dismissal.h"
#import "SPXAlertViewControllerProvider.h"
#import "SPXButtonsHorizontalLayoutView.h"
#import "SPXColorScheme.h"
#import "SPXFeedbackComposeViewControllerProvider.h"
#import "SPXPagingView.h"
#import "SPXRestorePurchasesButton.h"
#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionGradientButtonsFactory.h"
#import "SPXSubscriptionTermsView.h"
#import "SPXSubscriptionTermsViewModel.h"
#import "SPXSubscriptionVideoPageView.h"
#import "SPXSubscriptionVideoPageViewModel.h"
#import "SPXSubscriptionViewModel.h"
#import "UIAlertController+ViewModel.h"
#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

#pragma mark -
#pragma mark SPXSubscriptionViewController
#pragma mark -

@interface SPXSubscriptionViewController () <MFMailComposeViewControllerDelegate>

/// View configuration.
@property (readonly, nonatomic) id<SPXSubscriptionViewModel> viewModel;

/// Provider used for creating success and failure alerts when requested.
@property (readonly, nonatomic) id<SPXAlertViewControllerProvider> alertControllerProvider;

/// Provider used for creating the feedback view controller when requested.
@property (readonly, nonatomic) id<SPXFeedbackComposeViewControllerProvider> mailComposerProvider;

/// Provider used for creating the subscription buttons.
@property (readonly, nonatomic) id<SPXSubscriptionButtonsFactory> subscriptionButtonsFactory;

/// View that lets the user paginate horizontally between the given pages.
@property (readonly, nonatomic) SPXPagingView *pagingView;

/// View contains horizontally aligned buttons, where one of the buttons can be enlarged.
@property (readonly, nonatomic) SPXButtonsHorizontalLayoutView *subscriptionButtonsView;

/// Button allows the user restore previous subscription.
@property (readonly, nonatomic) SPXRestorePurchasesButton *restorePurchasesButton;

/// View for subscription terms of use text and documents links.
@property (readonly, nonatomic) SPXSubscriptionTermsView *termsView;

/// View used to disable the UI when a task is in progress.
@property (readonly, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation SPXSubscriptionViewController

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
    mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider {
  auto defaultButtonsFactory = [[SPXSubscriptionGradientButtonsFactory alloc]
                                initWithColorScheme:viewModel.colorScheme];
  return [self initWithViewModel:viewModel
         alertControllerProvider:[[SPXAlertViewControllerProvider alloc] init]
            mailComposerProvider:mailComposerProvider
     subscriptionButtonsProvider:defaultButtonsFactory];
}

- (instancetype)initWithViewModel:(id<SPXSubscriptionViewModel>)viewModel
          alertControllerProvider:(id<SPXAlertViewControllerProvider>)alertControllerProvider
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
      subscriptionButtonsProvider:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _viewModel = viewModel;
    _alertControllerProvider = alertControllerProvider;
    _mailComposerProvider = mailComposerProvider;
    _subscriptionButtonsFactory = subscriptionButtonsFactory;
  }
  return self;
}

#pragma mark -
#pragma mark View Lifecycle
#pragma mark -

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = self.viewModel.colorScheme.backgroundColor;
  [self setupSubviews];
  [self setupBindings];
  [self.viewModel fetchProductsInfo];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  if (self.view.frame.size.width < self.view.frame.size.height) {
    self.pagingView.pageViewWidthRatio = 0.84;
  } else {
    self.pagingView.pageViewWidthRatio = 0.42;
  }
}

#pragma mark -
#pragma mark Subviews Setup
#pragma mark -

- (void)setupSubviews {
  [self setupBackgroundView];
  [self setupPageingView];
  [self setupButtons];
  [self setupRestorePurchasesButton];
  [self setupTerms];
  [self setupActivityIndicator];
}

- (void)setupBackgroundView {
  if (!self.backgroundView) {
    return;
  }

  [self.view insertSubview:self.backgroundView atIndex:0];
  [self.backgroundView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (void)setupPageingView {
  _pagingView = [[SPXPagingView alloc] init];
  [self.view addSubview:self.pagingView];

  [self.pagingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self.view);
    make.height.equalTo(self.view).multipliedBy(0.58).priorityHigh();
  }];
  self.pagingView.pageViews = [self createPageViews];
}

- (NSArray<UIView *> *)createPageViews {
  return [self.viewModel.pageViewModels
          lt_map:^UIView *(id<SPXSubscriptionVideoPageViewModel> pageViewModel) {
    auto pageView = [[SPXSubscriptionVideoPageView alloc] init];
    pageView.videoURL = pageViewModel.videoURL;
    pageView.title = pageViewModel.title;
    pageView.subtitle = pageViewModel.subtitle;

    return pageView;
  }];
}

- (void)setupButtons {
  auto topPaddingView = [self addPaddingSubviewBeneathView:self.pagingView heightRatio:0.03
                                                 maxHeight:120];

  _subscriptionButtonsView = [[SPXButtonsHorizontalLayoutView alloc] init];
  [self.view addSubview:self.subscriptionButtonsView];

  [self.subscriptionButtonsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.view);
    make.top.equalTo(topPaddingView.mas_bottom);
    make.height.equalTo(self.view).multipliedBy(0.197).priorityHigh();
    make.height.mas_lessThanOrEqualTo(167);
    make.height.mas_lessThanOrEqualTo(self.view.mas_width).multipliedBy(0.32);
  }];

  self.subscriptionButtonsView.buttons = [self.viewModel.subscriptionDescriptors
      lt_map:^UIButton *(SPXSubscriptionDescriptor *subscriptionDescriptor) {
        return [self.subscriptionButtonsFactory
                createSubscriptionButtonWithSubscriptionDescriptor:subscriptionDescriptor];
      }];

  self.subscriptionButtonsView.enlargedButtonIndex = self.viewModel.preferredProductIndex;
}

- (void)setupRestorePurchasesButton {
  auto topPaddingView = [self addPaddingSubviewBeneathView:self.subscriptionButtonsView
                                               heightRatio:0.01 maxHeight:20];

  _restorePurchasesButton = [[SPXRestorePurchasesButton alloc] init];
  self.restorePurchasesButton.textColor = self.viewModel.colorScheme.textColor;

  [self.view addSubview:self.restorePurchasesButton];
  [self.restorePurchasesButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(topPaddingView.mas_bottom);
    make.centerX.equalTo(self.view);
  }];
}

- (void)setupTerms {
  _termsView = [[SPXSubscriptionTermsView alloc]
                initWithTermsText:self.viewModel.termsViewModel.termsText
                termsOfUseLink:self.viewModel.termsViewModel.termsOfUseLink
                privacyPolicyLink:self.viewModel.termsViewModel.privacyPolicyLink];
  [self.view addSubview:self.termsView];

  [self.termsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.view);
    make.bottom.equalTo(self.view).offset(-5);
    make.width.equalTo(self.view).multipliedBy(0.94);
  }];
}

- (void)setupActivityIndicator {
  _activityIndicatorView = [[UIActivityIndicatorView alloc]
                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  self.activityIndicatorView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
  self.activityIndicatorView.hidesWhenStopped = YES;
  [self.view addSubview:self.activityIndicatorView];

  [self.activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (UIView *)addPaddingSubviewBeneathView:(UIView *)view heightRatio:(CGFloat)heightRatio
                               maxHeight:(NSUInteger)maxHeight {
  auto paddingView = [[UIView alloc] init];
  paddingView.hidden = YES;
  [self.view addSubview:paddingView];

  [paddingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.view);
    make.top.equalTo(view.mas_bottom);
    make.height.equalTo(self.view).multipliedBy(heightRatio).priorityHigh();
    make.height.mas_lessThanOrEqualTo(maxHeight);
  }];

  return paddingView;
}

#pragma mark -
#pragma mark Bindings Setup
#pragma mark -

- (void)setupBindings {
  [self setupSubscriptionButtonsBindings];
  [self setupRestorePurchasesButtonPressedBinding];
  [self setupActivityIndicatorBinding];
  [self setupAlertRequestBinding];
  [self setupFeedbackComposerRequestBinding];
}

- (void)setupSubscriptionButtonsBindings {
  @weakify(self);
  [self.subscriptionButtonsView.buttonPressed subscribeNext:^(NSNumber *index) {
    @strongify(self);
    [self.viewModel subscriptionButtonPressed:index.unsignedIntegerValue];
  }];
}

- (void)setupRestorePurchasesButtonPressedBinding {
  @weakify(self);
  [[self.restorePurchasesButton rac_signalForControlEvents:UIControlEventTouchUpInside]
   subscribeNext:^(UIControl *) {
     @strongify(self);
     [self.viewModel restorePurchasesButtonPressed];
   }];
}

- (void)setupActivityIndicatorBinding {
  @weakify(self);
  [RACObserve(self, viewModel.shouldShowActivityIndicator) subscribeNext:^(NSNumber *active) {
    @strongify(self);
    active.boolValue ?
        [self.activityIndicatorView startAnimating] : [self.activityIndicatorView stopAnimating];
  }];
}

- (void)setupAlertRequestBinding {
  @weakify(self);
  [self.viewModel.alertRequested subscribeNext:^(id<SPXAlertViewModel> alertViewModel) {
    @strongify(self);
    auto alert = [UIAlertController spx_alertControllerWithViewModel:alertViewModel];
    [self presentViewController:alert animated:YES completion:nil];
  }];
}

- (void)setupFeedbackComposerRequestBinding {
  @weakify(self);
  [self.viewModel.feedbackComposerRequested subscribeNext:^(LTVoidBlock completionHandler) {
    @strongify(self);
    auto _Nullable mailComposer = [self.mailComposerProvider feedbackComposeViewController];

    if (mailComposer) {
      mailComposer.mailComposeDelegate = self;
      mailComposer.spx_dismissBlock = completionHandler;
      [self presentViewController:mailComposer animated:YES completion:nil];
    } else {
      completionHandler();
    }
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setBackgroundView:(nullable UIView *)backgroundView {
  if (_backgroundView && self.isViewLoaded) {
    [_backgroundView removeFromSuperview];
  }

  _backgroundView = backgroundView;

  if (backgroundView && self.isViewLoaded) {
    [self setupBackgroundView];
  }
}

- (RACSignal<RACUnit *> *)dismissRequested {
  return self.viewModel.dismissRequested;
}

#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate
#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult __unused)result
                        error:(NSError * _Nullable __unused)error {
  [controller dismissViewControllerAnimated:YES completion:^{
    controller.spx_dismissBlock();
  }];
}

@end

NS_ASSUME_NONNULL_END
