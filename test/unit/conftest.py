# -*- coding: utf-8 -*-
"""
Shared fixtures for unit tests of the formula's custom Salt extensions.

The extension modules live in ``_serializers/`` at the repository root (the
location Salt syncs them from), so that directory is put on ``sys.path`` here
instead of packaging the modules.
"""

import pathlib
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "_serializers"))
