// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUResource.h"

/// @class LTProgram
///
/// Object for representing a GLSL program. The program is composed of a vertex and a fragment
/// shader and may include uniforms (variables that are global for the entire drawing of an object)
/// and attributes (variables that are set for each vertex).
/// This class takes care of loading the shaders from a string, compiling and linking them, and
/// getting/setting the uniforms and attributes indices to set their values.
@interface LTProgram : NSObject <LTGPUResource>

/// Initializes an OpenGL program. Once a shader is loaded, attribute and uniforms information will
/// be retrieved.
///
/// Throws LTGLException with \c kLTProgramCreationFailedException if the program failed to create,
/// and \c kLTProgramLinkFailedException if the program linking failed.
///
/// @param vertexSource GLSL source of the vertex shader.
/// @param fragmentSource GLSL source of the fragment shader.
- (id)initWithVertexSource:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource;

/// Returns true if the program is valid. See \c glValidateProgram for more information on when
/// programs are valid or not.
- (BOOL)isProgramValid;

/// Retrieves a uniform index given its name. The given name must be one of the names that were
/// supplied in the initializer. Otherwise, the result is undefined.
- (GLuint)uniformForName:(NSString *)name;

/// Retrieves an attribute index given its name. The given name must be one of the names that were
/// supplied in the initializer. Otherwise, the result is undefined.
- (GLuint)attributeForName:(NSString *)name;

/// Returns yes iff the program contains a uniform variable with the given name.
- (BOOL)containsUniform:(NSString *)name;

/// Returns yes iff the program contains an attribute variable with the given name.
- (BOOL)containsAttribute:(NSString *)name;

/// Sets a uniform's value. The value can be either an \c NSNumber (if the type of the uniform is
/// \c int or \c float), or an \c NSValue (for vector and matrix types).
- (void)setUniform:(NSString *)name withValue:(id)value;

/// Retrieves the value of the given uniform. The returned value can be either an \c NSNumber (if
/// the type of the uniform is \c int or \c float), or an \c NSValue (for vector and matrix types).
- (id)uniformValue:(NSString *)name;

/// Subscript setter to uniform values.
///
/// Examples of use:
/// @code
/// LTProgram *prog = ...;
/// prog[@"myUniform"] = @(5);  // Same as glUniform1f().
///
/// LTVector3 vec = LTVector3(1.f, 2.f, 3.f);
/// prog[@"myUniform"] = [NSValue valueWithLTVector3:vec];  // Same as glUniform3f().
/// @endcode
///
/// @param obj value to set. The type of \c obj must be either an \c NSNumber or
/// \c NSValue and match the underlying uniform type.
/// @param key name of the uniform or arrtibute to set.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

/// Subscript getter to the uniform value keyed by its name.
- (id)objectForKeyedSubscript:(NSString *)key;

/// Names of all uniforms of the program.
@property (readonly, nonatomic) NSSet *uniforms;

/// Names of all attributes of the program.
@property (readonly, nonatomic) NSSet *attributes;

@end
