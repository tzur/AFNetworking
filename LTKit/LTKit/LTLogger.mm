// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

#import "NSDate+Formatting.h"

NS_ASSUME_NONNULL_BEGIN

NSString *NSStringFromLTLogLevel(LTLogLevel logLevel) {
  switch (logLevel) {
    case LTLogLevelDebug:
      return @"DEBUG";
    case LTLogLevelInfo:
      return @"INFO";
    case LTLogLevelWarning:
      return @"WARNING";
    case LTLogLevelError:
      return @"ERROR";
  }
}

#pragma mark -
#pragma mark LTLogger
#pragma mark -

@interface LTLogger ()

/// Maps between a \c logLevel to a set of targets that log that log level.
@property (readonly, nonatomic) NSMutableArray<NSMutableSet<id<LTLoggerTarget>> *> *targets;

@end

@implementation LTLogger

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    @synchronized(self) {
      NSUInteger count = (NSUInteger)LTLogLevelError + 1;
      _targets = [NSMutableArray arrayWithCapacity:count];
      for (NSUInteger i = 0; i < count; ++i) {
        self.targets[i] = [NSMutableSet set];
      }
    }
  }
  return self;
}

+ (LTLogger *)sharedLogger {
  static LTLogger *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTLogger alloc] init];
  });
  return instance;
}

#pragma mark -
#pragma mark Expression formatter
#pragma mark -

+ (nullable NSString *)descriptionFromTypeCode:(const char *)typeCode andValue:(void *)value {
#define MATCH_TYPE_AND_HANDLER(typeToMatch, handler) \
  if (strcmp(typeCode, @encode(typeToMatch)) == 0) { \
    return (handler)(*(typeToMatch *)value); \
  }

#define MATCH_TYPE_AND_FORMAT_STRING(typeToMatch, formatString) \
  if (strcmp(typeCode, @encode(typeToMatch)) == 0) { \
    return [NSString stringWithFormat:(formatString), (*(typeToMatch *)value)]; \
  }

  MATCH_TYPE_AND_HANDLER(CGPoint, NSStringFromCGPoint);
  MATCH_TYPE_AND_HANDLER(CGSize, NSStringFromCGSize);
  MATCH_TYPE_AND_HANDLER(CGRect, NSStringFromCGRect);
  MATCH_TYPE_AND_HANDLER(CGAffineTransform, NSStringFromCGAffineTransform);
  MATCH_TYPE_AND_HANDLER(NSRange, NSStringFromRange);
  MATCH_TYPE_AND_HANDLER(Class, NSStringFromClass);
  MATCH_TYPE_AND_HANDLER(SEL, NSStringFromSelector);
  MATCH_TYPE_AND_HANDLER(BOOL, stringFromBoolOrChar);
  MATCH_TYPE_AND_HANDLER(NSDecimal, stringFromNSDecimalWithCurrentLocale);
  MATCH_TYPE_AND_HANDLER(UIEdgeInsets, NSStringFromUIEdgeInsets);
  MATCH_TYPE_AND_HANDLER(UIOffset, NSStringFromUIOffset);
  MATCH_TYPE_AND_HANDLER(GLKMatrix2, NSStringFromGLKMatrix2);
  MATCH_TYPE_AND_HANDLER(GLKMatrix3, NSStringFromGLKMatrix3);
  MATCH_TYPE_AND_HANDLER(GLKMatrix4, NSStringFromGLKMatrix4);
  MATCH_TYPE_AND_HANDLER(GLKQuaternion, NSStringFromGLKQuaternion);
  MATCH_TYPE_AND_HANDLER(GLKVector2, NSStringFromGLKVector2);
  MATCH_TYPE_AND_HANDLER(GLKVector3, NSStringFromGLKVector3);
  MATCH_TYPE_AND_HANDLER(GLKVector4, NSStringFromGLKVector4);

  MATCH_TYPE_AND_FORMAT_STRING(CFStringRef, @"%@");
  MATCH_TYPE_AND_FORMAT_STRING(CFArrayRef, @"%@");
  MATCH_TYPE_AND_FORMAT_STRING(long long, @"%lld");
  MATCH_TYPE_AND_FORMAT_STRING(unsigned long long, @"%llu");
  MATCH_TYPE_AND_FORMAT_STRING(float, @"%f");
  MATCH_TYPE_AND_FORMAT_STRING(double, @"%f");
  MATCH_TYPE_AND_FORMAT_STRING(short, @"%hi");
  MATCH_TYPE_AND_FORMAT_STRING(unsigned short, @"%hu");
  MATCH_TYPE_AND_FORMAT_STRING(int, @"%i");
  MATCH_TYPE_AND_FORMAT_STRING(unsigned, @"%u");
  MATCH_TYPE_AND_FORMAT_STRING(long, @"%li");
  MATCH_TYPE_AND_FORMAT_STRING(long double, @"%Lf");
  MATCH_TYPE_AND_FORMAT_STRING(char *, @"%s");
  MATCH_TYPE_AND_FORMAT_STRING(const char *, @"%s");
#if __has_feature(objc_arc)
  MATCH_TYPE_AND_FORMAT_STRING(__unsafe_unretained id, @"%@");
#else
  MATCH_TYPE_AND_FORMAT_STRING(id, @"%@");
#endif

  if ([[self class] isCharArray:typeCode]) {
    return [NSString stringWithFormat:@"%s", (char *)value];
  }

  MATCH_TYPE_AND_FORMAT_STRING(void *, @"(void *)%p");

#undef MATCH_TYPE_AND_HANDLER
#undef MATCH_TYPE_AND_FORMAT_STRING

  return nil;
}

