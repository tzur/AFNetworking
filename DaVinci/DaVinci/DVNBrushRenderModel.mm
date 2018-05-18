// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderModel.h"

#import "DVNBrushRenderTargetInformation.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushRenderModel

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithBrushModel:(DVNBrushModel *)brushModel
                  renderTargetInfo:(DVNBrushRenderTargetInformation *)renderTargetInfo
                  conversionFactor:(CGFloat)conversionFactor {
  LTParameterAssert(brushModel);
  LTParameterAssert(renderTargetInfo);

  if (self = [super init]) {
    _brushModel = brushModel;
    _renderTargetInfo = renderTargetInfo;
    _conversionFactor = conversionFactor;
  }
  return self;
}

#pragma mark -
#pragma mark Factory Methods
#pragma mark -

+ (instancetype)instanceWithBrushModel:(DVNBrushModel *)brushModel
                      renderTargetInfo:(DVNBrushRenderTargetInformation *)renderTargetInfo
                      conversionFactor:(CGFloat)conversionFactor {
  return [[self alloc] initWithBrushModel:brushModel renderTargetInfo:renderTargetInfo
                         conversionFactor:conversionFactor];
}

+ (instancetype)instanceWithBrushModel:(DVNBrushModel *)brushModel
                  renderTargetLocation:(lt::Quad)location
          renderTargetHasSingleChannel:(BOOL)hasSingleChannel
        renderTargetIsNonPremultiplied:(BOOL)isNonPremultiplied
                      conversionFactor:(CGFloat)conversionFactor {
  return [[self alloc] initWithBrushModel:brushModel
                         renderTargetInfo:[DVNBrushRenderTargetInformation
                                           instanceWithRenderTargetLocation:location
                                           renderTargetHasSingleChannel:hasSingleChannel
                                           renderTargetIsNonPremultiplied:isNonPremultiplied]
                         conversionFactor:conversionFactor];
}

#pragma mark -
#pragma mark Copying Methods
#pragma mark -

- (instancetype)copyWithBrushModel:(DVNBrushModel *)brushModel {
  return [[[self class] alloc] initWithBrushModel:brushModel renderTargetInfo:self.renderTargetInfo
                                 conversionFactor:self.conversionFactor];
}

@end

NS_ASSUME_NONNULL_END
