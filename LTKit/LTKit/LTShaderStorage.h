// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Container class for retrieving source of shaders, which are encrypted and stored as buffer in
/// build time. This class only provides the basic functionality for decrypting the shaders and
/// retrieving them. The shaders themselves should be created by adding a category to this class.
@interface LTShaderStorage : NSObject

/// Returns a shader's source with the given name. This method is a dynamic alternative to the
/// static \c -[LTShaderStorage <shader name>] method invocation. If the shader cannot be found, an
/// exception is raised.
+ (NSString *)shaderSourceWithName:(NSString *)name;

@end
