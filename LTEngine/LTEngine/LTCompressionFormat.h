// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Available compression formats.
LTEnumDeclare(NSUInteger, LTCompressionFormat,
  LTCompressionFormatJPEG,
  LTCompressionFormatPNG,
  LTCompressionFormatTIFF,
  LTCompressionFormatHEIC
);

/// Category providing properties for an \c LTCompressionFormat enum value.
@interface LTCompressionFormat (Properties)

/// File extension for the compression format.
@property (readonly, nonatomic) NSString *fileExtension;

/// Mime type for the compression format.
@property (readonly, nonatomic) NSString *mimeType;

/// UTI of the compressed output.
@property (readonly, nonatomic) NSString *UTI;

@end

/// Returns \c YES if current device supports the given compression \c format.
BOOL LTIsDeviceSupportsCompressionFormat(LTCompressionFormat *format);

NS_ASSUME_NONNULL_END
