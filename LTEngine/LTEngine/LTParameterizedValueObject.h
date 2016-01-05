// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by value objects that conform to the \c LTParameterizedObject
/// protocol. The protocol is not to be implemented by complex objects maintaining state.
@protocol LTParameterizedValueObject <LTParameterizedObject, NSCopying>
@end

NS_ASSUME_NONNULL_END
