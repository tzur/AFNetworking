// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

NS_ASSUME_NONNULL_BEGIN

/// Category for accessing and manipulating URL \c query string.
@interface NSURL (Query)

/// Returns a new URL made by appending query items from \c queryItems array. The order and the
/// multiplicity of query items (both existing and new) are preserved.
///
/// Raises \c NSInternalInconsistencyException if the URL string of the receiver could not be
/// parsed. This should never happen, since the receiver instance has applied the same parsing logic
/// in order to be initialized.
///
/// @see <tt>-[NSURLComponents queryItems]</tt> for the details of how an item is mapped to \c query
/// string.
- (NSURL *)lt_URLByAppendingQueryItems:(NSArray<NSURLQueryItem *> *)queryItems;

/// Returns a new URL made by appending query items as defined by \c queryDictionary. The order
/// and the multiplicity of the original query items are preserved, but the ordering of new items is
/// not defined.
///
/// @note \c NSNull is not allowed. Use empty strings to append query item with empty key and/or
/// value parts.
///
/// Raises \c NSInvalidArgumentException if \c queryDictionary contains anything other than
/// \c NSString.
///
/// Raises \c NSInternalInconsistencyException if the URL string of the receiver could not be
/// parsed. This should never happen, since the receiver instance has applied the same parsing logic
/// in order to be initialized.
- (NSURL *)lt_URLByAppendingQueryDictionary:(NSDictionary<NSString *, NSString *> *)queryDictionary;

/// Returns a new URL made by appending query items as defined by \c queryArrayDictionary, for each
/// array in the dictionary, all items are added with the appropriate key. The order and the
/// multiplicity of the original query items are preserved, as well as the order of values within
/// each array, but the ordering of the new arrays themselves is not defined.
///
/// @note \c NSNull is not allowed. Use empty strings to append query item with empty key and/or
/// value parts.
///
/// @note empty arrays are not allowed. Use empty strings to append query items with empty values.
///
/// Raises \c NSInvalidArgumentException if \c queryArrayDictionary contains anything other than
/// \c NSString and non-empty \c NSArray of \c NSString.
///
/// Raises \c NSInternalInconsistencyException if the URL string of the receiver could not be
/// parsed. This should never happen, since the receiver instance has applied the same parsing logic
/// in order to be initialized.
- (NSURL *)lt_URLByAppendingQueryArrayDictionary:
    (NSDictionary<NSString *, NSArray<NSString *> *> *)queryArrayDictionary;

/// The query URL component as an array of name/value pairs. It is a one-to-one mapping of \c query
/// property.
///
/// @note \c NSURL and \c NSURLComponents treat empty and missing queries differently. Missing query
/// means that query component is not present in an URL at all, and so \c query is \c nil. Empty
/// query means that the query component is present, but is empty. In this case, \c query is an
/// empty string.
///
/// The same holds for this property: \c queryItems is is \c nil when query is missing, and empty
/// when query is empty. This is exactly the same as <tt>-[NSURLComponents queryItems]</tt>.
///
/// For example:
///
/// <tt>"scheme://host/path/foo"</tt> -> \c nil
///
/// <tt>"scheme://host/path/foo?"</tt> -> \c @[]
///
/// @see <tt>-[NSURLComponents queryItems]</tt> for the details of this representation.
@property (readonly, nonatomic, nullable) NSArray<NSURLQueryItem *> *lt_queryItems;

/// Query items as a dictionary mapping query keys to query values. If there are multiple query
/// items with the same key, only the last such item is present in the dictionary. Missing query
/// values are converted to empty value strings.
///
/// @note while this property offers a convenient way to access URL's \c query string, it does not
/// represent it uniquely. For example, the original ordering and duplicates are not preserved, and
/// there is no way to distinguish between <tt>"key="</tt> and <tt>"key"</tt> query strings.
///
/// Use \c queryItems when a one-to-one representation of the \c query string is required (and it is
/// if there is anything remotely related to security).
@property (readonly, nonatomic) NSDictionary<NSString *, NSString *> *lt_queryDictionary;

/// Query items as a dictionary mapping query keys to query value arrays. Multiple query items with
/// the same key are joined into single arrays. Missing query values are converted to empty value
/// strings.
///
/// @note while this property offers a convenient way to access URL's \c query string arrays, it
/// does not represent it uniquely. For example, the original ordering is not preserved between
/// different keys, and there is no way to distinguish between <tt>"key="</tt> and <tt>"key"</tt>
/// query strings.
///
/// Use \c queryItems when a one-to-one representation of the \c query string is required (and it is
/// if there is anything remotely related to security).
@property (readonly, nonatomic) NSDictionary<NSString *, NSArray<NSString *> *>
    *lt_queryArrayDictionary;

@end

NS_ASSUME_NONNULL_END
