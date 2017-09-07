// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import <LTKit/LTLocalizationTable.h>

NS_ASSUME_NONNULL_BEGIN

/// Name of the default localization table.
extern NSString * const kSPXDefaultLocalizationTableName;

/// Class that provides localization services. It currently provides one service - it returns the
/// localization tables that contains the localized strings.
@interface SPXLocalization : NSObject

/// Mapping between localization table name and the table for accessing the localized strings.
+ (NSDictionary<NSString *, LTLocalizationTable *> *)localizationTables;

@end

/// Returns localized \c key string from the given table with name \c tableName. \c key is returned
/// if no such key exists in \c tableName or if \c tableName does not exist.
static inline NSString *SPXLocalizeFromTable(NSString *tableName, NSString *key) {
  LTLocalizationTable * _Nullable table = [SPXLocalization localizationTables][tableName];
  return table ? table[key] : key;
}

namespace spx {

  /// Returns localized \c key string from the default table. \c key is returned if no such key
  /// exists in the default table or if the default table does not exist. \c comment is used only by
  /// external tools that extract the strings needed to be localized.
  ///
  /// @important \c key must be a literal string and not \c NSString object.
  ///
  /// @code
  /// _LDefault(@"String to localize", @"some context to help localize this string");
  /// @endcode
  static inline NSString *_LDefault(NSString *key, NSString __unused *comment) {
    return SPXLocalizeFromTable(kSPXDefaultLocalizationTableName, key);
  }

  /// Returns localized \c key for strings containing plurals, like "%d persons" from the default
  /// table. \c key is returned if no such key exists in the default table or if the default table
  /// does not exist. \c comment is used only by external tools that extract the strings needed to
  /// be localized.
  ///
  /// @important \c key must be a literal string and not \c NSString object.
  ///
  /// @code
  /// [NSString stringWithFormat:_LPlural(@"%lu photos", @"context string"), photos.count];
  /// @endcode
  static inline NSString *_LPlural(NSString *key, NSString *comment) {
    return _LDefault(key, comment);
  }
}

NS_ASSUME_NONNULL_END
