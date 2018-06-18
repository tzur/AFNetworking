// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "EXPMatchers+beCloseToMatNormalizedHamming.h"

#import <Expecta/NSValue+Expecta.h>
#import <LTEngine/LTOpenCVExtensions.h>

static double LTNormalizedHammingDistance(const cv::Mat &first, const cv::Mat &second) {
  cv::Mat equalityMask = (first == second);

  std::vector<cv::Mat> equalityMaskPerChannel;
  cv::split(equalityMask, equalityMaskPerChannel);

  cv::Mat1b allChannelsMatch(equalityMask.rows, equalityMask.cols, 0xff);
  for (auto channelMatch: equalityMaskPerChannel) {
    allChannelsMatch &= channelMatch;
  }

  double matches = (double)cv::countNonZero(allChannelsMatch);
  double total = (double)allChannelsMatch.total();

  return 1.0 - matches / total;
}

EXPMatcherImplementationBegin(_beCloseToMatNormalizedHamming, (NSValue *expected, id within)) {
  __block NSString *prerequisiteErrorMessage;
  __block double actualNormalizedHammingDistance;

  prerequisite(^BOOL{
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
    }
    return !prerequisiteErrorMessage;
  });

  match(^BOOL{
    // Compare pointers.
    if ([actual isEqual:expected]) {
      return YES;
    } else {
      const cv::Mat expectedMat([expected matValue]);
      const cv::Mat actualMat([actual matValue]);
      double maxNormalizedHammingDistance = [within doubleValue];
      actualNormalizedHammingDistance = LTNormalizedHammingDistance(expectedMat, actualMat);
      return actualNormalizedHammingDistance <= maxNormalizedHammingDistance;
    }
  });

  failureMessageForTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    return [NSString stringWithFormat:@"Expected Normalized Hamming Distance %g to be less than or "
            "equal to %g", actualNormalizedHammingDistance, [within doubleValue]];
  });

  failureMessageForNotTo(^NSString *{
    if (prerequisiteErrorMessage) {
      return prerequisiteErrorMessage;
    }

    return [NSString stringWithFormat:@"Expected Normalized Hamming Distance %g to be greater than "
            "%g", actualNormalizedHammingDistance, [within doubleValue]];
  });
}

EXPMatcherImplementationEnd
