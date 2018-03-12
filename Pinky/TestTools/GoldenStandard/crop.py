# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "crop"
    left = 1
    top = 2
    right = 3
    bottom = 4

    input_shape = common.default_tensor_shape
    output_shape = (input_shape[0], input_shape[1] - top - bottom, input_shape[2] - left - right,
                    input_shape[3])

    input_name = common.tensor_file_name(test_name, "input", shape=input_shape)
    output_name = common.tensor_file_name(test_name, "output", shape=output_shape)

    input_tensor = common.create_and_save_tensor(file_name=input_name)
    output_tensor = tf.image.crop_to_bounding_box(input_tensor, top, left, output_shape[1],
                                                  output_shape[2])

    common.evaluate_and_save(output_tensor, output_name)
