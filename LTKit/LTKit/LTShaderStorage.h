// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Utility class for retrieving source of shaders, which are encrypted and stored as buffer in
/// build time. This class only provides the basic functionality for decrypting the shaders and
/// retrieving them. The shaders themselves should be created by adding a new class that uses this
/// one.
@interface LTShaderStorage : NSObject

/// Decrypts the shader with the given buffer and length.
+ (NSString *)shaderWithBuffer:(void *)buffer ofLength:(NSUInteger)length;

@end
