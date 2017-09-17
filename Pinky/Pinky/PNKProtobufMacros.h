// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#undef PNK_PROTOBUF_INCLUDE_BEGIN
#define PNK_PROTOBUF_INCLUDE_BEGIN \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wunused-parameter\"") \
    _Pragma("clang diagnostic ignored \"-Wshorten-64-to-32\"")

#undef PNK_PROTOBUF_INCLUDE_END
#define PNK_PROTOBUF_INCLUDE_END \
    _Pragma("clang diagnostic pop")
