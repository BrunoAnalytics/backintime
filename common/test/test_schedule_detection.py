"""Tests for scheduler detection and diagnostics population.

These tests monkeypatch the `schedule` module attributes at runtime so we
can simulate environments with and without a system crontab/fcrontab.
"""
import sys
import os
import json

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

import diagnostics
import schedule


def test_scheduler_absent_returns_unavailable():
    # Save original values
    orig_cmd = getattr(schedule, 'CRONTAB_COMMAND', None)
    orig_has = getattr(schedule, 'HAS_SCHEDULER', None)

    try:
        schedule.CRONTAB_COMMAND = None
        schedule.HAS_SCHEDULER = False

        data = diagnostics.collect_diagnostics()
        sched = data['host-setup']['scheduler']

        assert sched['available'] is False
        assert sched['name'] is None
        assert 'not available' in sched['line']

    finally:
        # Restore
        schedule.CRONTAB_COMMAND = orig_cmd
        schedule.HAS_SCHEDULER = orig_has


def test_scheduler_fcrontab_detected_when_set():
    orig_cmd = getattr(schedule, 'CRONTAB_COMMAND', None)
    orig_has = getattr(schedule, 'HAS_SCHEDULER', None)

    try:
        schedule.CRONTAB_COMMAND = 'fcrontab'
        schedule.HAS_SCHEDULER = True

        data = diagnostics.collect_diagnostics()
        sched = data['host-setup']['scheduler']

        assert sched['available'] is True
        assert sched['name'] == 'fcrontab'
        assert 'fcrontab' in sched['line']

    finally:
        schedule.CRONTAB_COMMAND = orig_cmd
        schedule.HAS_SCHEDULER = orig_has
