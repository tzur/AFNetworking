// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageContentMode.h"

NS_ASSUME_NONNULL_BEGIN

/// Resizes images in an efficient manner by leveraging ImageIO capabilities. Naively, resizing
/// image requires to load the entire image to memory, which requires a theoretical unbounded amount
/// of RAM. This class allows resizing of images while keeping the memory footprint low.
@interface PTNImageResizer : NSObject

/// Resizes the image located at the given \c url, which must be a file URL, by fitting it to the
/// given \c size using \c contentMode. If \c size is larger than the image's size, the returned
/// image will be original one.
///
/// The returned signal will return a single \c UIImage and complete on success, and will error if
/// the image cannot be found or opened.
- (RACSignal *)resizeImageAtURL:(NSURL *)url toSize:(CGSize)size
                    contentMode:(PTNImageContentMode)contentMode;

@end

NS_ASSUME_NONNULL_END
