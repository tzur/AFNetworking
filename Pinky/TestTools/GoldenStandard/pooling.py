# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

def create_pooling_test(test_name, pool_type="avg", pool_size=(3, 3), strides=(1, 1),
                        padding="SAME"):
    input_name = common.tensor_file_name(test_name, "input", common.default_tensor_shape)
    input_tensor = common.create_and_save_tensor(file_name=input_name)

    if pool_type == "avg":
        output_tensor = tf.nn.avg_pool(value=input_tensor,
                                       ksize=(1, pool_size[0], pool_size[1], 1),
                                       strides=(1, strides[0], strides[1], 1),
                                       padding=padding)
    elif pool_type == "max":
        output_tensor = tf.nn.max_pool(value=input_tensor,
                                       ksize=(1, pool_size[0], pool_size[1], 1),
                                       strides=(1, strides[0], strides[1], 1),
                                       padding=padding)

    output_name = common.tensor_file_name(test_name, "output", output_tensor.shape)

    common.evaluate_and_save(output_tensor, output_name)

if __name__ == "__main__":
    create_pooling_test("pooling_basic")
    create_pooling_test("pooling_stride", strides=(2, 2))
    create_pooling_test("pooling_valid", padding="VALID")
    create_pooling_test("pooling_max", pool_type="max")
