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

/// File extension of \c 3 chars for the compression format.
///
/// @note File extension is forced to be of \c 3 chars due to a bug in the MAC photos application
/// which doesn't behave well when trying to import an image file with longer extensions. See open
/// radar problem 29659566 for more information.
@property (readonly, nonatomic) NSString *fileExtension;

/// Mime type for the compression format.
@property (readonly, nonatomic) NSString *mimeType;

/// UTI of the compressed output.
@property (readonly, nonatomic) NSString *UTI;

@end

NS_ASSUME_NONNULL_END
