// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNTestPipelineConfiguration.h"

#import <LTEngine/LTAttributeData.h>
#import <LTEngine/LTGPUStruct.h>
#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNPipelineConfiguration.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"
#import "LTShaderStorage+DVNTestShaderFsh.h"
#import "LTShaderStorage+DVNTestShaderVsh.h"

LTGPUStructMake(DVNPipelineTestStruct,
                float, factor);

LTGPUStruct *DVNPipelineTestGPUStruct() {
  return [[LTGPUStructRegistry sharedInstance] structForName:@"DVNPipelineTestStruct"];
}

static const cv::Vec4b kWhite(255, 255, 255, 255);
static const cv::Vec4b kRed(255, 0, 0, 255);
static const cv::Vec4b kGreen(0, 255, 0, 255);
static const cv::Vec4b kDarkGreen(0, 128, 0, 255);
static const cv::Vec4b kBlue(0, 0, 255, 255);
static const cv::Vec4b kDarkBlue(0, 0, 128, 255);
static const cv::Vec4b kYellow(255, 255, 0, 255);

NSString * const kQuadSizeKey = @"quadSize";

#pragma mark -
#pragma mark LTContinuousSampler/Model
#pragma mark -

@interface DVNPipelineTestContinuousSampler : NSObject <LTContinuousSampler>
- (instancetype)initWithState:(NSUInteger)state;
@property (readonly, nonatomic) NSUInteger state;
@end

@implementation DVNPipelineTestContinuousSamplerModel

@synthesize state = _state;

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone __unused *)zone {
  return self;
}

- (id<LTContinuousSampler>)sampler {
  return [[DVNPipelineTestContinuousSampler alloc] initWithState:self.state];
}

- (BOOL)isEqual:(DVNPipelineTestContinuousSamplerModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[self class]]) {
    return NO;
  }

  return self.state == model.state;
}

@end

@implementation DVNPipelineTestContinuousSampler

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (id<LTSampleValues>)nextSamplesFromParameterizedObject:(__unused id)object
    constrainedToInterval:(__unused const lt::Interval<CGFloat> &)interval {
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithObject:kQuadSizeKey];
  cv::Mat1g matrix = !self.state ? (cv::Mat1g(1, 2) << 1.0 / 16, 1.0 / 8) :
      (cv::Mat1g(1, 2) << 1.0 / 4, 1.0 / 2);
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:matrix];
  std::vector<CGFloat> sampledParametricValues;
  if (!self.state) {
    sampledParametricValues = {0.0, 0.5};
  } else {
    sampledParametricValues = {1.0, 1.5};
  }
  _state++;
  return [[LTSampleValues alloc] initWithSampledParametricValues:sampledParametricValues
                                                         mapping:mapping];
}

- (id<LTContinuousSamplerModel>)currentModel {
  return [[DVNPipelineTestContinuousSamplerModel alloc] initWithState:self.state];
}

@end

#pragma mark -
#pragma mark DVNGeometryProvider/Model
#pragma mark -

@interface DVNPipelineTestGeometryProvider : NSObject <DVNGeometryProvider>
- (instancetype)initWithState:(NSUInteger)state;
@property (readonly, nonatomic) NSUInteger state;
@end

@implementation DVNPipelineTestGeometryProviderModel

@synthesize state = _state;

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone __unused *)zone {
  return self;
}

- (id<DVNGeometryProvider>)provider {
  return [[DVNPipelineTestGeometryProvider alloc] initWithState:self.state];
}

- (BOOL)isEqual:(DVNPipelineTestGeometryProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[self class]]) {
    return NO;
  }

  return self.state == model.state;
}

@end

@implementation DVNPipelineTestGeometryProvider

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(__unused BOOL)end {
  std::vector<lt::Quad> quads;
  std::vector<NSUInteger> indices;
  std::vector<CGFloat> quadSizes = [samples.mappingOfSampledValues valuesForKey:kQuadSizeKey];
  for (NSUInteger i = 0; i < quadSizes.size(); ++i) {
    CGFloat quadSize = quadSizes[i];
    quads.push_back(lt::Quad(CGRectMake(quadSize, quadSize, quadSize, quadSize)));
    indices.push_back(i);
  }
  _state++;
  return dvn::GeometryValues(quads, indices, samples);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNPipelineTestGeometryProviderModel alloc] initWithState:self.state];
}

@end

#pragma mark -
#pragma mark DVNTexCoordProvider/Model
#pragma mark -

@interface DVNPipelineTestTexCoordProvider : NSObject <DVNTexCoordProvider>
- (instancetype)initWithState:(NSUInteger)state;
@property (readonly, nonatomic) NSUInteger state;
@property (readonly, nonatomic) NSUInteger regionIndex;
@end

@implementation DVNPipelineTestTexCoordProviderModel

@synthesize state = _state;

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone __unused *)zone {
  return self;
}

- (id<DVNTexCoordProvider>)provider {
  return [[DVNPipelineTestTexCoordProvider alloc] initWithState:self.state];
}

- (BOOL)isEqual:(DVNPipelineTestTexCoordProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[self class]]) {
    return NO;
  }

  return self.state == model.state;
}

@end