+ (BOOL)isCharArray:(const char *)typeCode {
  LTParameterAssert(typeCode);

  size_t length = strlen(typeCode);
  if (length <= 2) {
    return NO;
  }

  if (typeCode[0] != '[' || typeCode[length - 2] != 'c'
      || typeCode[length - 1] != ']') {
    return NO;
  }

  for (size_t i = 1; i < length - 2; i++) {
    if (!isdigit(typeCode[i])) {
      return NO;
    }
  }

  return YES;
}

static NSString *stringFromBoolOrChar(BOOL value) {
  if (value) {
    return @"YES";
  } else if (value == NO) {
    return @"NO";
  } else {
    return [NSString stringWithFormat:@"'%c'", value];
  }
}

static NSString *stringFromNSDecimalWithCurrentLocale(NSDecimal value) {
  return NSDecimalString(&value, [NSLocale currentLocale]);
}

#pragma mark -
#pragma mark Logging helper methods
#pragma mark -

- (void)registerTarget:(id<LTLoggerTarget>)target withMinimalLogLevel:(LTLogLevel)minimalLogLevel {
  @synchronized (self) {
    for (NSUInteger i = minimalLogLevel; i <= LTLogLevelError; ++i) {
      [self.targets[i] addObject:target];
    }
  }
}

- (void)unregisterTarget:(id<LTLoggerTarget>)target {
  @synchronized (self) {
    for (NSUInteger i = 0; i <= LTLogLevelError; ++i) {
      auto targets = self.targets[i];
      [targets removeObject:target];
    }
  }
}

- (void)logWithFormat:(NSString *)format logLevel:(LTLogLevel)logLevel file:(const char *)file
                 line:(int)line, ... {
  @synchronized (self) {
    auto targets = self.targets[(NSUInteger)logLevel];
    if (!targets.count) {
      return;
    }

    va_list args;
    va_start(args, line);

    NSString *logString = [[NSString alloc] initWithFormat:format arguments:args];
    for (id<LTLoggerTarget> target in targets) {
      [target outputString:logString file:file line:line logLevel:logLevel];
    }

    va_end(args);
  }
}

@end

#pragma mark -
#pragma mark LTOutputLogger
#pragma mark -

@implementation LTOutputLogger

- (void)outputString:(NSString *)message file:(const char *)file line:(int)line
            logLevel:(LTLogLevel)logLevel {
  NSString *formattedMessage = [NSString stringWithFormat:@"%@ [%@] [%s:%d] %@",
                                [[NSDate date] lt_deviceTimezoneString],
                                NSStringFromLTLogLevel(logLevel),
                                file, line, message];
  puts([formattedMessage UTF8String]);
}

@end

NS_ASSUME_NONNULL_END
