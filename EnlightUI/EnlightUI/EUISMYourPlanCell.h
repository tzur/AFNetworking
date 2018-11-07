// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@protocol EUISMYourPlanViewModel;

/// Table view cell with information about user's subscription plan. The cell contains a
/// thumbnail of the current application and textual subscription presented as title, subtitle and
/// body. A spacer view is located between the title and the textual data below it and has the
/// accessibility identifier "YourPlanTitleSpacer". Another spacer view is located between the
/// subtitle and the textual data below it and has the accessibility identifier
/// "YourPlanSubtitleSpacer". In addition it contains icon reflecting the subscription status, and a
/// disclosure indicator image.
@interface EUISMYourPlanCell : UITableViewCell

/// View model for the cell view.
@property (strong, nonatomic, nullable) id<EUISMYourPlanViewModel> viewModel;

@end

NS_ASSUME_NONNULL_END
