# Event-handling utilities
#
# Copyright (c) 2018 Ensoft Ltd

"""Event-handling utilities."""

__all__ = ("create_checked_task",)


import asyncio


def create_checked_task(coro_or_future):
    """
    Wrapper for `asyncio.ensure_future` that always propagates exceptions.
    """

    def raise_any_exc(task):
        return task.result()

    task = asyncio.ensure_future(coro_or_future)
    task.add_done_callback(raise_any_exc)
    return task
