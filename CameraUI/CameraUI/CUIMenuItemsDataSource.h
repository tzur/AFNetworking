// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

@protocol CUIMenuItemViewModel;

/// Collection view data source that configures each cell with a \c CUIMenuItemViewModel.
@interface CUIMenuItemsDataSource : NSObject <UICollectionViewDataSource>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes this data source. \c reusableCellIdentifier is used for fetching cells from the
/// \c UICollectionViewCell. The received cells must conform to the \c CUIMutableMenuItemView
/// protocol.
- (instancetype)initWithItemViewModels:(NSArray<id<CUIMenuItemViewModel>> *)itemViewModels
                reusableCellIdentifier:(NSString *)reusableCellIdentifier NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
