// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Macro releasing a given \c CFTypeRef if it is not \c NULL and setting it to \c NULL afterwards.
#define LTCFSafeRelease(referenceToRelease) \
  if (referenceToRelease) { \
    CFRelease(referenceToRelease); \
  } \
  referenceToRelease = NULL;

NS_ASSUME_NONNULL_END
