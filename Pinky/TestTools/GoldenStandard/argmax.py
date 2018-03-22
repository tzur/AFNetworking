# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "argmax"

    input_name = common.tensor_file_name(test_name, "input")
    input_tensor = common.create_and_save_tensor(file_name=input_name)

    output_shape = common.default_tensor_shape[:-1]
    output_name = common.tensor_file_name(test_name, "output", (output_shape + (1,)))
    output_tensor = tf.argmax(input_tensor, axis=3)

    common.evaluate_and_save(output_tensor, output_name)
