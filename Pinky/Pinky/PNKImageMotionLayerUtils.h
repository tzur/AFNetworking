// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Verifies that \c displacements is a two-channel half-float matrix of size \c expectedSize.
void PNKImageMotionValidateDisplacementsMatrix(const cv::Mat &displacements, cv::Size expectedSize);

NS_ASSUME_NONNULL_END
