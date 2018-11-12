// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "EXPMatchers+beCloseToMatPSNR.h"

#import <Expecta/NSValue+Expecta.h>
#import <LTEngine/LTOpenCVExtensions.h>

#import "LTTestUtils+LTEngine.h"

static double LTPSNRScore(const cv::Mat &first, const cv::Mat &second) {
  cv::Mat error;
  cv::Mat firstFloat, secondFloat;
  LTConvertMat(first, &firstFloat, CV_32FC(first.channels()));
  LTConvertMat(second, &secondFloat, CV_32FC(second.channels()));

  double sse = cv::norm(firstFloat, secondFloat, cv::NORM_L2SQR);

  if (sse <= 1e-10) {
    return INFINITY;
  }

  double mse = sse / (double)(first.total() * first.channels());
  return -10.0 * log10(mse);
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

EXPMatcherImplementationBegin(_beCloseToMatPSNR, (NSValue *expected, id psnr)) {
  __block NSString *prerequisiteErrorMessage;
  __block double actualPSNR;

  prerequisite(^BOOL(id actual) {
    if (strcmp([expected _EXP_objCType], @encode(cv::Mat))) {
      prerequisiteErrorMessage = @"Expected value is not cv::Mat";
    } else if (![psnr isKindOfClass:[NSNumber class]]) {
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
      double minPSNR = [psnr doubleValue];
      actualPSNR = LTPSNRScore(expectedMat, actualMat);
      return actualPSNR >= minPSNR;
    }
  });

  failureMessageForTo(^NSString *(NSValue *actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTAttachMatricesToTest(expected.matValue, actual.matValue);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    return [NSString stringWithFormat:@"Expected PSNR %g to be greater than or equal to %g",
            actualPSNR, [psnr doubleValue]];
  });

  failureMessageForNotTo(^NSString *(NSValue *actual) {
    if ([expected matValue].dims == 2 && [actual matValue].dims == 2) {
      LTAttachMatricesToTest(expected.matValue, actual.matValue);
    }

    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    return [NSString stringWithFormat:@"Expected PSNR %g to be less than %g", actualPSNR,
            [psnr doubleValue]];
  });
}

EXPMatcherImplementationEnd
