// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "WFImageProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provider of images drawn by PaintCode modules.
///
/// Supports the following parameters:
///
/// \c width - width of the image, in points. Required.
///
/// \c height - height of the image, in points. Required.
///
/// \c color - hexadecimal color used to draw the image.
///
/// \c lineWidth - line width used to draw the image, in points.
///
/// Example URLs:
///
/// <tt>
/// paintcode://Module/Icon?width=20&height=10
///
/// paintcode://Module/Icon?width=20&height=10&color=deadbeef&lineWidth=1
/// </tt>
///
/// Host component specifies the module's class name and path (with query) specifies the selector to
/// invoke on the module along with the values. In the example above, the following selectors are
/// called to perform the actual drawing:
///
/// <code>
/// +[Module drawIconWithFrame:]
///
/// +[Module drawIconWithFrame:color:lineWidth:]
/// </code>
///
/// The selector is constructed by fitting the assets name (path of the URL) into draw<>WithFrame:
/// template. If optional parameters are present, their names are appended. The order of all
/// optional parameters is hard-coded, and matches their order as given above.
///
/// @note Points are defined using the device's main screen scale factor, which is also the \c scale
/// of the returned \c UIImage.
///
/// @note Unsupported URL queries cause errors.
@interface WFPaintCodeImageProvider : NSObject <WFImageProvider>
@end

NS_ASSUME_NONNULL_END