@implementation DVNPipelineTestTexCoordProvider

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (std::vector<lt::Quad>)textureMapQuadsForQuads:(const std::vector<lt::Quad> &)quads {
  std::vector<lt::Quad> textureMapQuads;

  for (std::vector<lt::Quad>::size_type i = 0; i < quads.size(); ++i) {
    textureMapQuads.push_back(kTextureMapQuads[self.regionIndex]);
    _regionIndex = (self.regionIndex + 1) % 4;
  }

  _state++;
  return textureMapQuads;
}

- (id<DVNTexCoordProviderModel>)currentModel {
  return [[DVNPipelineTestTexCoordProviderModel alloc] initWithState:self.state];
}

@end

#pragma mark -
#pragma mark DVNAttributeProvider/Model
#pragma mark -

@interface DVNPipelineTestAttributeProvider : NSObject <DVNAttributeProvider>
- (instancetype)initWithState:(NSUInteger)state;
@property (readonly, nonatomic) NSUInteger state;
@end

@implementation DVNPipelineTestAttributeProviderModel

@synthesize state = _state;

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone __unused *)zone {
  return self;
}

- (id<DVNAttributeProvider>)provider {
  return [[DVNPipelineTestAttributeProvider alloc] initWithState:self.state];
}

- (LTAttributeData *)sampleAttributeData {
  return [[LTAttributeData alloc] initWithData:[NSData data]
                           inFormatOfGPUStruct:DVNPipelineTestGPUStruct()];
}

- (BOOL)isEqual:(DVNPipelineTestAttributeProviderModel *)model {
  if (self == model) {
    return YES;
  }

  if (![model isKindOfClass:[self class]]) {
    return NO;
  }

  return self.state == model.state;
}

@end

@implementation DVNPipelineTestAttributeProvider

- (instancetype)initWithState:(NSUInteger)state {
  if (self = [super init]) {
    _state = state;
  }
  return self;
}

- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)values {
  std::vector<float> attributeValues;
  std::vector<lt::Quad>::size_type size = values.quads().size();

  for (std::vector<lt::Quad>::size_type i = 0; i < size; ++i) {
    float value = 1.0 - (float)i / size;
    std::vector<float> valuesPerVertex = {value, value, value, value, value, value};
    attributeValues.insert(attributeValues.end(), valuesPerVertex.begin(), valuesPerVertex.end());
  }
  NSData *binaryData = [NSData dataWithBytes:&attributeValues[0]
                                      length:attributeValues.size() * sizeof(attributeValues[0])];
  _state++;
  return [[LTAttributeData alloc] initWithData:binaryData
                           inFormatOfGPUStruct:DVNPipelineTestGPUStruct()];;
}

- (id<DVNAttributeProviderModel>)currentModel {
  return [[DVNPipelineTestAttributeProviderModel alloc] initWithState:self.state];
}

@end

DVNPipelineConfiguration *DVNTestPipelineConfiguration() {
  DVNPipelineTestContinuousSamplerModel *samplerModel =
      [[DVNPipelineTestContinuousSamplerModel alloc] init];

  DVNPipelineTestGeometryProviderModel *geometryProviderModel =
      [[DVNPipelineTestGeometryProviderModel alloc] init];

  DVNPipelineTestTexCoordProviderModel *texCoordProviderModel =
      [[DVNPipelineTestTexCoordProviderModel alloc] init];

  DVNPipelineTestAttributeProviderModel *attributeProviderModel =
      [[DVNPipelineTestAttributeProviderModel alloc] init];

  LTTexture *texture = [LTTexture textureWithImage:DVNTestTextureMappingMatrix()];
  texture.magFilterInterpolation = LTTextureInterpolationNearest;
  texture.minFilterInterpolation = LTTextureInterpolationNearest;

  DVNTextureMappingStageConfiguration *textureConfiguration =
      [[DVNTextureMappingStageConfiguration alloc]
       initWithTexCoordProviderModel:texCoordProviderModel texture:texture];

  DVNAttributeStageConfiguration *attributeConfiguration =
      [[DVNAttributeStageConfiguration alloc]
       initWithAttributeProviderModels:@[attributeProviderModel]];

  DVNRenderStageConfiguration *renderConfiguration =
      [[DVNRenderStageConfiguration alloc] initWithVertexSource:[DVNTestShaderVsh source]
                                                 fragmentSource:[DVNTestShaderFsh source]];

  return [[DVNPipelineConfiguration alloc] initWithSamplingStageConfiguration:samplerModel
                                                   geometryStageConfiguration:geometryProviderModel
                                             textureMappingStageConfiguration:textureConfiguration
                                                  attributeStageConfiguration:attributeConfiguration
                                                     renderStageConfiguration:renderConfiguration];
}

cv::Mat4b DVNTestTextureMappingMatrix() {
  return (cv::Mat4b(2, 2) << kRed, kGreen, kBlue, kYellow);
}

cv::Mat4b DVNTestSingleProcessResult() {
  cv::Mat4b image(16, 16, kWhite);
  image(cv::Rect(1, 1, 1, 1)).setTo(kRed);
  image(cv::Rect(2, 2, 2, 2)).setTo(kDarkGreen);
  return image;
}

cv::Mat4b DVNTestConsecutiveProcessResult() {
  cv::Mat4b image(16, 16, kWhite);
  image(cv::Rect(1, 1, 1, 1)).setTo(kRed);
  image(cv::Rect(2, 2, 2, 2)).setTo(kDarkGreen);
  image(cv::Rect(4, 4, 4, 4)).setTo(kYellow);
  image(cv::Rect(8, 8, 8, 8)).setTo(kDarkBlue);
  return image;
}
