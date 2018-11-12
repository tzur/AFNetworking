// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "EXPMatchers+beCloseToMatIntersectionOverUnion.h"

#import <Expecta/NSValue+Expecta.h>

static double PNKIntersectionOverUnion(const cv::Mat1b &first, const cv::Mat1b &second) {
  cv::Mat1b firstMask = first > 127;
  cv::Mat1b secondMask = second > 127;

  cv::Mat1b intersectionMask = firstMask & secondMask;
  cv::Mat1b unionMask = firstMask | secondMask;

  return cv::sum(intersectionMask)[0] / (1.e-6 + cv::sum(unionMask)[0]);
}

static void LTAttachMatricesToTest(const cv::Mat &expected, const cv::Mat &actual) {
  std::vector<std::pair<NSString *, UIImage *>> attachments;

  UIImage * _Nullable expectedImage =
      LTUIImageWithCompatibleMat(LTUIImageCompatibleMatWithMat(expected));
  if (expectedImage) {
    attachments.push_back({@"expected", expectedImage});
  }

  UIImage * _Nullable actualImage =
      LTUIImageWithCompatibleMat(LTUIImageCompatibleMatWithMat(actual));
  if (actualImage) {
    attachments.push_back({@"actual", actualImage});
  }

  if (attachments.size()) {
    LTAttachImagesToCurrentTest(@"images", attachments);
  }
}

EXPMatcherImplementationBegin(_beCloseToMatIntersectionOverUnion, (NSValue *expected, id within)) {
  __block NSString *prerequisiteErrorMessage;
  __block double intersectionOverUnion;

  prerequisite(^BOOL(id actual) {
    if (strcmp([expected _EXP_objCType], @encode(cv::Mat))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Mat";
    } else if (![within isKindOfClass:[NSNumber class]]) {
      prerequisiteErrorMessage = @"Given range is not NSNumber";
    } else if (![expected matValue].data) {
      prerequisiteErrorMessage = @"Expected mat data is null";
    } else if (![actual matValue].data) {
      prerequisiteErrorMessage = @"Actual mat data is null";
    } else if ([expected matValue].rows != [actual matValue].rows) {
      prerequisiteErrorMessage = @"Actual mat and expected mat row counts do not match";
    } else if ([expected matValue].cols != [actual matValue].cols) {
      prerequisiteErrorMessage = @"Actual mat and expected mat column counts do not match";
    } else if ([expected matValue].channels() != [actual matValue].channels()) {
      prerequisiteErrorMessage = @"Actual mat and expected mat channels counts do not match";
    } else if ([expected matValue].depth() != [actual matValue].depth()) {
      prerequisiteErrorMessage = @"Actual mat and expected mat depth does not match";
    } else if ([actual matValue].type() != CV_8UC1) {
      prerequisiteErrorMessage = @"Actual mat is not a one-channel uchar matrix";
    }
    return !prerequisiteErrorMessage;
  });

  match(^BOOL(id actual) {
    // Compare pointers.
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      const cv::Mat expectedMat([expected matValue]);
      const cv::Mat actualMat([actual matValue]);
      auto acceptableDeviation = [within doubleValue];
      intersectionOverUnion = PNKIntersectionOverUnion(expectedMat, actualMat);
      return intersectionOverUnion >= 1. - acceptableDeviation;
    }
  });

  failureMessageForTo(^NSString *(id actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTAttachMatricesToTest([expected matValue], [actual matValue]);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    return [NSString stringWithFormat:@"Expected IOU %g to be greater than or equal to %g",
            intersectionOverUnion, 1 - [within doubleValue]];
  });

  failureMessageForNotTo(^NSString *(id actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTAttachMatricesToTest([expected matValue], [actual matValue]);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    return [NSString stringWithFormat:@"Expected IOU %g to be less than %g",
            intersectionOverUnion, 1 - [within doubleValue]];
  });
}

EXPMatcherImplementationEnd
