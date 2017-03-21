// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

@class LTTexture, LTRenderbuffer;

@protocol LTFboAttachable;

/// Describes how to attach an \c id<LTFboAttachable> to a framebuffer by providing the attachable
/// and its level.
@interface LTFboAttachmentInfo : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c attachable.
+ (instancetype)withAttachable:(id<LTFboAttachable>)attachable;

/// Initializes with the given \c attachable and the given \c level.
///
/// @note \c attachable.attachableType must be \c LTFboAttachableTypeTexture2D. \c level must be
/// not greater than texture's \c maxMipmapLevel.
+ (instancetype)withAttachable:(id<LTFboAttachable>)attachable level:(GLint)level;

/// Framebuffer's attachable.
@property (readonly, nonatomic) id<LTFboAttachable> attachable;

/// Mipmap level of an attachable. Only valid for texture attachable.
@property (readonly, nonatomic) GLint level;

@end

NS_ASSUME_NONNULL_END
