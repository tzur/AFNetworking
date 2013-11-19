// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "metamacros.h"

/// Various useful metamacros.

#pragma mark -
#pragma mark Interface
#pragma mark -

/// For each consecutive variadic argument (up to twenty), MACRO is passed the
/// zero-based index of the current argument, CONTEXT, and then two consecutive arguments.
/// The results of adjoining invocations of MACRO are then separated by SEP.
#define metamacro_foreach2(MACRO, CONTEXT, SEP, ...) \
  metamacro_concat(metamacro_foreach2_cxt, \
                   metamacro_argcount(__VA_ARGS__))(MACRO, CONTEXT, SEP, __VA_ARGS__)

#pragma mark -
#pragma mark Implementation
#pragma mark -

#define metamacro_foreach2_cxt2(MACRO, CONTEXT, SEP, _0, _1) \
    MACRO(CONTEXT, _0, _1)

#define metamacro_foreach2_cxt4(MACRO, CONTEXT, SEP, _0, _1, _2, _3) \
    metamacro_foreach2_cxt2(MACRO, CONTEXT, SEP, _0, _1) \
    SEP() \
    MACRO(CONTEXT, _2, _3)

#define metamacro_foreach2_cxt6(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5) \
    metamacro_foreach2_cxt4(MACRO, CONTEXT, SEP, _0, _1, _2, _3) \
    SEP() \
    MACRO(CONTEXT, _4, _5)

#define metamacro_foreach2_cxt8(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7) \
    metamacro_foreach2_cxt6(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5) \
    SEP() \
    MACRO(CONTEXT, _6, _7)

#define metamacro_foreach2_cxt10(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9) \
    metamacro_foreach2_cxt8(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7) \
    SEP() \
    MACRO(CONTEXT, _8, _9)

#define metamacro_foreach2_cxt12(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11) \
    metamacro_foreach2_cxt10(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9) \
    SEP() \
    MACRO(CONTEXT, _10, _11)

#define metamacro_foreach2_cxt14(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13) \
    metamacro_foreach2_cxt12(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11) \
    SEP() \
    MACRO(CONTEXT, _12, _13)

#define metamacro_foreach2_cxt16(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15) \
    metamacro_foreach2_cxt14(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13) \
    SEP() \
    MACRO(CONTEXT, _14, _15)

#define metamacro_foreach2_cxt18(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17) \
    metamacro_foreach2_cxt16(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15) \
    SEP() \
    MACRO(CONTEXT, _16, _17)

#define metamacro_foreach2_cxt20(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19) \
    metamacro_foreach2_cxt18(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17) \
    SEP() \
    MACRO(CONTEXT, _18, _19)
