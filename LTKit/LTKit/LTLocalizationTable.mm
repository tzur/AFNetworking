// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LTLocalizationTable.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTLocalizationTable ()

/// Bundle that contains the localized strings table.
@property (readonly, nonatomic) NSBundle *bundle;

@end

@implementation LTLocalizationTable

- (instancetype)initWithBundle:(NSBundle *)bundle tableName:(NSString *)tableName {
  if (self = [super init]) {
    _bundle = bundle;
    _tableName = tableName;
  }
  return self;
}

- (NSString *)objectForKeyedSubscript:(NSString *)key {
  return [self.bundle localizedStringForKey:key value:nil table:self.tableName];
}

@end

NS_ASSUME_NONNULL_END
