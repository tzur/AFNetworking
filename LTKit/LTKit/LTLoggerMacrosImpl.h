// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Logging is enabled by default. To disable, add LOGGING=0 to the GCC_PREPROCESSOR_DEFINITIONS
/// build variable.
#ifndef LOGGING
  #define LOGGING 1
#endif

/// Log levels are enabled by default. To disable, add LOGGING_LEVEL_<level>=1 to the
/// GCC_PREPROCESSOR_DEFINITIONS build variable.
/// For these settings to be effective, LOGGING must also be defined and non-zero.
#ifndef LOGGING_LEVEL_DEBUG
  #define LOGGING_LEVEL_DEBUG 1
#endif
#ifndef LOGGING_LEVEL_INFO
  #define LOGGING_LEVEL_INFO 1
#endif
#ifndef LOGGING_LEVEL_WARNING
  #define LOGGING_LEVEL_WARNING 1
#endif
#ifndef LOGGING_LEVEL_ERROR
  #define LOGGING_LEVEL_ERROR 1
#endif

#if !(defined(LOGGING) && LOGGING)
  #undef LOGGING_LEVEL_DEBUG
  #undef LOGGING_LEVEL_INFO
  #undef LOGGING_LEVEL_WARNING
  #undef LOGGING_LEVEL_ERROR
#endif

/// Formats the format string, level and varargs to an Objective-C call to \c LTLogger.
#if !(defined(LT_LOG_FORMAT))
  #define LT_LOG_FORMAT(fmt, lvl, ...) do { \
    NSString *fileName = [[NSString stringWithUTF8String:__FILE__] lastPathComponent]; \
    const char *fileNameChar = [fileName UTF8String] ?: ""; \
    [[LTLogger sharedLogger] logWithFormat:fmt logLevel:lvl file:fileNameChar \
                                      line:__LINE__, ##__VA_ARGS__]; \
  } while (0)
#endif

#if defined(LOGGING_LEVEL_DEBUG) && LOGGING_LEVEL_DEBUG
  #define _LogDebug(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelDebug, ##__VA_ARGS__)
#else
  #define _LogDebug(...) _LogUnused(__VA_ARGS__)
#endif

#if defined(LOGGING_LEVEL_INFO) && LOGGING_LEVEL_INFO
  #define _LogInfo(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelInfo, ##__VA_ARGS__)
#else
  #define _LogInfo(...) _LogUnused(__VA_ARGS__)
#endif

#if defined(LOGGING_LEVEL_WARNING) && LOGGING_LEVEL_WARNING
  #define _LogWarning(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelWarning, ##__VA_ARGS__)
#else
  #define _LogWarning(...) _LogUnused(__VA_ARGS__)
#endif

#if defined(LOGGING_LEVEL_ERROR) && LOGGING_LEVEL_ERROR
  #define _LogError(fmt, ...) LT_LOG_FORMAT(fmt, LTLogLevelError, ##__VA_ARGS__)
#else
  #define _LogError(...) _LogUnused(__VA_ARGS__)
#endif

/// Drops the first argument, and calls \c _LTUnused on the next arguments.
#define _LogUnused(...) \
    metamacro_if_eq(1, metamacro_argcount(__VA_ARGS__)) \
      () \
      (metamacro_foreach(_LTUnused, ;, metamacro_tail(__VA_ARGS__)))

/// Based on http://vgable.com/blog/2010/08/19/the-most-useful-objective-c-code-ive-ever-written/
#define _LogExpression(expr) do { \
    __typeof__(expr) value = (expr); \
    const char *typeCode = @encode(__typeof__(expr)); \
    NSString *output = [LTLogger descriptionFromTypeCode:typeCode andValue:&value]; \
    if (output) { \
      LogDebug(@"%s = %@", #expr, output); \
    } else { \
      LogDebug(@"Unknown type given to log: %s", typeCode); \
    } \
} while (0)

NS_ASSUME_NONNULL_END
