// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Maximum number of bins supported by the kernel, based on the available threadgroup memory on the
/// lower end devices. Number is \c 1016 and not \c 1024 since in some iOS and tvOS feature sets,
/// the
/// driver may consume up to 32 bytes of a device's total threadgroup memory.
#define PNK_COLOR_TRANSFER_CDF_MAX_SUPPORTED_HISTOGRAM_BINS (1016);
