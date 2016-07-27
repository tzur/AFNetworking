// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CUIPreviewViewController.h"

#import "CUIPreviewViewModel.h"
#import "UIView+Retrieval.h"

SpecBegin(CUIPreviewViewController)

__block id viewModel;
__block CUIPreviewViewController *viewController;

beforeEach(^{
  viewModel = OCMClassMock([CUIPreviewViewModel class]);
  viewController = [[CUIPreviewViewController alloc] initWithViewModel:viewModel];
});

it(@"should create views", ^{
  expect([viewController.view wf_viewForAccessibilityIdentifier:@"LivePreview"]).notTo.beNil();
});

SpecEnd
