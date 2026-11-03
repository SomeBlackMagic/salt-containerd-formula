# -*- coding: utf-8 -*-
"""
Dependency-free TOML serializer for Salt.

Salt's bundled ``toml`` serializer wraps the third-party ``toml`` library,
which is not shipped with the onedir packages (3006, 3007, 3008). This module
writes TOML v1.0.0 with the standard library only, so ``file.serialize`` works
on a stock minion.

Usage:

.. code-block:: yaml

    /etc/containerd/config.toml:
      file.serialize:
        - serializer: containerd_toml
        - dataset:
            version: 3
            plugins:
              io.containerd.cri.v1.runtime:
                containerd:
                  runtimes:
                    runc:
                      options:
                        SystemdCgroup: true
        - serializer_opts:
          - header: Managed by Salt, do not edit by hand

The module must be synced to the minion before use, e.g. via
``saltutil.sync_serializers`` (done automatically on highstate).

Serialization rules:

- The top-level object must be a mapping.
- Keys that are not bare TOML keys (``[A-Za-z0-9_-]+``) are quoted, e.g.
  ``plugins."io.containerd.cri.v1.runtime"``. Integer keys are converted to
  strings; any other non-string key raises an error.
- Keys whose value is ``None`` are omitted. TOML has no null, and this lets a
  pillar remove a key that comes from the formula defaults. ``None`` inside an
  array raises an error.
- In every table, plain key/values are written first, then sub-tables
  (``[a.b]``), then arrays of tables (``[[a.c]]``).
- A table that ends up with no key/values of its own gets a header only when
  it is completely empty, so that the empty table is preserved.
- A non-empty list made only of mappings becomes an array of tables. Any other
  list, and anything nested inside a list, is written inline.
- Key order is kept as given, unless ``sort_keys`` is set.

Options (``serializer_opts``):

sort_keys
    Sort keys in every table. Defaults to ``False``.

header
    Text written as a ``#`` comment block at the top of the document.

Deserialization (used by ``file.serialize`` with ``merge_if_exists``) relies
on ``tomllib`` (Python 3.11+), then ``tomli`` or ``toml`` if installed.
"""

import datetime
import math
import re
from collections.abc import Mapping

try:
    from salt.serializers import DeserializationError, SerializationError
except ImportError:  # pragma: no cover - only hit when running without Salt

    class SerializationError(Exception):
        """Raised when data cannot be serialized."""

    class DeserializationError(Exception):
        """Raised when data cannot be deserialized."""


try:
    import tomllib as _toml_reader
except ImportError:  # Python < 3.11
    try:
        import tomli as _toml_reader
    except ImportError:
        try:
            import toml as _toml_reader
        except ImportError:
            _toml_reader = None


__virtualname__ = "containerd_toml"

__all__ = ["deserialize", "serialize"]

_OPTIONS = frozenset(("sort_keys", "header"))

_BARE_KEY = re.compile(r"[A-Za-z0-9_-]+")

_INT_MIN = -(2**63)
_INT_MAX = 2**63 - 1

_ESCAPES = {
    '"': '\\"',
    "\\": "\\\\",
    "\b": "\\b",
    "\t": "\\t",
    "\n": "\\n",
    "\f": "\\f",
    "\r": "\\r",
}


def __virtual__():
    # Pure standard library: always available
    return __virtualname__


def serialize(obj, **options):
    """
    Serialize a mapping to a TOML document.

    :param obj: the mapping to serialize.
    :param options: ``sort_keys`` (bool) and ``header`` (str).
    :returns: the TOML document, without a trailing newline.
    :raises SerializationError: if the data cannot be represented in TOML.
    """
    unknown = set(options) - _OPTIONS
    if unknown:
        raise SerializationError(
            "Unknown option(s): {}".format(", ".join(sorted(unknown)))
        )
    if not isinstance(obj, Mapping):
        raise SerializationError(
            f"The top-level object must be a mapping, got {type(obj).__name__}"
        )

    writer = _Writer(sort_keys=bool(options.get("sort_keys", False)))
    writer.table(obj, path=(), header=None)
    body = "\n".join(writer.lines).strip("\n")

    header = options.get("header")
    if header:
        comment = "\n".join(
            line if line.startswith("#") else "# " + line
            for line in str(header).splitlines()
        )
        return comment + "\n\n" + body if body else comment
    return body


def deserialize(stream_or_string, **options):
    """
    Deserialize a TOML document into Python data.

    :param stream_or_string: a string, bytes or a file-like object.
    :param options: accepted for API compatibility, ignored.
    :raises DeserializationError: if no parser is available or input is invalid.
    """
    if _toml_reader is None:
        raise DeserializationError(
            "No TOML parser available: requires Python 3.11+ (tomllib), "
            "or the 'tomli' or 'toml' library"
        )
    try:
        if hasattr(stream_or_string, "read"):
            stream_or_string = stream_or_string.read()
        if isinstance(stream_or_string, bytes):
            stream_or_string = stream_or_string.decode("utf-8")
        return _toml_reader.loads(stream_or_string)
    except Exception as error:  # pylint: disable=broad-except
        raise DeserializationError(error)


