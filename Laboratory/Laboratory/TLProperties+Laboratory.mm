// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "TLProperties+Laboratory.h"

#import <LTKit/NSDictionary+Functional.h>

static auto const kBaselineVariantID = @"baseline";

NS_ASSUME_NONNULL_BEGIN

@implementation TLProperties (Laboratory)

- (NSDictionary<NSString *, NSString *> *)lab_runningExperimentsAndVariations {
  auto experimentAndVariations = [NSMutableDictionary<NSString *, NSString *> dictionary];
  for (NSDictionary *experimentInfo in self.experimentAndVariationNames) {
    NSString *value = experimentInfo[@"v"];
    experimentAndVariations[experimentInfo[@"e"]] =
        [value isEqual:kBaselineVariantID] ? @"Baseline" : value;
  }
  return [experimentAndVariations copy];
}

- (NSDictionary<NSString *, NSSet<NSString *> *> *)lab_allExperimentsAndVariations {
  auto allExperimentsAndVariations =
      [NSMutableDictionary<NSString *, NSSet<NSString *> *> dictionary];
  for (NSDictionary<NSString *, id> *experimentInfo in self.experiments) {
    auto variations = [NSMutableSet setWithObject:experimentInfo[kBaselineVariantID][@"name"]];
    for (NSDictionary *variantionInfo in experimentInfo[@"variations"]) {
      [variations addObject:variantionInfo[@"name"]];
    }

    allExperimentsAndVariations[experimentInfo[@"name"]] = variations;
  }
  return [allExperimentsAndVariations copy];
}

- (NSDictionary<NSString *, id> *)lab_dynamicVariables {
  auto _Nullable dynamicVariables = self.dynamicVariables;
  if (!dynamicVariables) {
    return nil;
  }

  auto filteredVariables = [NSMutableDictionary<NSString *, id> dictionary];
  [dynamicVariables enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *) {
    id _Nullable value = obj[@"value"];
    if (value) {
      filteredVariables[key] = value;
    }
  }];
  return filteredVariables;
}

- (nullable NSString *)lab_variationsIDForVariation:(NSString *)variation
                                       inExperiment:(NSString *)experiment {
  auto _Nullable experimentInfo = [self experimentInfoForExperiment:experiment];
  if (!experimentInfo) {
    return nil;
  }

  if ([variation isEqual:@"Baseline"]) {
    return kBaselineVariantID;
  }

  for (NSDictionary *variationInfo in experimentInfo[@"variations"]) {
    if ([variationInfo[@"name"] isEqual:variation]) {
      return variationInfo[@"_id"];
    }
  }
  return nil;
}

- (nullable NSDictionary *)experimentInfoForExperiment:(NSString *)experiment {
  for (NSDictionary<NSString *, id> *experimentInfo in self.experiments) {
    if ([experimentInfo[@"name"] isEqual:experiment]) {
      return experimentInfo;
    }
  }

  return nil;
}

- (nullable NSString *)lab_experimentIDForExperiment:(NSString *)experiment {
  return [self experimentInfoForExperiment:experiment][@"_id"];
}

@end

NS_ASSUME_NONNULL_END
