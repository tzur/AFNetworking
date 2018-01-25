// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXMultiSubscriptionViewController.h"

#import <LTKit/NSArray+Functional.h>
#import <LTKit/UIColor+Utilities.h>
#import <MessageUI/MessageUI.h>
#import <Wireframes/UIButton+ViewModel.h>
#import <Wireframes/UIView+MASSafeArea.h>
#import <Wireframes/WFGradientView.h>
#import <Wireframes/WFImageViewModelBuilder.h>
#import <Wireframes/WFVideoView.h>

#import "MFMailComposeViewController+Dismissal.h"
#import "SPXAlertViewControllerProvider.h"
#import "SPXButtonsHorizontalLayoutView.h"
#import "SPXColorScheme.h"
#import "SPXFeedbackComposeViewControllerProvider.h"
#import "SPXMultiSubscriptionGradientButtonsFactory.h"
#import "SPXMultiSubscriptionViewModel.h"
#import "SPXPagingView.h"
#import "SPXRestorePurchasesButton.h"
#import "SPXSubscriptionButtonFormatter.h"
#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionButtonsPageView.h"
#import "SPXSubscriptionButtonsPageView+ViewModel.h"
#import "SPXSubscriptionTermsView.h"
#import "SPXSubscriptionTermsViewModel.h"
#import "UIAlertController+ViewModel.h"
#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXMultiSubscriptionViewController
#pragma mark -

@interface SPXMultiSubscriptionViewController () <MFMailComposeViewControllerDelegate>

/// View configuration.
@property (readonly, nonatomic) id<SPXMultiSubscriptionViewModel> viewModel;

/// Provider used for creating success and failure alerts when requested.
@property (readonly, nonatomic) id<SPXAlertViewControllerProvider> alertControllerProvider;

/// Provider used for creating the feedback view controller when requested.
@property (readonly, nonatomic) id<SPXFeedbackComposeViewControllerProvider> mailComposerProvider;

/// Provider used for creating the subscription buttons.
@property (readonly, nonatomic) id<SPXSubscriptionButtonsFactory> subscriptionButtonsFactory;

/// Scroll view used to scroll vertically the view's content.
@property (readonly, nonatomic) UIScrollView *scrollView;

/// Flexible view used to hold all the the scroll view subviews.
@property (readonly, nonatomic) UIView *contentView;

/// View that lets the user paginate horizontally between the given pages.
@property (readonly, nonatomic) SPXPagingView *pagingView;

/// View that displays a horizontal series of dots, each of which corresponds to one of the page
/// views. The dot of the currently active page will be highlighted.
@property (readonly, nonatomic) UIPageControl *pageControl;

/// View used to fill the empty space between the page control and the restore button.
@property (readonly, nonatomic) UIView *pageControlBottomPaddingView;

/// Button allows the user restore previous subscription.
@property (readonly, nonatomic) SPXRestorePurchasesButton *restorePurchasesButton;

/// View for subscription terms of use text and documents links.
@property (readonly, nonatomic) SPXSubscriptionTermsView *termsView;

/// View used to disable the UI when a task is in progress.
@property (readonly, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end

@implementation SPXMultiSubscriptionViewController

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithViewModel:(id<SPXMultiSubscriptionViewModel>)viewModel
    mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider {
  auto alertViewControllerProvider = [[SPXAlertViewControllerProvider alloc] init];
  auto buttonFormatter =
      [[SPXSubscriptionButtonFormatter alloc] initColorScheme:viewModel.colorScheme
       showNonMonthlyFootnoteMarker:viewModel.showNonMonthlyBillingFootnote];
  auto defaultButtonsFactory =
      [[SPXMultiSubscriptionGradientButtonsFactory alloc] initWithColorScheme:viewModel.colorScheme
                                                                    formatter:buttonFormatter];
  return [self initWithViewModel:viewModel
         alertControllerProvider:alertViewControllerProvider
            mailComposerProvider:mailComposerProvider
      subscriptionButtonsFactory:defaultButtonsFactory];
}

- (instancetype)initWithViewModel:(id<SPXMultiSubscriptionViewModel>)viewModel
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory {
  auto alertViewControllerProvider = [[SPXAlertViewControllerProvider alloc] init];
  return [self initWithViewModel:viewModel
         alertControllerProvider:alertViewControllerProvider
            mailComposerProvider:mailComposerProvider
      subscriptionButtonsFactory:subscriptionButtonsFactory];
}

- (instancetype)initWithViewModel:(id<SPXMultiSubscriptionViewModel>)viewModel
          alertControllerProvider:(id<SPXAlertViewControllerProvider>)alertControllerProvider
             mailComposerProvider:(id<SPXFeedbackComposeViewControllerProvider>)mailComposerProvider
       subscriptionButtonsFactory:(id<SPXSubscriptionButtonsFactory>)subscriptionButtonsFactory {
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
  [self.viewModel viewDidSetup];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.scrollView.contentSize = self.contentView.frame.size;
}

- (void)viewWillTransitionToSize:(CGSize __unused)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  auto activePageIndex = self.viewModel.activePageIndex;
  [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>) {
    [self.pagingView scrollToPage:activePageIndex animated:NO];
  } completion:nil];
}

