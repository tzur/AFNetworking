// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderModel.h"

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

+ (instancetype)instanceWithBrushModel:(DVNBrushModel *)brushModel
                      renderTargetInfo:(DVNBrushRenderTargetInformation *)renderTargetInfo
                      conversionFactor:(CGFloat)conversionFactor {
  return [[self alloc] initWithBrushModel:brushModel renderTargetInfo:renderTargetInfo
                         conversionFactor:conversionFactor];
}

@end

NS_ASSUME_NONNULL_END
