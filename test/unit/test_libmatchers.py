"""Check diagnostics emitted while parsing map matchers under salt-ssh."""

from pathlib import Path

import jinja2
import yaml


REPO_ROOT = Path(__file__).resolve().parents[2]


def render_matchers(matchers, strategy=None):
    warnings = []
    calls = []

    def lookup(method):
        def get(key, default=None, **options):
            calls.append((method, key, options))
            return default

        return get

    environment = jinja2.Environment(
        loader=jinja2.FileSystemLoader(str(REPO_ROOT)),
        extensions=["jinja2.ext.do"],
    )
    def traverse(value, key, default):
        for part in key.split(":"):
            if not isinstance(value, dict) or part not in value:
                return default
            value = value[part]
        return value

    environment.filters["traverse"] = traverse
    environment.filters["yaml"] = lambda value, *_: yaml.safe_dump(value)
    template = environment.from_string(
        "{% from 'containerd/libmatchers.jinja' import parse_matchers with context %}"
        "{{ parse_matchers(matchers, config_get_strategy=strategy) }}"
    )
    template.render(
        tpldir="containerd",
        opts={"__cli": "salt-call", "__master_opts__": {"__cli": "salt-ssh"}},
        matchers=matchers,
        strategy=strategy,
        salt={
            "log.debug": lambda message: None,
            "log.warning": warnings.append,
            "config.get": lookup("config.get"),
            "grains.get": lookup("grains.get"),
        },
    )
    return warnings, calls


def test_salt_ssh_default_matchers_do_not_warn():
    warnings, calls = render_matchers(["defaults.yaml", "Y:G@os", "C@containerd"])

    assert warnings == []
    assert all(options == {} for _, _, options in calls)


def test_salt_ssh_warns_for_unsupported_custom_options():
    warnings, _ = render_matchers(["C@containerd"], strategy="recurse")

    assert len(warnings) == 1
    assert "custom 'delimiter' or 'merge'" in warnings[0]
