// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// View that displays a \c CALayer in its frame. Intended to help apply AutoLayout to a layer.
@interface CUILayerView : UIView

/// Initializes the view to display the given layer.
- (instancetype)initWithLayer:(CALayer *)layer;

@end

NS_ASSUME_NONNULL_END
