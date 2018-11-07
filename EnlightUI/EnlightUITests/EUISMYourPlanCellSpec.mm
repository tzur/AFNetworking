// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanCell.h"

#import "EUISMFakeYourPlanViewModel.h"

SpecBegin(EUISMYourPlanCell)

__block EUISMYourPlanCell *yourPlanCell;
__block UIView *titleSpacer;
__block UIView *subtitleSpacer;
__block EUISMFakeYourPlanViewModel *viewModel;

beforeEach(^{
  yourPlanCell = [[EUISMYourPlanCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  titleSpacer = [yourPlanCell wf_viewForAccessibilityIdentifier:@"YourPlanTitleSpacer"];
  subtitleSpacer = (UILabel *)[yourPlanCell
                               wf_viewForAccessibilityIdentifier:@"YourPlanSubtitleSpacer"];
  viewModel = [[EUISMFakeYourPlanViewModel alloc] init];
  viewModel.title = @"title";
  viewModel.subtitle = @"subtitle";
  viewModel.body = @"body";
  yourPlanCell.viewModel = viewModel;
});

context(@"title spacer", ^{
  it(@"should not hide title spacer when title, subtitle and body are not empty", ^{
    expect(titleSpacer.hidden).to.beFalsy();
  });

  it(@"should hide title spacer when title is empty but subtitle and body are not", ^{
    viewModel.title = @"";

    expect(titleSpacer.hidden).to.beTruthy();
  });

  it(@"should not hide title spacer when title and body are not empty but subtitle is", ^{
    viewModel.subtitle = @"";

    expect(titleSpacer.hidden).to.beFalsy();
  });

  it(@"should not hide title spacer when title and subtitle are not empty but body is", ^{
    viewModel.body = @"";

    expect(titleSpacer.hidden).to.beFalsy();
  });

  it(@"should hide title spacer when body is not empty but title and subtitle are", ^{
    viewModel.title = @"";
    viewModel.subtitle = @"";

    expect(titleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide title spacer when subtitle is not empty but title and body are", ^{
    viewModel.title = @"";
    viewModel.body = @"";

    expect(titleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide title spacer when title is not empty but subtitle and body are", ^{
    viewModel.subtitle = @"";
    viewModel.body = @"";

    expect(titleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide title spacer when title, subtitle and body are empty", ^{
    viewModel.title = @"";
    viewModel.subtitle = @"";
    viewModel.body = @"";

    expect(titleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide title spacer when view model is nil", ^{
    yourPlanCell.viewModel = nil;

    expect(titleSpacer.hidden).to.beTruthy();
  });
});

context(@"subtitle spacer", ^{
  it(@"should not hide subtitle spacer when title, subtitle and body are not empty", ^{
    expect(subtitleSpacer.hidden).to.beFalsy();
  });

  it(@"should not hide subtitle spacer when title is empty but subtitle and body are not", ^{
    viewModel.title = @"";

    expect(subtitleSpacer.hidden).to.beFalsy();
  });

  it(@"should hide subtitle spacer when title and body are not empty but subtitle is", ^{
    viewModel.subtitle = @"";

    expect(subtitleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide subtitle spacer when title and subtitle are not empty but body is", ^{
    viewModel.body = @"";

    expect(subtitleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide subtitle spacer when body is not empty but title and subtitle are", ^{
    viewModel.title = @"";
    viewModel.subtitle = @"";

    expect(subtitleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide subtitle spacer when subtitle is not empty but title and body are", ^{
    viewModel.title = @"";
    viewModel.body = @"";

    expect(subtitleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide subtitle spacer when title is not empty but subtitle and body are", ^{
    viewModel.subtitle = @"";
    viewModel.body = @"";

    expect(subtitleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide subtitle spacer when title, subtitle and body are empty", ^{
    viewModel.title = @"";
    viewModel.subtitle = @"";
    viewModel.body = @"";

    expect(subtitleSpacer.hidden).to.beTruthy();
  });

  it(@"should hide subtitle spacer when view model is nil", ^{
    yourPlanCell.viewModel = nil;

    expect(subtitleSpacer.hidden).to.beTruthy();
  });
});

it(@"should deallocate even when view model has not deallocated", ^{
  __weak EUISMYourPlanCell *weakCell = nil;
  @autoreleasepool {
    auto cell = [[EUISMYourPlanCell alloc] initWithFrame:CGRectZero];
    cell.viewModel = viewModel;
    weakCell = cell;
  }
  expect(weakCell).to.beNil();
});

SpecEnd
