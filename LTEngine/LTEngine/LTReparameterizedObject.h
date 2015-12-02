// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@class LTReparameterization;

/// Parameterized object constituted by another parameterized object and a reparameterization, both
/// provided upon initialization. The reparameterization is used in order to project the intrinsic
/// parametric range of this object to the corresponding range of the parameterized object.
@interface LTReparameterizedObject<__covariant ObjectType:id<LTParameterizedObject>> : NSObject
    <LTParameterizedObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c parameterizedObject and the given \c reparameterization.
- (instancetype)initWithParameterizedObject:(ObjectType)parameterizedObject
                         reparameterization:(LTReparameterization *)reparameterization
    NS_DESIGNATED_INITIALIZER;

/// Parameterized object wrapped by this object.
@property (readonly, nonatomic) ObjectType parameterizedObject;

/// Reparameterization used to map the parameterization of this object to the parameterization of
/// the wrapped object.
@property (readonly, nonatomic) LTReparameterization *reparameterization;

@end

NS_ASSUME_NONNULL_END
