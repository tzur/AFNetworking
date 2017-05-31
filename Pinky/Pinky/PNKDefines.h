// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

// MetalPerformanceShaders doesn't exist on simulator targets.
#if !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
  #define PNK_USE_MPS 1
#else
  #define PNK_USE_MPS 0
#endif
