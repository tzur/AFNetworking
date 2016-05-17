// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Creates a new instance of \c UIImage, all black, with the given \c width and \c height
/// (in points). \c scale is set to the scale factor of the main screen.
UIImage *WFCreateBlankImage(CGFloat width, CGFloat height);

#ifdef __cplusplus
} // extern "C"
#endif

NS_ASSUME_NONNULL_END
