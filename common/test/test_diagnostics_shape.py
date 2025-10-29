"""Lightweight test to assert diagnostics JSON shape for scheduler.

This complements the scheduler-detection tests by ensuring the diagnostics
payload contains the `host-setup.scheduler` object with the minimal shape.
"""
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

import diagnostics


def test_diagnostics_contains_scheduler_block():
    data = diagnostics.collect_diagnostics()
    assert 'host-setup' in data
    hs = data['host-setup']
    assert 'scheduler' in hs
    sched = hs['scheduler']
    # minimal expected keys
    assert 'available' in sched
    assert 'name' in sched
    assert 'line' in sched
    # available should be boolean
    assert isinstance(sched['available'], bool)
    # line should be a short human message
    assert isinstance(sched['line'], str)
