# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "gather"
    channel_indices = (1, 3, 7, 15, 31)

    input_shape = common.default_tensor_shape
    output_shape = (input_shape[0], input_shape[1], input_shape[2], len(channel_indices))

    input_name = common.tensor_file_name(test_name, "input", shape=input_shape)
    output_name = common.tensor_file_name(test_name, "output", shape=output_shape)

    input_tensor = common.create_and_save_tensor(file_name=input_name)
    output_tensor = tf.gather(input_tensor, channel_indices, axis=3)

    common.evaluate_and_save(output_tensor, output_name)
