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

/// Executes \c block which writes using the GPU to the attachable, allowing the attachable to
/// execute relevant code before and after the actual write. Binding to the attachable, if required,
/// should be done by the caller, either inside \c block or before it is called by this method.
///
/// Calling this method will update the generation ID of the attachable and will set its
/// \c fillColor to \c LTVector4::null().
///
/// @note All GPU-based writes should be executed via this method.
- (void)writeToAttachableWithBlock:(NS_NOESCAPE LTVoidBlock)block;

/// Executes \c block which clears the attachable with color \c color, allowing the attachable to
/// execute relevant code before and after the write.
///
/// Calling this method will update the generation ID of the attachable and set its \c fillColor to
/// \c color.
///
/// @note All GPU-based clears should be executed via this method.
- (void)clearAttachableWithColor:(LTVector4)color block:(NS_NOESCAPE LTVoidBlock)block;

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
