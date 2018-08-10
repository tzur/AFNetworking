// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTInterval.h>
#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNPipeline, DVNPipelineConfiguration;

@protocol LTParameterizedObject;

/// Protocol to be implemented by delegates of \c DVNPipeline objects.
@protocol DVNPipelineDelegate <NSObject>

/// Is called directly after the rendering of the given \c quads by the given \c pipeline.
- (void)pipeline:(DVNPipeline *)pipeline renderedQuads:(const std::vector<lt::Quad> &)quads;

@end

/// Object representing a pipeline for iteratively rendering quadrilateral geometry constructed from
/// a given parameterized object. The pipeline consists of several stages which are executed
/// consecutively and linearly. The setup of the pipeline stages is performed using an immutable
/// configuration model provided upon initialization. Upon initialization, the objects performing
/// the stage tasks are constructed from the relevant submodels of the configuration model. This
/// inversion of control allows for different implementations of the pipeline stages.
///
/// The stages executed by the pipeline are:
/// 1. Sampling stage:
///      In this first stage, the given parameterized object is sampled, using the sampler
///      constructed from the corresponding model provided upon initialization.
/// 2. Geometry stage:
///      In this stage, quadrilateral geometry is constructed from the samples returned by the
///      sampling stage. The object responsible for the geometry construction is created from the
///      corresponding model provided upon initialization.
/// 3. Texture mapping stage:
///      In this stage, for each of the quadrilaterals returned by the geometry stage, an assignment
///      of texture coordinates to every vertex of the quadrilateral is performed.
/// 4. Attribute stage:
///      In this stage, for each of the quadrilateral returned by the geometry stage, auxiliary
///      attributes are assigned for every vertex of the quadrilateral.
/// 5. Render stage:
///      In this final stage, the data constructed by the geometry, texture mapping and attribute
///      stages are provided to a renderer producing the desired rendering. The renderer is
///      initialized with the shader code and auxiliary data provided by the corresponding model.
///
/// The discussed order of pipeline stages is also reflected by the occurrences of their
/// corresponding configuration models in the \c DVNPipelineConfiguration model.
///
/// The objects composing the pipeline might or might not be stateful. Hence, this pipeline object
/// must be assumed to be stateful. The current state of the object can be retrieved (in form of a
/// \c DVNPipelineConfiguration object) by calling the method \c currentConfiguration.
///
/// The pipeline does not assume any specific render target. It is the responsibility of the user to
/// to ensure the usage of an appropriate render target.
///
/// @important It is the responsibility of the user to a) provide a pipeline configuration whose
/// stages work together and b) to execute the pipeline only using parameterized objects that can be
/// handled by the stages. For example, if the \c id<LTContinuousSampler> object used in the
/// sampling stage assumes that the parameterized object has a parameterization key \c foo, all
/// parameterized objects with which the pipeline is executed must provide the required key \c foo.
@interface DVNPipeline : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c configuration.
- (instancetype)initWithConfiguration:(DVNPipelineConfiguration *)configuration
    NS_DESIGNATED_INITIALIZER;

/// Processes the given \c parameterizedObject in the given \c interval by executing the pipeline as
/// described above. The \c end indication should be \c YES if this is the last call of a sequence
/// of calls processing the given \c parameterizedObject, in order to allow the pipeline stages to
/// react on this information.
- (void)processParameterizedObject:(id<LTParameterizedObject>)parameterizedObject
                        inInterval:(lt::Interval<CGFloat>)interval
                               end:(BOOL)end;

/// Returns an immutable copy of the current configuration of this instance.
- (DVNPipelineConfiguration *)currentConfiguration;

/// Sets the configuration of the receiver to the given \c configuration.
///
/// @important Like upon initialization, the given \c configuration must be compatible to the
/// parameterized object consecutively processed.
- (void)setConfiguration:(DVNPipelineConfiguration *)configuration;

/// Delegate to be informed.
@property (weak, nonatomic) id<DVNPipelineDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
