// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

/// Enumeration of error codes related to \c DVNBrushModel.
LTEnumDeclare(NSInteger, DVNBrushModelErrorCode,
  /// Code of an error occurring when no version string can be found in a serialized version of a
  /// \c DVNBrushModel.
  DVNBrushModelErrorCodeNoSerializedVersion,
  /// Code of an error occurring when no valid version can be computed from the version string found
  /// in a serialized version of a \c DVNBrushModel.
  DVNBrushModelErrorCodeNoValidVersion
);

NS_ASSUME_NONNULL_END
