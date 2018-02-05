// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

#import "NSScanner+LTEngine.h"

template <typename T>
lt::Interval<T> LTIntervalFromString(NSString *string,
                                     std::pair<BOOL, T> (^scan)(NSScanner *scanner)) {
  NSScanner *scanner = [NSScanner scannerWithString:string];
  typename lt::Interval<T>::EndpointInclusion infInclusion;

  if ([scanner scanString:@"(" intoString:nil]) {
    infInclusion = lt::Interval<T>::EndpointInclusion::Open;
  } else if ([scanner scanString:@"[" intoString:nil]) {
    infInclusion = lt::Interval<T>::EndpointInclusion::Closed;
  } else {
    return lt::Interval<T>();
  }

  std::pair<BOOL, T> scanResult = scan(scanner);

  if (!scanResult.first) {
    return lt::Interval<T>();
  }

  T inf = scanResult.second;

  if (![scanner scanString:@"," intoString:nil]) {
    return lt::Interval<T>();
  }

  scanResult = scan(scanner);

  if (!scanResult.first) {
    return lt::Interval<T>();
  }

  T sup = scanResult.second;

  typename lt::Interval<T>::EndpointInclusion supInclusion;

  if ([scanner scanString:@")" intoString:nil]) { \
    supInclusion = lt::Interval<T>::EndpointInclusion::Open;
  } else if ([scanner scanString:@"]" intoString:nil]) {
    supInclusion = lt::Interval<T>::EndpointInclusion::Closed;
  } else {
    return lt::Interval<T>();
  }

  return lt::Interval<T>({inf, sup}, infInclusion, supInclusion);
}

lt::Interval<CGFloat> LTCGFloatIntervalFromString(NSString *string) {
  std::pair<BOOL, CGFloat> (^scan)(NSScanner *) = ^std::pair<BOOL, CGFloat>(NSScanner *scanner) {
#if CGFLOAT_IS_DOUBLE
    double value;
    BOOL success = [scanner scanDouble:&value];
#else
    float value;
    BOOL success = [scanner scanFloat:&value];
#endif
    return {success, value};
  };
  return LTIntervalFromString(string, scan);
}

lt::Interval<NSInteger> LTNSIntegerIntervalFromString(NSString *string) {
  std::pair<BOOL, NSInteger> (^scan)(NSScanner *) =
      ^std::pair<BOOL, NSInteger>(NSScanner *scanner) {
    NSInteger value;
    BOOL success = [scanner scanInteger:&value];
    return {success, value};
  };
  return LTIntervalFromString(string, scan);
}

lt::Interval<NSUInteger> LTNSUIntegerIntervalFromString(NSString *string) {
  std::pair<BOOL, NSUInteger> (^scan)(NSScanner *) =
      ^std::pair<BOOL, NSUInteger>(NSScanner *scanner) {
    NSUInteger value;
    BOOL success = [scanner lt_scanNSUInteger:&value];
    return {success, value};
  };
  return LTIntervalFromString(string, scan);
}