#pragma mark -
#pragma mark Subviews Setup
#pragma mark -

- (void)setupSubviews {
  [self setupScrollView];
  [self setupContentView];
  [self setupPageingView];
  [self setupPageControl];
  [self setupPageControlBottomPaddingView];
  [self setupRestorePurchasesButton];
  [self setupTerms];
  [self setupBottomGradient];
  [self setupActivityIndicator];
  [self setupDismissButton];
}

- (void)setupScrollView {
  _scrollView = [[UIScrollView alloc] init];
  self.scrollView.bounces = NO;
  if (@available(iOS 11.0, *)) {
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
  } else {
    self.automaticallyAdjustsScrollViewInsets = NO;
  }

  [self.view addSubview:self.scrollView];
  [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.top.equalTo(self.view);
    make.bottom.equalTo(self.view.wf_safeArea);
  }];
}

- (void)setupContentView {
  _contentView = [[UIView alloc] init];
  [self.scrollView addSubview:self.contentView];
  [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.width.centerX.equalTo(self.scrollView);
    make.height.greaterThanOrEqualTo(self.scrollView);
  }];
}

- (void)setupPageingView {
  _pagingView = [[SPXPagingView alloc] init];
  self.pagingView.pageViewWidthRatio = 1.0;
  self.pagingView.spacingRatio = 0;
  [self.contentView addSubview:self.pagingView];

  [self.pagingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.top.equalTo(self.contentView);
    make.height.equalTo(self.scrollView).multipliedBy(0.84);
  }];

  self.pagingView.pageViews = [self createPageViews];
}

- (NSArray<UIView *> *)createPageViews {
  return [self.viewModel.pageViewModels
          lt_map:^UIView *(id<SPXSubscriptionButtonsPageViewModel> pageViewModel) {
    return [self createPageViewWithPageViewModel:pageViewModel];
  }];
}

- (UIView *)createPageViewWithPageViewModel:(id<SPXSubscriptionButtonsPageViewModel>)pageViewModel {
  auto pageView = [SPXSubscriptionButtonsPageView
                   buttonsPageViewWithViewModel:pageViewModel
                   buttonsFactory:self.subscriptionButtonsFactory];

  auto pageViewIndex = [self.viewModel.pageViewModels indexOfObject:pageViewModel];
  @weakify(self);
  [pageView.buttonsContainer.buttonPressed subscribeNext:^(NSNumber *index) {
    @strongify(self);
    [self.viewModel subscriptionButtonPressed:index.unsignedIntegerValue atPageIndex:pageViewIndex];
  }];

  return pageView;
}

- (void)setupPageControl {
  _pageControl = [[UIPageControl alloc] init];
  self.pageControl.userInteractionEnabled = NO;
  self.pageControl.hidesForSinglePage = YES;
  self.pageControl.numberOfPages = self.viewModel.pageViewModels.count;
  [self.contentView addSubview:self.pageControl];

  [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.pagingView.mas_bottom).with.offset(7);
    make.centerX.equalTo(self.contentView);
    make.height.equalTo(@20);
  }];
}

- (void)setupPageControlBottomPaddingView {
  _pageControlBottomPaddingView = [[UIView alloc] init];
  self.pageControlBottomPaddingView.hidden = YES;
  [self.contentView addSubview:self.pageControlBottomPaddingView];

  [self.pageControlBottomPaddingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.pageControl.mas_bottom);
    make.width.centerX.equalTo(self.contentView);
    make.height.mas_greaterThanOrEqualTo(7);
  }];
}

- (void)setupRestorePurchasesButton {
  _restorePurchasesButton = [[SPXRestorePurchasesButton alloc] init];
  self.restorePurchasesButton.textColor = self.viewModel.colorScheme.textColor;

  [self.contentView addSubview:self.restorePurchasesButton];
  [self.restorePurchasesButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.pageControlBottomPaddingView.mas_bottom);
    make.centerX.equalTo(self.contentView);
    make.height.equalTo(@20);
  }];
}

