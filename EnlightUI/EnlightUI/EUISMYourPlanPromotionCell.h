// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

@protocol EUISMYourPlanPromotionViewModel;

/// Table view cell with promotion for upgrade of the current subscription. The cell contains the
/// promotion text and an upgrade button.
@interface EUISMYourPlanPromotionCell : UITableViewCell

/// View model for the cell view.
@property (nonatomic, nullable) id<EUISMYourPlanPromotionViewModel> viewModel;

@end

NS_ASSUME_NONNULL_END
