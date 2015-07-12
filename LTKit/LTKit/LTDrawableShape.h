// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// By implementing this protocol, a class can be drawn by the \c LTShapeDrawer.
/// The protocol contains two parts: the draw methods are used by the \c LTShapeDrawer to perform
/// the actual drawing, depending on the target (texture or screen).
/// The opacity/translation/rotationAngle setters and getters allow it to update the shape without
/// updating its vertices (which can be expensive, in case of a shape with many vertices).
@protocol LTDrawableShape <NSObject>

/// Draws the shape on the currently bound framebuffer.
- (void)drawInFramebufferWithSize:(CGSize)size;

/// The translation of the shape (from the origin).
@property (nonatomic) CGPoint translation;

/// The rotation angle (clockwise, around the origin) of the shape.
@property (nonatomic) CGFloat rotationAngle;

/// The opacity of the shape to draw.
@property (nonatomic) CGFloat opacity;

@end
