// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

NS_ASSUME_NONNULL_BEGIN

@class LTGLPixelFormat;

/// Type of framebuffer attachable.
typedef NS_ENUM(NSUInteger, LTFboAttachableType) {
  /// 2D texture attachable.
  LTFboAttachableTypeTexture2D = GL_TEXTURE_2D,
  /// Renderbuffer attachable.
  LTFboAttachableTypeRenderbuffer = GL_RENDERBUFFER,
};

/// An OpenGL resource that can be attached to a framebuffer object. Implementers of this protocol
/// are responsible for providing the size, type and format, together with metadata such as
/// the generation ID and the fill color of the attachable. Additionally, such attachable should
/// provide methods for writing to it and clearing it with a specific color.
@protocol LTFboAttachable <LTGPUResource>

/// Type of framebuffer attachable.
@property (readonly, nonatomic) LTFboAttachableType attachableType;

/// Size of the framebuffer attachable.
@property (readonly, nonatomic) CGSize size;

/// Pixel format of the attachable.
@property (readonly, nonatomic) LTGLPixelFormat *pixelFormat;

/// Current generation ID of the attachable. The generation ID changes whenever the attachable is
/// modified, and when the attachable is cloned, copied to its clone. This can be used as an
/// efficient way to check if an attachable has changed or if two attachables have the same content.
///
/// @note While two attachables having equal \c generationID implies that they have the same
/// content, the other direction is not necessarily true as two attachables can have the same
/// content with different \c generationID.
@property (readonly, nonatomic) NSString *generationID;

/// Returns the color the entire attachable and all its levels is filled with, or
/// \c LTVector4::null() if the attachable is not filled with a single color or it is uncertain if
/// it is filled with a single color.
@property (readonly, nonatomic) LTVector4 fillColor;

@end

NS_ASSUME_NONNULL_END
