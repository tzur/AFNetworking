// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

namespace pnk {

/// Loads from \c tensorURL a half float tensor with size \c tensorSize represented in the order
/// <tt>[height, width, channels]</tt>. Tensor is expected to be compressed using LZFSE. Returns
/// the tensor as a matrix with the proper dimensions and channel number. If an error occurred, an
/// empty matrix is returned and \c error is populated with \c LTErrorCodeFileReadFailed if the file
/// at \c tensorURL could not be read properly, \c LTErrorCodeObjectCreationFailed if the underlying
/// serialized tensor is invalid or \c LTErrorCodeCompressionFailed if decompressing the serialized
/// tensor has failed.
cv::Mat loadHalfTensor(NSURL *tensorURL, MTLSize tensorSize, NSError **error);

} // namespace pnk

NS_ASSUME_NONNULL_END
