// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "WHSFakeDatabase.h"

NS_ASSUME_NONNULL_BEGIN

@interface FMDatabase (Tests)

- (BOOL)executeUpdate:(NSString *)sql error:(NSError **)outErr
 withArgumentsInArray:(nullable NSArray *)arrayArgs
         orDictionary:(nullable NSDictionary *)dictionaryArgs orVAList:(va_list)args;

- (nullable FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arrayArgs
                          orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args;

@end

@implementation WHSFakeDatabase

- (BOOL)executeUpdate:(NSString *)sql error:(NSError *__autoreleasing *)outErr
 withArgumentsInArray:(nullable NSArray *)arrayArgs
         orDictionary:(nullable NSDictionary *)dictionaryArgs orVAList:(va_list)args {
  if (self.updateError) {
    self.lastError = nn(self.updateError);
    if (*outErr) {
      *outErr = self.updateError;
    }
    return NO;
  }

  return [super executeUpdate:sql error:outErr withArgumentsInArray:arrayArgs
                 orDictionary:dictionaryArgs orVAList:args];
}

- (nullable FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arrayArgs
                          orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args {
  if (self.queryError) {
    self.lastError = nn(self.queryError);
    return nil;
  }

  return [super executeQuery:sql withArgumentsInArray:arrayArgs orDictionary:dictionaryArgs
                    orVAList:args];
}

@end

NS_ASSUME_NONNULL_END
