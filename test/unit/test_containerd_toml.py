# -*- coding: utf-8 -*-
"""
Unit tests for the ``containerd_toml`` Salt serializer.

Every serialized document is parsed back with a reference TOML parser
(``tomllib`` on Python 3.11+, ``tomli`` otherwise), so the tests check both
that the output is valid TOML and that it carries exactly the input data.
"""

import datetime
import io
import math
import textwrap

import containerd_toml as ct
import pytest

try:
    import tomllib
except ImportError:  # Python < 3.11
    import tomli as tomllib

from hypothesis import given, settings
from hypothesis import strategies as st


def roundtrip(data, **options):
    """Serialize ``data`` and parse it back with the reference parser."""
    return tomllib.loads(ct.serialize(data, **options))


# ---------------------------------------------------------------------------
# Loader contract
# ---------------------------------------------------------------------------


def test_virtual_returns_virtualname():
    assert ct.__virtual__() == "containerd_toml"


def test_public_api():
    assert set(ct.__all__) == {"serialize", "deserialize"}


# ---------------------------------------------------------------------------
# Realistic containerd configuration
# ---------------------------------------------------------------------------

CONTAINERD_K8S = {
    "version": 3,
    "root": "/var/lib/containerd",
    "state": "/run/containerd",
    "imports": ["/etc/containerd/conf.d/*.toml"],
    "grpc": {"address": "/run/containerd/containerd.sock"},
    "plugins": {
        "io.containerd.cri.v1.images": {
            "snapshotter": "overlayfs",
            "registry": {"config_path": "/etc/containerd/certs.d"},
            "pinned_images": {"sandbox": "registry.k8s.io/pause:3.10"},
        },
        "io.containerd.cri.v1.runtime": {
            "enable_selinux": False,
            "containerd": {
                "default_runtime_name": "runc",
                "runtimes": {
                    "runc": {
                        "runtime_type": "io.containerd.runc.v2",
                        "options": {
                            "SystemdCgroup": True,
                            "BinaryName": "/usr/local/sbin/runc",
                        },
                    },
                },
            },
            "cni": {"bin_dirs": ["/opt/cni/bin"], "conf_dir": "/etc/cni/net.d"},
        },
    },
}

CONTAINERD_K8S_TOML = textwrap.dedent(
    """\
    version = 3
    root = "/var/lib/containerd"
    state = "/run/containerd"
    imports = ["/etc/containerd/conf.d/*.toml"]

    [grpc]
    address = "/run/containerd/containerd.sock"

    [plugins."io.containerd.cri.v1.images"]
    snapshotter = "overlayfs"

    [plugins."io.containerd.cri.v1.images".registry]
    config_path = "/etc/containerd/certs.d"

    [plugins."io.containerd.cri.v1.images".pinned_images]
    sandbox = "registry.k8s.io/pause:3.10"

    [plugins."io.containerd.cri.v1.runtime"]
    enable_selinux = false

    [plugins."io.containerd.cri.v1.runtime".containerd]
    default_runtime_name = "runc"

    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.runc]
    runtime_type = "io.containerd.runc.v2"

    [plugins."io.containerd.cri.v1.runtime".containerd.runtimes.runc.options]
    SystemdCgroup = true
    BinaryName = "/usr/local/sbin/runc"

    [plugins."io.containerd.cri.v1.runtime".cni]
    bin_dirs = ["/opt/cni/bin"]
    conf_dir = "/etc/cni/net.d\""""
)


def test_containerd_config_golden():
    assert ct.serialize(CONTAINERD_K8S) == CONTAINERD_K8S_TOML


def test_containerd_config_roundtrip():
    assert roundtrip(CONTAINERD_K8S) == CONTAINERD_K8S


def test_hosts_toml_roundtrip():
    # Shape of /etc/containerd/certs.d/<registry>/hosts.toml
    data = {
        "server": "https://registry-1.docker.io",
        "host": {
            "https://mirror.example.com": {
                "capabilities": ["pull", "resolve"],
                "skip_verify": False,
                "ca": "/etc/containerd/certs.d/docker.io/ca.crt",
                "header": {"X-Custom": ["a", "b"]},
            },
        },
    }
    out = ct.serialize(data)
    assert '[host."https://mirror.example.com"]' in out
    assert roundtrip(data) == data


# ---------------------------------------------------------------------------
# Keys
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "key,expected",
    [
        ("plain", "plain"),
        ("with-dash_and_9", "with-dash_and_9"),
        ("io.containerd.grpc.v1.cri", '"io.containerd.grpc.v1.cri"'),
        ("has space", '"has space"'),
        ("", '""'),
        ("ключ", '"ключ"'),
        ('quo"te', '"quo\\"te"'),
        # Regression: a trailing newline must not pass as a bare key
        ("0\n", '"0\\n"'),
    ],
)
def test_key_quoting(key, expected):
    assert ct.serialize({key: 1}) == f"{expected} = 1"
    assert roundtrip({key: 1}) == {key: 1}


