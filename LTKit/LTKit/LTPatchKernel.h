// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <opencv2/core/core.hpp>

/// Creates a kernel for Patch with the given \c size. The kernel function is:
/// @code f_c(p) = 1 / ((||p - c|| + 0.1) ^ 3) @endcode
/// where p is the current point and c is the center of the kernel.
cv::Mat1f LTPatchKernelCreate(const cv::Size &size);
