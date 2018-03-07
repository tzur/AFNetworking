// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Verifies that the keys of \c collection are exactly the strings in \c names. \c designation
/// should contain a description of \c collection. \c designation is used for debug purposes only.
void PNKValidateCollection(NSDictionary *collection, NSArray<NSString *> *names,
                           NSString *designation);

NS_ASSUME_NONNULL_END
