// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@interface NSSet<ObjectType> (Operations)

/// Returns a new set comprised of all objects in the receiver and all objects in \c otherSet.
- (NSSet<ObjectType> *)lt_union:(NSSet<ObjectType> *)otherSet;

/// Returns a new set comprised of objects in the receiver, but excluding any object in \c otherSet.
- (NSSet<ObjectType> *)lt_minus:(NSSet<ObjectType> *)otherSet;

/// Returns a new set comprised of only the objects that are both in the reciver and in \c otherSet.
- (NSSet<ObjectType> *)lt_intersect:(NSSet<ObjectType> *)otherSet;

@end

NS_ASSUME_NONNULL_END