def test_integer_keys_are_coerced_to_strings():
    assert roundtrip({1: "a", "t": {2: "b"}}) == {"1": "a", "t": {"2": "b"}}


@pytest.mark.parametrize("key", [True, False, None, 1.5, ("a",)])
def test_invalid_keys_raise(key):
    with pytest.raises(ct.SerializationError):
        ct.serialize({key: 1})


def test_duplicate_keys_after_coercion_raise():
    with pytest.raises(ct.SerializationError, match="Duplicate key"):
        ct.serialize({1: "a", "1": "b"})


# ---------------------------------------------------------------------------
# Scalars
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "value",
    [
        "",
        "simple",
        'double "quotes"',
        "back\\slash",
        "tab\tnew\nline\rcr",
        "\b\f",
        "\x00\x01\x1f\x7f",
        "unicode ✓ кириллица 🐳",
        "'single'",
        "# not a comment",
    ],
)
def test_string_escaping_roundtrip(value):
    assert roundtrip({"s": value}) == {"s": value}


def test_control_characters_use_unicode_escapes():
    assert ct.serialize({"s": "\x00\x7f"}) == 's = "\\u0000\\u007F"'


@pytest.mark.parametrize(
    "value,expected",
    [
        (True, "true"),
        (False, "false"),
        (0, "0"),
        (-42, "-42"),
        (2**63 - 1, str(2**63 - 1)),
        (-(2**63), str(-(2**63))),
        (1.0, "1.0"),
        (-0.5, "-0.5"),
        (1e20, "1e+20"),
        (1e-7, "1e-07"),
        (float("inf"), "inf"),
        (float("-inf"), "-inf"),
    ],
)
def test_scalar_rendering(value, expected):
    assert ct.serialize({"v": value}) == f"v = {expected}"
    assert roundtrip({"v": value}) == {"v": value}


def test_nan():
    assert ct.serialize({"v": float("nan")}) == "v = nan"
    assert math.isnan(roundtrip({"v": float("nan")})["v"])


@pytest.mark.parametrize("value", [2**63, -(2**63) - 1])
def test_integer_out_of_range_raises(value):
    with pytest.raises(ct.SerializationError, match="64-bit"):
        ct.serialize({"v": value})


@pytest.mark.parametrize(
    "value",
    [
        datetime.datetime(2026, 11, 3, 11, 5, 0, tzinfo=datetime.timezone.utc),
        datetime.datetime(2026, 11, 3, 11, 5, 0),
        datetime.date(2026, 11, 3),
        datetime.time(11, 5, 0),
    ],
)
def test_datetimes_roundtrip(value):
    assert roundtrip({"v": value}) == {"v": value}


@pytest.mark.parametrize("value", [object(), {1, 2}, b"bytes", 1j])
def test_unsupported_types_raise(value):
    with pytest.raises(ct.SerializationError, match="Unsupported type"):
        ct.serialize({"v": value})


# ---------------------------------------------------------------------------
# None handling
# ---------------------------------------------------------------------------


def test_none_values_are_omitted_from_tables():
    # Lets a pillar drop a default key by setting it to null
    data = {"a": None, "b": 1, "t": {"x": None, "y": 2}}
    assert roundtrip(data) == {"b": 1, "t": {"y": 2}}


def test_none_values_are_omitted_from_inline_tables():
    data = {"arr": [{"a": 1, "b": None}, 2]}
    assert roundtrip(data) == {"arr": [{"a": 1}, 2]}


def test_table_of_only_none_values_becomes_empty_table():
    assert ct.serialize({"t": {"x": None}}) == "[t]"


def test_none_in_array_raises():
    with pytest.raises(ct.SerializationError, match="null"):
        ct.serialize({"arr": [1, None]})


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------


def test_empty_table_emits_header():
    # containerd distinguishes "table present but empty" in some plugins
    assert ct.serialize({"a": {"b": {}}}) == "[a.b]"
    assert roundtrip({"a": {"b": {}}}) == {"a": {"b": {}}}


def test_table_with_only_subtables_has_no_own_header():
    out = ct.serialize({"a": {"b": {"c": 1}}})
    assert out == "[a.b]\nc = 1"