- (void)setupTerms {
  _termsView = [[SPXSubscriptionTermsView alloc]
                initWithTermsText:self.viewModel.termsViewModel.termsText
                termsOfUseLink:self.viewModel.termsViewModel.termsOfUseLink
                privacyPolicyLink:self.viewModel.termsViewModel.privacyPolicyLink];
  self.termsView.termsTextContainerInset = UIEdgeInsetsMake(6, 0, 9, 0);
  [self.contentView addSubview:self.termsView];

  [self.termsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.bottom.equalTo(self.contentView);
    make.top.equalTo(self.restorePurchasesButton.mas_bottom).with.offset(10);
    make.width.equalTo(self.contentView).multipliedBy(0.94);
  }];
}

- (void)setupBottomGradient {
  auto gradientView = [[WFGradientView alloc] init];
  gradientView.userInteractionEnabled = NO;
  gradientView.colors = @[
    [UIColor clearColor],
    [UIColor lt_colorWithHex:@"#CC000000"]
  ];
  gradientView.startPoint = CGPointMake(0.5, 0);
  gradientView.endPoint = CGPointMake(0.5, 1.0);
  [self.view addSubview:gradientView];

  [gradientView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.left.right.equalTo(self.view.wf_safeArea);
    make.height.equalTo(self.view).multipliedBy(0.022);
  }];
}

- (void)setupActivityIndicator {
  _activityIndicatorView = [[UIActivityIndicatorView alloc]
                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
  self.activityIndicatorView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
  self.activityIndicatorView.hidesWhenStopped = YES;
  [self.contentView addSubview:self.activityIndicatorView];

  [self.activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.contentView);
  }];
}

- (void)setupDismissButton {
  auto *dismissButton = [[UIButton alloc] init];
  dismissButton.exclusiveTouch = YES;
  [dismissButton addTarget:self.viewModel action:@selector(dismissButtonPressed)
          forControlEvents:UIControlEventTouchUpInside];
  NSString *dismissIconURLString = @"paintcode://SPXDismissIcon/DismissIcon";
  dismissButton.wf_viewModel = WFImageViewModel([NSURL URLWithString:dismissIconURLString])
      .color([UIColor colorWithWhite:1 alpha:0.7])
      .sizeToBounds(dismissButton)
      .build();

  [self.view addSubview:dismissButton];
  [dismissButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(self.view).with.offset(10);
    make.top.equalTo(self.view.wf_safeArea).with.offset(10);
  }];
}

#pragma mark -
#pragma mark Bindings Setup
#pragma mark -

- (void)setupBindings {
  [self setupScrollPositionBinding];
  [self setupActivePageBinding];
  [self setupRestorePurchasesButtonPressedBinding];
  [self setupTermsGistBinding];
  [self setupActivityIndicatorBinding];
  [self setupAlertRequestBinding];
  [self setupFeedbackComposerRequestBinding];
}

- (void)setupScrollPositionBinding {
  @weakify(self);
  [RACObserve(self.pagingView, scrollPosition) subscribeNext:^(NSNumber *value) {
    @strongify(self);
    [self.viewModel scrolledToPosition:value.floatValue];
  }];
}

- (void)setupActivePageBinding {
  RAC(self.pageControl, currentPage) = [RACObserve(self.viewModel, activePageIndex)
                                        distinctUntilChanged];
}

- (void)setupRestorePurchasesButtonPressedBinding {
  @weakify(self);
  [[self.restorePurchasesButton rac_signalForControlEvents:UIControlEventTouchUpInside]
   subscribeNext:^(UIControl *) {
     @strongify(self);
     [self.viewModel restorePurchasesButtonPressed];
   }];
}

- (void)setupTermsGistBinding {
  RAC(self.termsView, termsGistText) = [RACObserve(self.viewModel.termsViewModel, termsGistText)
                                        distinctUntilChanged];
}

- (void)setupActivityIndicatorBinding {
  @weakify(self);
  [RACObserve(self.viewModel, shouldShowActivityIndicator) subscribeNext:^(NSNumber *active) {
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
    auto _Nullable mailComposer = [self.mailComposerProvider createFeedbackComposeViewController];

    if (mailComposer) {
      [mailComposer.dismissRequested subscribeNext:^(RACUnit *) {
        [self dismissViewControllerAnimated:YES completion:completionHandler];
      }];
      [self presentViewController:mailComposer animated:YES completion:nil];
    } else {
      completionHandler();
    }
  }];
}

- (RACSignal<RACUnit *> *)dismissRequested {
  return self.viewModel.dismissRequested;
}

@end

NS_ASSUME_NONNULL_END
