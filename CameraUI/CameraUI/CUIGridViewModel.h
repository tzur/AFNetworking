// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#include "CUIMenuItemViewModel.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for showing a grid with toggleable visibility.
@protocol CUIGridContainer <NSObject>

/// \c YES when the grid should be hidden.
@property (nonatomic) BOOL gridHidden;

@end

/// \c CUIMenuItemViewModel for a menu item button that toggles the visibility of a grid.
///
/// The \c hidden and \c selected properties are always \c NO, and the \c subitems property is
/// always \c nil.
///
/// Calling \c didTap toggles the visibility of the \c CUIGridContainer's grid.
@interface CUIGridViewModel : NSObject <CUIMenuItemViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c gridContainer, \c title and \c iconURL.
- (instancetype)initWithGridContainer:(id<CUIGridContainer>)gridContainer title:(NSString *)title
                              iconURL:(NSURL *)iconURL;

@end

NS_ASSUME_NONNULL_END