def test_scalars_are_written_before_subtables():
    # TOML requires a table's key/values to precede any nested header
    data = {"t": {"sub": {"x": 1}, "y": 2}}
    assert ct.serialize(data) == "[t]\ny = 2\n\n[t.sub]\nx = 1"
    assert roundtrip(data) == data


def test_empty_document():
    assert ct.serialize({}) == ""


@pytest.mark.parametrize("value", [[], "str", 1, None])
def test_top_level_must_be_mapping(value):
    with pytest.raises(ct.SerializationError, match="mapping"):
        ct.serialize(value)


# ---------------------------------------------------------------------------
# Arrays
# ---------------------------------------------------------------------------


def test_array_of_tables():
    data = {
        "proxy_plugins": [
            {"name": "a", "address": "/run/a.sock"},
            {"name": "b", "options": {"x": 1}, "nested": [{"k": 1}, {"k": 2}]},
        ]
    }
    out = ct.serialize(data)
    assert out.count("[[proxy_plugins]]") == 2
    assert "[proxy_plugins.options]" in out
    assert out.count("[[proxy_plugins.nested]]") == 2
    assert roundtrip(data) == data


def test_nested_array_of_tables_inside_table():
    data = {"t": {"items": [{"a": 1}], "x": 1}}
    assert ct.serialize(data) == "[t]\nx = 1\n\n[[t.items]]\na = 1"
    assert roundtrip(data) == data


def test_empty_array():
    assert ct.serialize({"a": []}) == "a = []"


def test_mixed_and_nested_arrays_are_inline():
    data = {"mixed": [1, "two", {"three": 3}, [4, [5]]], "tuple": (1, 2)}
    out = ct.serialize(data)
    assert 'mixed = [1, "two", { three = 3 }, [4, [5]]]' in out
    assert roundtrip(data) == {
        "mixed": [1, "two", {"three": 3}, [4, [5]]],
        "tuple": [1, 2],
    }


def test_empty_inline_table():
    assert ct.serialize({"a": [{}, 1]}) == "a = [{}, 1]"


def test_array_of_tables_inside_inline_context_stays_inline():
    data = {"a": [[{"x": 1}, {"x": 2}]]}
    assert ct.serialize(data) == "a = [[{ x = 1 }, { x = 2 }]]"
    assert roundtrip(data) == data


# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------


def test_insertion_order_is_preserved_by_default():
    assert ct.serialize({"b": 1, "a": 2}) == "b = 1\na = 2"


def test_sort_keys():
    data = {"b": 1, "a": 2, "t": {"z": 1, "y": 2}}
    assert ct.serialize(data, sort_keys=True) == "a = 2\nb = 1\n\n[t]\ny = 2\nz = 1"


def test_header_comment():
    out = ct.serialize({"a": 1}, header="Managed by Salt\n# Do not edit")
    assert out == "# Managed by Salt\n# Do not edit\n\na = 1"
    assert roundtrip({"a": 1}, header="x") == {"a": 1}


def test_unknown_option_raises():
    with pytest.raises(ct.SerializationError, match="Unknown option"):
        ct.serialize({"a": 1}, indent=4)


def test_output_is_deterministic():
    assert ct.serialize(CONTAINERD_K8S) == ct.serialize(CONTAINERD_K8S)


# ---------------------------------------------------------------------------
# Deserialization
# ---------------------------------------------------------------------------


def test_deserialize_string_bytes_and_stream():
    text = ct.serialize(CONTAINERD_K8S)
    assert ct.deserialize(text) == CONTAINERD_K8S
    assert ct.deserialize(text.encode()) == CONTAINERD_K8S
    assert ct.deserialize(io.StringIO(text)) == CONTAINERD_K8S


def test_deserialize_invalid_raises():
    with pytest.raises(ct.DeserializationError):
        ct.deserialize("a = ")


def test_deserialize_without_parser_raises(monkeypatch):
    monkeypatch.setattr(ct, "_toml_reader", None)
    with pytest.raises(ct.DeserializationError, match="No TOML parser"):
        ct.deserialize("a = 1")


# ---------------------------------------------------------------------------
# Property-based round trip
# ---------------------------------------------------------------------------

_keys = st.text(max_size=8)
_scalars = (
    st.booleans()
    | st.integers(min_value=-(2**63), max_value=2**63 - 1)
    | st.floats(allow_nan=False)
    | st.text(max_size=16)
)
_values = st.recursive(
    _scalars,
    lambda children: (
        st.lists(children, max_size=4) | st.dictionaries(_keys, children, max_size=4)
    ),
    max_leaves=20,
)
_documents = st.dictionaries(_keys, _values, max_size=6)


@settings(max_examples=500, deadline=None)
@given(_documents)
def test_property_roundtrip(data):
    assert roundtrip(data) == data
