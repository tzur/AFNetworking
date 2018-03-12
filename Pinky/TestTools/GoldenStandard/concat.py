# Copyright (c) 2018 Lightricks. All rights reserved.

import common
import tensorflow as tf # pylint: disable=E0401

if __name__ == "__main__":
    test_name = "concat"
    primary_input_name = common.tensor_file_name(test_name, "primary_input")
    secondary_input_name = common.tensor_file_name(test_name, "secondary_input")
    output_name = common.tensor_file_name(test_name, "output",
                                          shape=(common.default_tensor_shape[0],
                                                 common.default_tensor_shape[1],
                                                 common.default_tensor_shape[2],
                                                 2 * common.default_tensor_shape[3]))

    primary_input_tensor = common.create_and_save_tensor(file_name=primary_input_name)
    secondary_input_tensor = common.create_and_save_tensor(file_name=secondary_input_name)
    output_tensor = tf.concat([primary_input_tensor, secondary_input_tensor], 3)

    common.evaluate_and_save(output_tensor, output_name)
