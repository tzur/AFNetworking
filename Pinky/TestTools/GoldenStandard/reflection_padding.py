# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "reflection_padding"
    left = 2
    top = 3
    right = 4
    bottom = 5

    paddings = tf.constant([[0, 0], [top, bottom], [left, right], [0, 0]])

    input_shape = common.default_tensor_shape
    output_shape = (input_shape[0], input_shape[1] + top + bottom, input_shape[2] + left + right,
                    input_shape[3])

    input_name = common.tensor_file_name(test_name, "input", shape=input_shape)
    output_name = common.tensor_file_name(test_name, "output", shape=output_shape)

    input_tensor = common.create_and_save_tensor(file_name=input_name)
    output_tensor = tf.pad(input_tensor, paddings, mode="REFLECT")

    common.evaluate_and_save(output_tensor, output_name)
