// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNJitteredColorAttributeProviderModel.h"

#import <LTEngine/LTAttributeData.h>
#import <LTEngine/UIColor+Vector.h>
#import <LTKit/LTRandom.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVNJitteredColorAttributeProvider : NSObject <DVNAttributeProvider>

/// Initializes with the given \c model.
- (instancetype)initWithModel:(DVNJitteredColorAttributeProviderModel *)model;

/// Underlying provider model of this instance.
@property (readonly, nonatomic) DVNJitteredColorAttributeProviderModel *model;

/// Random object for sampling flow.
@property (readonly, nonatomic) LTRandom *random;

@end

@implementation DVNJitteredColorAttributeProvider

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithModel:(DVNJitteredColorAttributeProviderModel *)model {
  if (self = [super init]) {
    _random = [[LTRandom alloc] initWithState:model.randomState];
    _model = model;
  }
  return self;
}

#pragma mark -
#pragma mark DVNAttributeProvider
#pragma mark -

static DVNJitteredColorAttributeProviderStruct DVNColorStructFromVector(LTVector3 vector) {
  return DVNJitteredColorAttributeProviderStruct({
    .colorRed = (GLubyte)(vector.r() * 255),
    .colorGreen = (GLubyte)(vector.g() * 255),
    .colorBlue = (GLubyte)(vector.b() * 255)
  });
}

- (LTAttributeData *)attributeDataFromGeometryValues:(dvn::GeometryValues)geometryValues {
  std::vector<DVNJitteredColorAttributeProviderStruct> attributes;
  std::vector<lt::Quad>::size_type size = geometryValues.quads().size();
  attributes.reserve(size);
  BOOL hasJitter = self.model.brightnessJitter != 0 || self.model.hueJitter != 0 ||
      self.model.saturationJitter != 0;

  for (NSUInteger i = 0; i < size; ++i) {
    DVNJitteredColorAttributeProviderStruct values =
        DVNColorStructFromVector(hasJitter ?
                                 [self jitteredColorFromVector:self.model.baseColor] :
                                 self.model.baseColor);
    attributes.insert(attributes.end(), 6, {values});
  }
  NSData *data = [NSData dataWithBytes:attributes.data()
                                length:attributes.size() * sizeof(attributes[0])];
  return [[LTAttributeData alloc] initWithData:data
                           inFormatOfGPUStruct:[self.model sampleAttributeData].gpuStruct];
}

- (LTVector3)jitteredColorFromVector:(LTVector3)vector {
  LTVector3 hsvVector = vector.rgbToHsv();
  CGFloat hue = [self.random randomDoubleBetweenMin:hsvVector.r() - self.model.hueJitter
                                                max:hsvVector.r() + self.model.hueJitter];
  CGFloat saturation =
      [self.random randomDoubleBetweenMin:hsvVector.g() - self.model.saturationJitter
                                      max:hsvVector.g() + self.model.saturationJitter];
  CGFloat brightness =
      [self.random randomDoubleBetweenMin:hsvVector.b() - self.model.brightnessJitter
                                      max:hsvVector.b() + self.model.brightnessJitter];
  return std::clamp(LTVector3(hue, saturation, brightness).hsvToRgb(), LTVector3::zeros(),
                    LTVector3::ones());
}

- (id<DVNAttributeProviderModel>)currentModel {
  return [[DVNJitteredColorAttributeProviderModel alloc]
          initWithBaseColor:self.model.baseColor brightnessJitter:self.model.brightnessJitter
          hueJitter:self.model.hueJitter saturationJitter:self.model.saturationJitter
          randomState:self.random.engineState];
}

@end

LTGPUStructImplementNormalized(DVNJitteredColorAttributeProviderStruct,
                               GLubyte, colorRed, YES,
                               GLubyte, colorGreen, YES,
                               GLubyte, colorBlue, YES);

@implementation DVNJitteredColorAttributeProviderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithBaseColor:(LTVector3)baseColor brightnessJitter:(CGFloat)brightnessJitter
                        hueJitter:(CGFloat)hueJitter saturationJitter:(CGFloat)saturationJitter
                      randomState:(LTRandomState *)randomState {
  LTParameterAssert(brightnessJitter >= 0 && brightnessJitter <= 1,
                    @"Brightness jitter must be in [0, 1] range");
  LTParameterAssert(hueJitter >= 0 && hueJitter <= 1, @"Hue jitter must be in [0, 1] range");
  LTParameterAssert(saturationJitter >= 0 && saturationJitter <= 1,
                    @"Saturation jitter must be in [0, 1] range");

  if (self = [super init]) {
    _randomState = randomState;
    _baseColor = baseColor;
    _brightnessJitter = brightnessJitter;
    _hueJitter = hueJitter;
    _saturationJitter = saturationJitter;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(DVNJitteredColorAttributeProviderModel *)model {
  if (self == model) {
    return YES;
  }
  if (![model isKindOfClass:[DVNJitteredColorAttributeProviderModel class]]) {
    return NO;
  }
  return model.baseColor == self.baseColor && model.brightnessJitter == self.brightnessJitter &&
      model.hueJitter == self.hueJitter && model.saturationJitter == self.saturationJitter &&
      [self.randomState isEqual:model.randomState];
}

- (NSUInteger)hash {
  size_t seed = 0;
  lt::hash_combine(seed, self.baseColor.r());
  lt::hash_combine(seed, self.baseColor.g());
  lt::hash_combine(seed, self.baseColor.b());
  lt::hash_combine(seed, self.brightnessJitter);
  lt::hash_combine(seed, self.hueJitter);
  lt::hash_combine(seed, self.saturationJitter);
  lt::hash_combine(seed, [self.randomState hash]);
  return seed;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark DVNAttributeProviderModel
#pragma mark -

- (id<DVNAttributeProvider>)provider {
  return [[DVNJitteredColorAttributeProvider alloc] initWithModel:self];
}

- (LTAttributeData *)sampleAttributeData {
  static LTAttributeData *sampleAttributeData;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    LTGPUStruct *transformStruct = [[LTGPUStructRegistry sharedInstance]
                                    structForName:@"DVNJitteredColorAttributeProviderStruct"];
    sampleAttributeData = [[LTAttributeData alloc] initWithData:[NSData data]
                                            inFormatOfGPUStruct:transformStruct];
  });
  return sampleAttributeData;
}

@end

NS_ASSUME_NONNULL_END
