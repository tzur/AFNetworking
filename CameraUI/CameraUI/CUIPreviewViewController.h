// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

@protocol CUIPreviewViewModel;

NS_ASSUME_NONNULL_BEGIN

/// View controller that displays a live preview and handles tap and pinch gestures.
///
/// The live preview has the following accessibility identifier: "LivePreview".
@interface CUIPreviewViewController : UIViewController

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

- (instancetype)initWithNibName:(nullable NSString *)nibName
                         bundle:(nullable NSBundle *)bundle NS_UNAVAILABLE;

/// Initializes the preview with the given view model.
- (instancetype)initWithViewModel:(id<CUIPreviewViewModel>)viewModel NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
