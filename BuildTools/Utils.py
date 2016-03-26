HEX_ITEMS_PER_LINE = 16


def string_to_buffer(variable_name, s):
    """Converts a Python string to C buffer declaration."""
    lines = ["static const unsigned char k%s[] = {" % variable_name]

    # Group characters such that each group will appear in a line of source code.
    grouped_chars = [s[i:i + HEX_ITEMS_PER_LINE] for i in xrange(0, len(s), HEX_ITEMS_PER_LINE)]

    # Create lines of code.
    for group in grouped_chars:
        lines.append("  %s," % ", ".join([hex(ord(c)) for c in group]))

    # Remove last ',' from the last line.
    lines[-1] = lines[-1][:-1]

    lines.append("};")

    return "\n".join(lines)
