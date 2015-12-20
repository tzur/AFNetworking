// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboAttachment.h"

NS_ASSUME_NONNULL_BEGIN

/// Internal protocol that provides interface for writing to and clearing the attachment. This
/// protocol is used by \c LTFbo and the attachments internally to perform these tasks, and should
/// not be made public.
@protocol LTFboWritableAttachment <LTFboAttachment>

/// Executes \c block which writes using the GPU to the attachment, allowing the attachment to
/// execute relevant code before and after the actual write. Binding to the attachment, if required,
/// should be done by the caller, either inside \c block or before it is called by this method.
///
/// Calling this method will update the generation ID of the attachment and will set its
/// \c fillColor to \c LTVector4::null().
///
/// @note All GPU-based writes should be executed via this method.
- (void)writeToAttachmentWithBlock:(LTVoidBlock)block;

/// Executes \c block which clears the attachment with color \c color, allowing the attachment to
/// execute relevant code before and after the write.
///
/// Calling this method will update the generation ID of the attachment and set its \c fillColor to
/// \c color.
///
/// @note All GPU-based clears should be executed via this method.
- (void)clearAttachmentWithColor:(LTVector4)color block:(LTVoidBlock)block;

@end

NS_ASSUME_NONNULL_END
