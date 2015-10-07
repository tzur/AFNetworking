// Copyright (c) 2012 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTLogger.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTLogger
#pragma mark -

@interface LTLogger ()

/// Targets for logging.
@property (strong, nonatomic) NSMutableSet *targets;

/// Lock for ensuring thread-safety when logging from multiple threads.
@property (strong, nonatomic) NSLock *lock;

@end

@implementation LTLogger

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    self.targets = [NSMutableSet set];
    self.lock = [[NSLock alloc] init];
  }
  return self;
}

+ (LTLogger *)sharedLogger {
  static LTLogger *instance = nil;
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

- (void)registerTarget:(id<LTLoggerTarget>)target {
  [self.targets addObject:target];
}

- (void)logWithFormat:(NSString *)format, ... {
  va_list argList;
  
  // Initialize logging string with variable number of arguments.
  va_start(argList, format);
  [self logWithFormat:format arguments:argList];
  va_end(argList);
}

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList {
  NSString *logString = [[NSString alloc] initWithFormat:format arguments:argList];
  
  // Write to targets.
  [self.lock lock];
  for (id<LTLoggerTarget> target in self.targets) {
    [target outputString:logString];
  }
  [self.lock unlock];
}

- (void)logWithFormat:(NSString *)format file:(const char *)file line:(int)line
             logLevel:(LTLogLevel)logLevel, ... {
  // Do not log messages below the minimal log level.
  if (logLevel < self.minimalLogLevel) {
    return;
  }
  
  // Create date string.
  NSDateFormatter *dateFormatter = [NSDateFormatter new];
  [dateFormatter setDateFormat:@"HH:mm:ss.SSS"];
  
  NSString *logLevelString;
  switch (logLevel) {
    case LTLogLevelDebug:
      logLevelString = @"DEBUG";
      break;
    case LTLogLevelInfo:
      logLevelString = @"INFO";
      break;
    case LTLogLevelWarning:
      logLevelString = @"WARNING";
      break;
    case LTLogLevelError:
      logLevelString = @"ERROR";
      break;
  }
  
  format = [NSString stringWithFormat:@"%@ [%@] [%s:%d] %@",
            [dateFormatter stringFromDate:[NSDate date]], logLevelString, file, line, format];
  
  va_list args;
  
  // Initialize logging string with variable number of arguments.
  va_start(args, logLevel);
  [self logWithFormat:format arguments:args];
  va_end(args);
}

@end

#pragma mark -
#pragma mark LTOutputLogger
#pragma mark -

@implementation LTOutputLogger

- (void)outputString:(NSString *)message {
  puts([message UTF8String]);
}

@end

NS_ASSUME_NONNULL_END
