// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNBrushModel, DVNBrushRenderTargetInformation;

/// Value object consisting of a \c DVNBrushModel object and a \c DVNBrushRenderTargetInformation
/// object.
@interface DVNBrushRenderModel : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given \c brushModel and \c renderTargetInfo.
+ (instancetype)instanceWithBrushModel:(DVNBrushModel *)brushModel
                      renderTargetInfo:(DVNBrushRenderTargetInformation *)renderTargetInfo;

/// Brush model provided upon initialization.
@property (readonly, nonatomic) DVNBrushModel *brushModel;

/// Information about the render target provided upon initialization.
@property (readonly, nonatomic) DVNBrushRenderTargetInformation *renderTargetInfo;

@end

NS_ASSUME_NONNULL_END
