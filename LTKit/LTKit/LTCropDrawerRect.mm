// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCropDrawerRect.h"

#import "LTCGExtensions.h"

LTCropDrawerRect::LTCropDrawerRect() : topLeft(0), topRight(0), bottomLeft(0), bottomRight(0) {}

LTCropDrawerRect::LTCropDrawerRect(const LTVector2 &topLeft, const LTVector2 &topRight,
                                   const LTVector2 &bottomLeft, const LTVector2 &bottomRight) :
  topLeft(topLeft), topRight(topRight), bottomLeft(bottomLeft), bottomRight(bottomRight) {}

LTCropDrawerRect::LTCropDrawerRect(CGRect rect) :
  topLeft(rect.origin),
  topRight(rect.origin + CGSizeMake(rect.size.width, 0)),
  bottomLeft(rect.origin + CGSizeMake(0, rect.size.height)),
  bottomRight(rect.origin + rect.size) {}

LTCropDrawerRect::operator CGRect() {
  return CGRectStandardize(CGRectFromPoints(topLeft, bottomRight));
}

LTCropDrawerRect &LTCropDrawerRect::operator*=(const LTVector2 &rhs) {
  topLeft *= rhs;
  topRight *= rhs;
  bottomLeft *= rhs;
  bottomRight *= rhs;
  return *this;
}

LTCropDrawerRect &LTCropDrawerRect::operator/=(const LTVector2 &rhs) {
  topLeft /= rhs;
  topRight /= rhs;
  bottomLeft /= rhs;
  bottomRight /= rhs;
  return *this;
}
