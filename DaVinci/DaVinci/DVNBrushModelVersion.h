// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Enumeration of the existing brush versions provided by DaVinci.
LTEnumDeclare(NSUInteger, DVNBrushModelVersion,
  DVNBrushModelVersionV1
);

/// Category augmenting \c DVNBrushModelVersion objects with additional convenience methods.
@interface DVNBrushModelVersion (DaVinci)

/// Returns the class of the \c DVNBrushModel instance corresponding to the \c value of the
/// receiver.
- (Class)classOfBrushModel;

@end

NS_ASSUME_NONNULL_END
