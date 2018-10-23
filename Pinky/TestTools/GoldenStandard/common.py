# Copyright (c) 2018 Lightricks. All rights reserved.

import re

import numpy as np # pylint: disable=E0401
import tensorflow as tf # pylint: disable=E0401

default_tensor_shape = (1, 15, 16, 32)

def create_and_save_tensor(file_name, input_shape=default_tensor_shape, create_as=np.float16,
                           save_as=np.float16):
    input_array = np.random.randn(*input_shape).astype(create_as)

    save_array(input_array.astype(save_as), file_name)
    return tf.constant(value=input_array, dtype=create_as, name=file_name)

def tensor_file_name(name, designation, shape=default_tensor_shape):
    return "{}_{}_{}x{}x{}.tensor".format(name, designation, shape[1], shape[2], shape[3])

def save_array(array, file_name):
    with open(file_name, "wb+") as f:
        array.tofile(f)

def evaluate_and_save(tensor, file_name="output_res", feed_dict=None):
    with tf.Session() as session:
        session.run(tf.global_variables_initializer())
        res = session.run(fetches=tensor, feed_dict=feed_dict)
        save_array(res.astype(np.float16), file_name)
        weights = tf.get_collection(tf.GraphKeys.GLOBAL_VARIABLES)
        for tensorWeight in weights:
            array = tensorWeight.eval()
            name = re.sub(r"[/:]", "_", tensorWeight.name)
            if "conv" in name and "kernel" in name:
                array = array.transpose(3, 0, 1, 2)

            save_array(array.astype(np.float32), name)
