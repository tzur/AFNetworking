// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Available compression formats.
LTEnumDeclare(NSUInteger, LTCompressionFormat,
  LTCompressionFormatJPEG,
  LTCompressionFormatPNG,
  LTCompressionFormatTIFF
);

/// Category providing properties for an \c LTCompressionFormat enum value.
@interface LTCompressionFormat (Properties)

/// File extention for the compression format.
@property (readonly, nonatomic) NSString *fileExtention;

/// Mime type for the compression format.
@property (readonly, nonatomic) NSString *mimeType;

/// UTI of the compressed output.
@property (readonly, nonatomic) NSString *UTI;

@end

NS_ASSUME_NONNULL_END
