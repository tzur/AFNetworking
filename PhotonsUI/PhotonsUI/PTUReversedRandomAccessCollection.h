// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <LTKit/LTRandomAccessCollection.h>

NS_ASSUME_NONNULL_BEGIN

/// Adapter to a \c LTRandomAccessCollection reversing its contents.
///
/// @note NSFastEnumeration isn't supported by this collection as that would either break
/// encapsulation or involve potentially dangerous memory constraints.
@interface PTUReversedRandomAccessCollection : NSObject <LTRandomAccessCollection>

/// Initializes with \c collection to reverse.
- (instancetype)initWithCollection:(id<LTRandomAccessCollection>)collection;

@end

NS_ASSUME_NONNULL_END
