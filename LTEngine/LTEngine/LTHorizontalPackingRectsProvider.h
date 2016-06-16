// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTPackingRectsProvider.h"

/// Implementation of \c LTPackingRectsProvider using horizontal packing. Given the \c sizes
/// map, the placement concatenates rects of those sizes in horizontal fashion.
@interface LTHorizontalPackingRectsProvider : NSObject <LTPackingRectsProvider>
@end
