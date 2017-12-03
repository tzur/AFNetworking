// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "TINMessage.h"

NS_ASSUME_NONNULL_BEGIN

/// TestHost's application group ID, used in specs.
extern NSString * const kTINTestHostAppGroupID;

/// Removes the contents of an application group directory associated with
/// \c kTINTestHostAppGroupID, if it exists.
void TINCleanupTestHostAppGroupDirectory();

NS_ASSUME_NONNULL_END
