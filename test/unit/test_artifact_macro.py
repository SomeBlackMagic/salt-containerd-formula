"""Render tests for the versioned artifact state macro."""

from pathlib import Path

import jinja2
import pytest
import yaml


REPO_ROOT = Path(__file__).resolve().parents[2]


def render_artifact(component, kind, expose, target_dir, mapdata):
    """Render the artifact macro with the supplied map data."""
    environment = jinja2.Environment(
        loader=jinja2.FileSystemLoader(str(REPO_ROOT)),
    )
    environment.globals["raise"] = raise_template_error
    template = environment.from_string(
        "{% from 'containerd/macros/artifact.jinja' import artifact with context %}"
        "{{ artifact(component, kind, expose, target_dir) }}"
    )
    return template.render(
        component=component,
        containerd=mapdata,
        expose=expose,
        kind=kind,
        target_dir=target_dir,
    )


def raise_template_error(message):
    """Expose Salt's Jinja ``raise`` behaviour to the standalone renderer."""
    raise jinja2.TemplateRuntimeError(message)


@pytest.fixture
def mapdata():
    """Return the minimal map data needed by the artifact macro."""
    return {
        "arch": "amd64",
        "paths": {
            "prefix": "/opt/containerd",
        },
        "components": {
            "containerd": {
                "version": "2.4.2",
                "url": "https://example.test/containerd-{version}-{arch}.tar.gz",
                "checksums": {
                    "2.4.2": {
                        "amd64": "tarball-checksum",
                    },
                },
            },
            "runc": {
                "version": "1.5.2",
                "url": "https://example.test/runc.{arch}",
                "checksums": {
                    "1.5.2": {
                        "amd64": "binary-checksum",
                    },
                },
            },
        },
    }


def test_tarball_artifact_renders_archive_and_symlinks(mapdata):
    rendered = yaml.safe_load(
        render_artifact(
            "containerd",
            "tarball",
            {"containerd": "bin/containerd", "ctr": "bin/ctr"},
            "/usr/local/bin",
            mapdata,
        )
    )

    archive = rendered["containerd-artifact-containerd-tarball"]["archive.extracted"]
    assert archive == [
        {"name": "/opt/containerd/containerd/2.4.2"},
        {"source": "https://example.test/containerd-2.4.2-amd64.tar.gz"},
        {"source_hash": "sha256=tarball-checksum"},
        {"enforce_toplevel": False},
        {"trim_output": True},
        {"require": [{"file": "containerd-artifact-containerd-directory"}]},
    ]
    assert rendered["containerd-artifact-containerd-containerd-symlink"]["file.symlink"][
        1
    ] == {"target": "/opt/containerd/containerd/2.4.2/bin/containerd"}
    assert rendered["containerd-artifact-containerd-ctr-symlink"]["file.symlink"][0] == {
        "name": "/usr/local/bin/ctr"
    }


def test_binary_artifact_renders_managed_file_and_symlink(mapdata):
    rendered = yaml.safe_load(
        render_artifact(
            "runc",
            "binary",
            {"runc": "runc"},
            "/usr/local/sbin",
            mapdata,
        )
    )

    binary = rendered["containerd-artifact-runc-binary"]["file.managed"]
    assert binary == [
        {"name": "/opt/containerd/runc/1.5.2/runc"},
        {"source": "https://example.test/runc.amd64"},
        {"source_hash": "sha256=binary-checksum"},
        {"mode": "0755"},
        {"makedirs": True},
        {"require": [{"file": "containerd-artifact-runc-directory"}]},
    ]
    assert rendered["containerd-artifact-runc-runc-symlink"]["file.symlink"][1] == {
        "target": "/opt/containerd/runc/1.5.2/runc"
    }


def test_missing_checksum_stops_render_with_component_version_and_arch(mapdata):
    del mapdata["components"]["runc"]["checksums"]["1.5.2"]["amd64"]

    with pytest.raises(
        jinja2.TemplateRuntimeError,
        match="Missing checksum for component 'runc' version '1.5.2' arch 'amd64'",
    ):
        render_artifact(
            "runc",
            "binary",
            {"runc": "runc"},
            "/usr/local/sbin",
            mapdata,
        )


# ---------------------------------------------------------------------------
# Install SLS render tests (moved from test_package_install.py)
# ---------------------------------------------------------------------------


def _render_install(enabled):
    """Render the install SLS with a minimal map and the real artifact macro."""
    loader = jinja2.ChoiceLoader(
        [
            jinja2.DictLoader(
                {
                    "containerd/map.jinja": "{% set mapdata = test_mapdata %}",
                }
            ),
            jinja2.FileSystemLoader(str(REPO_ROOT)),
        ]
    )
    environment = jinja2.Environment(loader=loader)
    template = environment.get_template("containerd/package/install.sls")
    return yaml.safe_load(
        template.render(
            tpldir="containerd/package",
            test_mapdata={
                "arch": "amd64",
                "paths": {"prefix": "/opt/containerd", "bin_dir": "/usr/local/bin"},
                "components": {
                    "containerd": {
                        "enabled": enabled,
                        "version": "2.4.2",
                        "url": "https://example.test/{version}/{arch}.tar.gz",
                        "checksums": {"2.4.2": {"amd64": "abc123"}},
                    }
                },
            },
        )
    )


def test_disabled_component_emits_no_install_states():
    assert _render_install(False) is None
