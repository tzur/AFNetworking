// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Object for representing a GLSL program. The program is composed of a vertex and a fragment
/// shader and may include uniforms (variables that are global for the entire drawing of an object)
/// and attributes (variables that are set for each vertex).
/// This class takes care of loading the shaders from a string, compiling and linking them, and
/// storing the uniforms and attributes indices to set their values.
@interface LTProgram : NSObject

/// Initializes an OpenGL program. Once shader is loaded, attribute indices will be set to their
/// corresponding location in the given vector.  If the program could not be compiled, \c nil is
/// returned.
///
/// @param vertexSource GLSL source of the vertex shader.
/// @param fragmentSource GLSL source of the fragment shader.
/// @param uniforms array of \c NSString elements that contains the shader's uniforms names.
/// @param attributes array of \c NSString elements that contains the shader's attributes names.
- (id)initWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource
                  uniforms:(NSArray *)uniforms andAttributes:(NSArray *)attributes;

/// Binds the program to the current active OpenGL context. If the shader is already bound, nothing
/// will happen. Once \c bind() is called, you must call the matching \c unbind() when the resource
/// is no longer needed for rendering.
- (void)bind;

/// Unbinds the program from the current active OpenGL context and binds the previous program
/// instead. If the program is not bound, nothing will happen.
- (void)unbind;

/// Returns true if the program is valid. See \c glValidateProgram for more information on when
/// programs are valid or not.
- (BOOL)isProgramValid;

/// Retrieves a uniform index given its name. The given name must be one of the names that were
/// supplied in the initializer. Otherwise, the result is undefined.
- (GLuint)uniformForName:(NSString *)name;

/// Retrieves an attribute index given its name. The given name must be one of the names that were
/// supplied in the initializer. Otherwise, the result is undefined.
- (GLuint)attributeForName:(NSString *)name;

/// Returns yes iff the shader contains a uniform variable with the given name.
- (BOOL)containsUniform:(NSString *)name;

/// Returns yes iff the shader contains an attribute variable with the given name.
- (BOOL)containsAttribute:(NSString *)name;

/// OpenGL name of the program.
@property (readonly, nonatomic) GLuint name;

@end
