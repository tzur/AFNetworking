// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCFExtensions.h"

void LTCFSafeRelease(CFTypeRef referenceToRelease) {
  if (referenceToRelease) {
    CFRelease(referenceToRelease);
  }
}