class _Writer:
    """Accumulates the lines of a TOML document."""

    def __init__(self, sort_keys):
        self.sort_keys = sort_keys
        self.lines = []

    # -- structure ----------------------------------------------------------

    def table(self, table, path, header):
        """
        Write a table and everything below it.

        :param header: ``None`` for the root table, ``"table"`` for ``[a.b]``
            or ``"array"`` for an ``[[a.b]]`` element (always written).
        """
        values, tables, arrays = [], [], []
        for key, value in self._items(table, path):
            if isinstance(value, Mapping):
                tables.append((key, value))
            elif _is_array_of_tables(value):
                arrays.append((key, value))
            else:
                values.append((key, value))

        if header == "array":
            self.lines += ["", f"[[{_dotted(path)}]]"]
        elif header == "table" and (values or not (tables or arrays)):
            self.lines += ["", f"[{_dotted(path)}]"]

        for key, value in values:
            self.lines.append(f"{_key(key)} = {self._inline(value, path + (key,))}")
        for key, value in tables:
            self.table(value, path + (key,), header="table")
        for key, value in arrays:
            for item in value:
                self.table(item, path + (key,), header="array")

    def _items(self, table, path):
        """Yield (key, value) pairs with normalized keys, skipping ``None``."""
        seen = set()
        items = []
        for key, value in table.items():
            norm = _normalize_key(key, path)
            if norm in seen:
                raise SerializationError(f"Duplicate key {norm!r} at {_where(path)}")
            seen.add(norm)
            if value is not None:
                items.append((norm, value))
        if self.sort_keys:
            items.sort(key=lambda item: item[0])
        return items

    # -- values -------------------------------------------------------------

    def _inline(self, value, path):
        if isinstance(value, Mapping):
            pairs = [
                f"{_key(key)} = {self._inline(item, path + (key,))}"
                for key, item in self._items(value, path)
            ]
            return "{ " + ", ".join(pairs) + " }" if pairs else "{}"
        if _is_array(value):
            parts = []
            for index, item in enumerate(value):
                if item is None:
                    raise SerializationError(
                        f"TOML has no null: None in array at {_where(path)}[{index}]"
                    )
                parts.append(self._inline(item, path + (index,)))
            return "[" + ", ".join(parts) + "]"
        return _scalar(value, path)


# -- helpers ------------------------------------------------------------------


def _is_array(value):
    return isinstance(value, (list, tuple))


def _is_array_of_tables(value):
    return (
        _is_array(value)
        and len(value) > 0
        and all(isinstance(item, Mapping) for item in value)
    )


def _normalize_key(key, path):
    if isinstance(key, str):
        return key
    # bool is a subclass of int; YAML turns `on:`/`yes:` into True, which is
    # almost always a mistake, so it is rejected rather than coerced
    if isinstance(key, int) and not isinstance(key, bool):
        return str(key)
    raise SerializationError(
        f"Invalid key {key!r} ({type(key).__name__}) at {_where(path)}: "
        "keys must be strings"
    )


def _key(key):
    # fullmatch: with match(), `$` would also accept a trailing newline
    return key if _BARE_KEY.fullmatch(key) else _quote(key)


def _dotted(path):
    return ".".join(_key(part) for part in path)


def _where(path):
    return ".".join(str(part) for part in path) or "<root>"


def _quote(text):
    out = []
    for char in text:
        if char in _ESCAPES:
            out.append(_ESCAPES[char])
        elif ord(char) < 0x20 or ord(char) == 0x7F:
            out.append(f"\\u{ord(char):04X}")
        else:
            out.append(char)
    return '"' + "".join(out) + '"'


def _scalar(value, path):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        if not _INT_MIN <= value <= _INT_MAX:
            raise SerializationError(
                f"Integer {value} at {_where(path)} does not fit in 64-bit signed range"
            )
        return str(value)
    if isinstance(value, float):
        if math.isnan(value):
            return "nan"
        if math.isinf(value):
            return "inf" if value > 0 else "-inf"
        # repr() always yields a valid TOML float: '1.0', '1e+20', '1e-07'
        return repr(value)
    if isinstance(value, str):
        return _quote(value)
    # datetime must be checked before date (it is a subclass)
    if isinstance(value, (datetime.datetime, datetime.date, datetime.time)):
        return value.isoformat()
    raise SerializationError(
        f"Unsupported type {type(value).__name__} at {_where(path)}"
    )
