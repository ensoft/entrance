# EnTrance logging utils
#
# Copyright (c) 2018 Ensoft Ltd

"""Logging helpers and utils."""

__all__ = ("FormattedLogRecord",)


import logging


class FormattedLogRecord(logging.LogRecord):
    """
    Log record that supports "{"-style formatting.

    Can be passed to `logging.setLogRecordFactory` to install it as the
    default log record type in the `logging` package.

    """

    def getMessage(self):
        """Return the message for this record."""
        msg = str(self.msg)
        # Short-circuit for old-style formatting.
        if "%" in msg:
            return super().getMessage()
        if self.args:
            # Three possibilities (which match the three
            #  - 'args' is a simple dictionary (on its own) that is to be
            #    output in full in a single "{}". If "format(*self.args)" is
            #    used then only the first item in the dictionary is output.
            #  - The format string doesn't have naming parameters.
            #  - The format string does have naming parameters and so
            #    format_map() must be used.
            try:
                if isinstance(self.args, dict):
                    msg = msg.format(self.args)
                else:
                    msg = msg.format(*self.args)
            except KeyError:
                msg = msg.format_map(self.args)
        # Now truncate the message, if necessary
        truncation = getattr(self, "truncation", None)
        if truncation is not None and len(msg) > truncation:
            msg = "".join((msg[: truncation - 3], "..."))
        return msg
