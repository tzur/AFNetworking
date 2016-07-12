// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Available compression types.
LTEnumDeclare(NSUInteger, LTCompressionType,
  LTCompressionTypeJPEG,
  LTCompressionTypePNG,
  LTCompressionTypeTIFF
);

/// Category providing properties for an \c LTCompressionType enum value.
@interface LTCompressionType (Properties)

/// File extention for the compression type.
@property (readonly, nonatomic) NSString *fileExtention;

/// Mime type for the compression type.
@property (readonly, nonatomic) NSString *mimeType;

/// UTI of the compressed output.
@property (readonly, nonatomic) NSString *UTI;

@end

NS_ASSUME_NONNULL_END
