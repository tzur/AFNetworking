// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Immutable object that represents a snapshot of a project. This object should only by constructed
/// by WHSProjectStorage from the storage of a project that was stored, and not by the user of this
/// library.
@interface WHSProjectSnapshot : NSObject

@end

NS_ASSUME_NONNULL_END
