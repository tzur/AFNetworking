// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTContinuousSampler.h>

#import "DVNAttributeProvider.h"
#import "DVNGeometryProvider.h"
#import "DVNTexCoordProvider.h"

@class DVNPipelineConfiguration, DVNRenderStageConfiguration;

/// Protocol to be implemented by objects constituting the model of a pipeline stage component used
/// for testing. The objects provide a numeric \c state property whose value is increased every time
/// the pipeline stage component is executed.
@protocol DVNTestPipelineStageModel <NSObject>

/// Number of executions of the pipeline stage component whose state is represented by this model.
/// Initial value is \c 0.
@property (readonly, nonatomic) NSUInteger state;

@end

/// Single key of mapping of \c id<LTSampleValue> objects returned by
/// \c DVNPipelineTestContinuousSamplerModel.
extern NSString * const kQuadSizeKey;

/// Model of a sampler allowing up to two sampling queries. The parameterized object and interval
/// provided to the sampler are ignored. For the first sampling query, the sampler returns an
/// \c id<LTSampleValue> object with \c sampledParametricValues <tt>{0.0, 0.5}</tt> and a mapping
/// from key \c kQuadSizeKey to values <tt>{1.0 / 16, 1.0 / 8}</tt>. For the second sampling query,
/// the sampler returns an \c id<LTSampleValue> object with \c sampledParametricValues
/// <tt>{1.0, 1.5}</tt> and a mapping from kQuadSizeKey to <tt>{1.0 / 4, 1.0 / 2}</tt>.
@interface DVNPipelineTestContinuousSamplerModel : NSObject <LTContinuousSamplerModel,
    DVNTestPipelineStageModel>
@end

/// Model of a geometry provider allowing up to two geometry creation queries. For any of the two
/// geometry creation queries, the provider returns an ordered collection of quads
/// <tt>lt::Quad(CGRectMake(quadSize, quadSize, quadSize, quadSize))</tt>, where \c quadSize is the
/// value retrieved from the given \c id<LTSampleValue> objects for key \c kQuadSizeKey. Must be
/// called with the output of the \c DVNPipelineTestContinuousSamplerModel.
@interface DVNPipelineTestGeometryProviderModel : NSObject <DVNGeometryProviderModel,
    DVNTestPipelineStageModel>
@end

/// Ordered collection of quads.
static const std::array<lt::Quad, 4> kTextureMapQuads({{
  lt::Quad(CGRectMake(0, 0, 0.25, 0.25)),
  lt::Quad(CGRectMake(0.75, 0, 0.25, 0.25)),
  lt::Quad(CGRectMake(0.75, 0.75, 0.25, 0.25)),
  lt::Quad(CGRectMake(0, 0.75, 0.25, 0.25))
}});

/// Model of a texture coordinate provider allowing up to two texture coordinate queries. For
/// texture coordinate queries, the provider returns the quads in \c kTextureMapQuads in cyclic
/// order, starting with \c kTextureMapQuads[0].
@interface DVNPipelineTestTexCoordProviderModel : NSObject <DVNTexCoordProviderModel,
    DVNTestPipelineStageModel>
@end

/// Model of an attribute provider allowing up to two attribute data queries. The \c LTAttributeData
/// returned by the provider requires usage with shaders possessing an <tt>attribute float</tt>
/// variable with name \c  factor. The values of the returned \c LTAttributeData are
/// <tt>{1, 1, 1, 1, 1, 1, 1 - c, 1 - c, 1 - c, 1 - c, 1 - c, 1 - c, 1 - 2 * c, 1 - 2 * c,
/// 1 - 2 * c, 1 - 2 * c, 1 - 2 * c, 1 - 2 * c, ...}</tt>, where \c c equals \c 1 divided by the
/// number of the quads provided in the specific attribute data query.
@interface DVNPipelineTestAttributeProviderModel : NSObject <DVNAttributeProviderModel,
    DVNTestPipelineStageModel>
@end

/// Returns a <tt>2 x 2</tt> texture with pixel colors red, green, yellow, blue (in clockwise-order,
/// starting from the top-left pixel).
cv::Mat4b DVNTestTextureMappingMatrix();

/// Returns a configuration for a \c DVNPipeline object that can be used for testing. The returned
/// configuration uses the following pipeline stage configurations:
/// Sampling stage: \c DVNPipelineTestContinuousSamplerModel
/// Geometry stage: \c DVNPipelineTestGeometryProviderModel
/// Texture mapping stage: \c DVNPipelineTestGeometryProviderModel in conjunction with a texture
/// constructed from the value of \c DVNTestTextureMappingMatrix().
/// Attribute stage: \c DVNPipelineTestAttributeProviderModel
/// Render stage: \c DVNTestShader vertex and fragment shaders and no uniforms or auxiliaryTextures.
DVNPipelineConfiguration *DVNTestPipelineConfiguration();

/// Returns the <tt>16 x 16</tt> matrix constituting the rendering result of a single execution of a
/// \c DVNPipeline initialized with the configuration returned by \c DVNTestPipelineConfiguration(),
/// given that the render target has size <tt>16 x 16</tt>.
cv::Mat4b DVNTestSingleProcessResult();

/// Returns the <tt>16 x 16</tt> matrix constituting the rendering result of two consecutive
/// executions of a \c DVNPipeline initialized with the configuration returned by
/// \c DVNTestPipelineConfiguration(), given that the render target has size <tt>16 x 16</tt>.
cv::Mat4b DVNTestConsecutiveProcessResult();
