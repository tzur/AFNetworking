// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIMutableMenuItemView.h"

NS_ASSUME_NONNULL_BEGIN

/// Cell that displays an icon and a title. When the \c viewModel is selected, highlighted colors
/// are used. The \c hidden and \c subitems properties of the \c viewModel are not used.
@interface CUIIconWithTitleCell : UICollectionViewCell <CUIMutableMenuItemView>
@end

NS_ASSUME_NONNULL_END
