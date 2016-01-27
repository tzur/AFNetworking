// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Options for fitting an image’s aspect ratio to a requested size.
typedef NS_ENUM(NSUInteger, PTNImageContentMode) {
  /// Scales the image so that its larger dimension fits the target size.
  PTNImageContentModeAspectFit,
  /// Scales the image so that it completely fills the target size.
  PTNImageContentModeAspectFill
};
