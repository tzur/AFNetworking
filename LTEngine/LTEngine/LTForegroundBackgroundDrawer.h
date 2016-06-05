// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTTextureDrawer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for drawing using two different drawers, one for foreground and one for background.
@interface LTForegroundBackgroundDrawer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the drawer with a given \c foregroundDrawer, a given \c backgroundDrawer and a \c
/// foregroundRect.
- (instancetype)initWithForegroundDrawer:(id<LTTextureDrawer>)foregroundDrawer
                        backgroundDrawer:(id<LTTextureDrawer>)backgroundDrawer
                          foregroundRect:(CGRect)foregroundRect NS_DESIGNATED_INITIALIZER;

/// Draws the \c sourceRect into the \c targetRect region in the given framebuffer. The region in
/// \c sourceRect that is inclusively contained inside the foreground area will be drawn using the
/// \c foregroundDrawer. The rest of the source region will be drawn using the \c backgroundDrawer.
///
/// @see [id<LTTextureDrawer> drawRect:inFramebuffer:fromRect] for more information.
- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect;

/// Draws the \c sourceRect into the \c targetRect region in an already bound offscreen framebuffer
/// with the given size. The region in \c sourceRect that is inclusively contained inside the
/// foreground area will be drawn using the \c foregroundDrawer. The rest of the source region will
/// be drawn using the \c backgroundDrawer.
///
/// @see [id<LTTextureDrawer> drawRect:inFramebufferWithSize:fromRect] for more information.
- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect;

/// Drawer that is used for drawing on the background area.
@property (readonly, nonatomic) id<LTTextureDrawer> backgroundDrawer;

/// Drawer that is used for drawing on the foreground area.
@property (readonly, nonatomic) id<LTTextureDrawer> foregroundDrawer;

@end

NS_ASSUME_NONNULL_END
