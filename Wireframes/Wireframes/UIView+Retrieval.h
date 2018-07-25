// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Retrieval)

/// Returns the first view that has an \c accessibilityIdentifier equal to the given one. The search
/// order is DFS, so the following hierarchy:
///
/// + receiver
/// |-- a
/// |   \-- c
/// |-- b
/// |   \-- c
/// |-- c
///
/// Will return the view \c a.c for an accessibility identifier of \c c.
- (nullable __kindof UIView *)wf_viewForAccessibilityIdentifier:(NSString *)accessibilityIdentifier;

@end

NS_ASSUME_NONNULL_END
