// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelVersion+TestBrushModel.h"

#import "DVNBrushModel+Deserialization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNBrushModelVersion (TestBrushModel)

#pragma mark -
#pragma mark Public API
#pragma mark -

- (NSDictionary *)JSONDictionaryOfTestBrushModel {
  return [self brushModelJSONDictionaryFromFileWithName:[self testFileName]];
}

- (DVNBrushModel *)testBrushModel {
  return [MTLJSONAdapter modelOfClass:[self classOfBrushModel]
                   fromJSONDictionary:[self JSONDictionaryOfTestBrushModel] error:nil];
}

#pragma mark -
#pragma mark Auxiliary Class Methods
#pragma mark -

- (NSString *)testFileName {
  switch (self.value) {
    case DVNBrushModelVersionV1:
      return @"DVNTestBrushModelV1";
  }
}

- (NSDictionary *)brushModelJSONDictionaryFromFileWithName:(NSString *)name {
  NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
}

@end

NS_ASSUME_NONNULL_END
