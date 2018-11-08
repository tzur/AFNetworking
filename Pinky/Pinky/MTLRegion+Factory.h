// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kupchick.

NS_ASSUME_NONNULL_BEGIN

/// Returns \c MTLRegion created from the given \c rect.
MTLRegion MTLRegionFromCGRect(CGRect rect);

/// Returns \c MTLRegion created from the given \c rect.
MTLRegion MTLRegionFromCVRect(cv::Rect rect);

NS_ASSUME_NONNULL_END
