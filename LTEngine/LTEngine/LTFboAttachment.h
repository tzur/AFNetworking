// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

NS_ASSUME_NONNULL_BEGIN

@class LTGLPixelFormat;

/// Type of framebuffer attachment.
typedef NS_ENUM(NSUInteger, LTFboAttachmentType) {
  /// 2D texture attachment.
  LTFboAttachmentTypeTexture2D = GL_TEXTURE_2D,
  /// Renderbuffer attachment.
  LTFboAttachmentTypeRenderbuffer = GL_RENDERBUFFER,
};

/// An OpenGL resource that can be attached to a framebuffer object. Implementers of this protocol
/// are responsible for providing the size, type and format, together with metadata such as
/// the generation ID and the fill color of the attachment. Additionally, such attachment should
/// provide methods for writing to it and clearing it with a specific color.
@protocol LTFboAttachment <LTGPUResource>

/// Type of framebuffer attachment.
@property (readonly, nonatomic) LTFboAttachmentType attachmentType;

/// Size of the framebuffer attachment.
@property (readonly, nonatomic) CGSize size;

/// Pixel format of the attachment.
@property (readonly, nonatomic) LTGLPixelFormat *pixelFormat;

/// Current generation ID of the attachment. The generation ID changes whenever the attachment is
/// modified, and when the attachment is cloned, copied to its clone. This can be used as an
/// efficient way to check if an attachment has changed or if two attachments have the same content.
///
/// @note While two attachments having equal \c generationID implies that they have the same
/// content, the other direction is not necessarily true as two attachments can have the same
/// content with different \c generationID.
@property (readonly, nonatomic) NSString *generationID;

/// Returns the color the entire attachment and all its levels is filled with, or
/// \c LTVector4::null() if the attachment is not filled with a single color or it is uncertain if
/// it is filled with a single color.
@property (readonly, nonatomic) LTVector4 fillColor;

@end

NS_ASSUME_NONNULL_END
