// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTProgram;

/// Protocol for factories that create \c LTProgram objects. The rationales for not creating these
/// objects directly stem from various reasons, such as caching, runtime source modification and
/// logging.
@protocol LTProgramFactory <NSObject>

/// Creates a new program given a \c vertexSource and a \c fragmentSource.
- (LTProgram *)programWithVertexSource:(NSString *)vertexSource
                        fragmentSource:(NSString *)fragmentSource;

@end

/// Creates a program with the given vertex and fragment sources. This is the default factory that
/// should be used when creating programs.
@interface LTBasicProgramFactory : NSObject <LTProgramFactory>
@end

/// Creates a program like \c LTBasicProgramFactory, but verifies that a set of given uniforms exist
/// in the program prior to returning it.
@interface LTVerifierProgramFactory : LTBasicProgramFactory

/// Initializes with a set of required uniforms as \c NSString.
- (instancetype)initWithRequiredUniforms:(NSSet *)uniforms;

@end

/// Creates a program with the given vertex shader and a modified fragment shader that run the
/// given fragment shader, then mixes between the result and the input texture using a mask
/// texture. The mix done is via mix(input, result, mask.r), so a white mask will keep the original
/// fragment shader result, where a black mask will show only the input texture.
@interface LTMaskableProgramFactory : NSObject <LTProgramFactory>

/// Initializes with no shader variable that holds the input texture color. In this scenario, a new
/// sampler uniform will be created for attaching the input texture, with the name \c
/// kLTMaskableProgramInputUniformName.
- (instancetype)init;

/// Designated initializer: initializes with the shader variable name that holds the input texture
/// color.
- (instancetype)initWithInputColorVariableName:(NSString *)inputColor;

/// Default name of the uniform texture sampler of the input texture.
extern NSString * const kLTMaskableProgramInputUniformName;

/// Default name of the uniform texture sampler of the mask texture.
extern NSString * const kLTMaskableProgramMaskUniformName;

/// Default name of the varying which specifies the sampling position for both textures.
extern NSString * const kLTMaskableProgramSamplingDefaultVaryingName;

/// Name of the shader variable name that holds the input texture color. If this is \c nil, the
/// color will be sampled from the input texture.
@property (readonly, nonatomic) NSString *inputColorVariableName;

/// Name of the varying which specifies the sampling position for both textures. Default value is
/// kLTMaskableProgramDefaultSamplingVaryingName.
@property (strong, nonatomic) NSString *samplingVaryingName;

@end
