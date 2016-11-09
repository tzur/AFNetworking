// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// For the EXIF standard dpecifications, see the following references:
/// @see http://sylvana.net/jpegcrop/exif_orientation.html
///
/// @see http://www.exif.org/Exif2-2.PDF page 18.

/// Returns the number of 90 degree rotations required to bring an image with \c orientation to an
/// upright orientation.
///
/// @note To make sure that the image is also left-side left the user should use
/// \c CAMHorizontalMirroringForOrientations to determine if the upright image is horizontally
/// mirrored and should be flipped.
int CAMClockwiseRotationsForExifOrientation(int orientation);

/// Returns \c YES if an image with \c orientation is horizontally flipped.
BOOL CAMIsExifOrientationMirrored(int orientation);

/// Returns \c YES if both \c first and \c second orientations have the same horizontal flipping.
BOOL CAMEqualMirroringForExifOrientations(int first, int second);

/// Returns \c YES if an image with \c orientation is in landscape orientation.
BOOL CAMIsExifOrientationLandscape(int orientation);

NS_ASSUME_NONNULL_END
