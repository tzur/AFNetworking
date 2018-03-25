// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <extobjc/metamacros.h>

NS_ASSUME_NONNULL_BEGIN

/// Various useful metamacros.

#pragma mark -
#pragma mark Interface
#pragma mark -

// Foreach macros.

#define _LTUnused(INDEX, VAR) \
  (void)(VAR)

// Foreach separator operators.

#define _LTComma() ,
#define _LTNull()

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

#define metamacro_foreach2_cxt22(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21) \
    metamacro_foreach2_cxt20(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19) \
    SEP() \
    MACRO(CONTEXT, _20, _21)

#define metamacro_foreach2_cxt24(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23) \
    metamacro_foreach2_cxt22(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21) \
    SEP() \
    MACRO(CONTEXT, _22, _23)

#define metamacro_foreach2_cxt26(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25) \
    metamacro_foreach2_cxt24(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23) \
    SEP() \
    MACRO(CONTEXT, _24, _25)

#define metamacro_foreach2_cxt28(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27) \
    metamacro_foreach2_cxt26(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25) \
    SEP() \
    MACRO(CONTEXT, _26, _27)

#define metamacro_foreach2_cxt30(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27, _28, _29) \
    metamacro_foreach2_cxt28(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25, _26, _27) \
    SEP() \
    MACRO(CONTEXT, _28, _29)

#define metamacro_foreach2_cxt32(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27, _28, _29, _30, _31) \
    metamacro_foreach2_cxt30(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25, _26, _27, _28, _29) \
    SEP() \
    MACRO(CONTEXT, _30, _31)

#define metamacro_foreach2_cxt34(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27, _28, _29, _30, _31, _32, _33) \
    metamacro_foreach2_cxt32(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25, _26, _27, _28, _29, _30, _31) \
    SEP() \
    MACRO(CONTEXT, _32, _33)

#define metamacro_foreach2_cxt36(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27, _28, _29, _30, _31, _32, _33, _34, _35) \
    metamacro_foreach2_cxt34(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25, _26, _27, _28, _29, _30, _31, _32, _33) \
    SEP() \
    MACRO(CONTEXT, _34, _35)

#define metamacro_foreach2_cxt38(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27, _28, _29, _30, _31, _32, _33, _34, _35, _36, \
                                 _37) \
    metamacro_foreach2_cxt36(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25, _26, _27, _28, _29, _30, _31, _32, _33, _34, _35) \
    SEP() \
    MACRO(CONTEXT, _36, _37)

#define metamacro_foreach2_cxt40(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                                 _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, \
                                 _24, _25, _26, _27, _28, _29, _30, _31, _32, _33, _34, _35, _36, \
                                 _37, _38, _39) \
    metamacro_foreach2_cxt38(MACRO, CONTEXT, SEP, _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, \
                             _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, _22, _23, _24, \
                             _25, _26, _27, _28, _29, _30, _31, _32, _33, _34, _35, _36, _37) \
    SEP() \
    MACRO(CONTEXT, _38, _39)

NS_ASSUME_NONNULL_END
