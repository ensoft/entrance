# Target group feature
#
# Copyright (c) 2018 Ensoft Ltd

from .._util import events
from .tgt_base import TargetFeature


class TargetGroupFeature(TargetFeature):
    """
    Feature that manages a set (or subtree) of target features
    """

    #
    # Schema
    #
    name = "target_group"

    #
    # Implementation
    #
    def __init__(self, ws_handler, channel, target, original_request):
        """
        Initialize ourselves for the specified target
        """
        super().__init__(ws_handler, channel, target, original_request)
        self.parent_target = original_request.get("parent_target", None)

        # If there are target features for our member target that have
        # already been started, associate them with us now. Any ones created
        # subsequently will automatically invoke our add_feature() method.
        for feature in ws_handler.get_features_for_target(target):
            assert feature != self
            self.add_feature(feature)

    async def connect(self, conn_factory):
        """
        Initiate all the connections to this target
        """
        for child in self.children:
            events.create_checked_task(child.connect(conn_factory))

    def add_feature(self, feature):
        """
        Add a target feature for our target
        """
        self.children.add(feature)
        feature.parent_target_group = self
        if self.connect_requested:
            # A connect request has already been made. So the late-arrival
            # feature should try to connect now too.
            events.create_checked_task(feature.connect(self.conn_factory))

    def remove_feature(self, feature):
        """
        Remove a target feature from our target
        """
        self.children.remove(feature)
