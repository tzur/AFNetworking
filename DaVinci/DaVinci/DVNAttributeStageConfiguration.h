// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol DVNAttributeProviderModel;

/// Value class representing the configuration of the attribute stage of the \c DVNPipeline.
@interface DVNAttributeStageConfiguration : NSObject

/// Initializes with an empty collection of \c models.
- (instancetype)init;

/// Initializes with the given attribute \c models of attribute providers.
- (instancetype)initWithAttributeProviderModels:(NSArray<id<DVNAttributeProviderModel>> *)models
    NS_DESIGNATED_INITIALIZER;

/// Models of the vertex shader attribute providers used in the attribute stage of the
/// \c DVNPipeline.
@property (readonly, nonatomic) NSArray<id<DVNAttributeProviderModel>> *models;

@end

NS_ASSUME_NONNULL_END
