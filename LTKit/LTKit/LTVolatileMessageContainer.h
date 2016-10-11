// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Shachar Langbeheim.

#import "LTMessageContainer.h"

NS_ASSUME_NONNULL_BEGIN

/// Container that keeps a limited number of messages in memory.
@interface LTVolatileMessageContainer : NSObject <LTMessageContainer>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c maxNumberOfEntries. Once the internal buffer contains that many
/// entries, the oldest entry will be discarded to make room for a new one.
- (instancetype)initWithMaxNumberOfEntries:(NSUInteger)maxNumberOfEntries;

/// Max number of entries saved in memory.
@property (readonly, nonatomic) NSUInteger maxNumberOfEntries;

@end

NS_ASSUME_NONNULL_END
