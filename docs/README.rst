.. _readme:

containerd-formula
==================

|img_travis| |img_sr| |img_pc|

.. |img_travis| image:: https://travis-ci.com/saltstack-formulas/containerd-formula.svg?branch=master
   :alt: Travis CI Build Status
   :scale: 100%
   :target: https://travis-ci.com/saltstack-formulas/containerd-formula
.. |img_sr| image:: https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg
   :alt: Semantic Release
   :scale: 100%
   :target: https://github.com/semantic-release/semantic-release
.. |img_pc| image:: https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white
   :alt: pre-commit
   :scale: 100%
   :target: https://github.com/pre-commit/pre-commit

A SaltStack formula to install and configure the containerd container runtime.

.. contents:: **Table of Contents**
   :depth: 1

General notes
-------------

See the full `SaltStack Formulas installation and usage instructions
<https://docs.saltproject.io/en/latest/topics/development/conventions/formulas.html>`_.

If you are interested in writing or contributing to formulas, please pay attention to the `Writing Formula Section
<https://docs.saltproject.io/en/latest/topics/development/conventions/formulas.html#writing-formulas>`_.

If you want to use this formula, please pay attention to the ``FORMULA`` file and/or ``git tag``,
which contains the currently released version. This formula is versioned according to `Semantic Versioning <http://semver.org/>`_.

See `Formula Versioning Section <https://docs.saltproject.io/en/latest/topics/development/conventions/formulas.html#versioning>`_ for more details.

If you need (non-default) configuration, please refer to:

- `how to configure the formula with map.jinja <map.jinja.rst>`_
- the ``pillar.example`` file
- the `Special notes`_ section

Contributing to this repo
-------------------------

Commit messages
^^^^^^^^^^^^^^^

**Commit message formatting is significant!!**

Please see `How to contribute <https://github.com/saltstack-formulas/.github/blob/master/CONTRIBUTING.rst>`_ for more details.

pre-commit
^^^^^^^^^^

`pre-commit <https://pre-commit.com/>`_ is configured for this formula, which you may optionally use to ease the steps involved in submitting your changes.
First install  the ``pre-commit`` package manager using the appropriate `method <https://pre-commit.com/#installation>`_, then run ``bin/install-hooks`` and
now ``pre-commit`` will run automatically on each ``git commit``. ::

  $ bin/install-hooks
  pre-commit installed at .git/hooks/pre-commit
  pre-commit installed at .git/hooks/commit-msg

Special notes
-------------

None

Available states
----------------

.. contents::
   :local:

``containerd``
^^^^^^^^^^^^^^

*Meta-state (This is a state that includes other states)*.

This installs the pinned containerd and runc binaries,
manages the containerd configuration file and then
starts the associated containerd service.
It also includes the kernel prerequisites when ``kernel.enabled`` is true.

``containerd.kernel``
^^^^^^^^^^^^^^^^^^^^^

This opt-in state includes ``containerd.kernel.modules`` and
``containerd.kernel.sysctl``. It is disabled by default. Configure
``kernel.modules`` and ``kernel.sysctl`` under the ``containerd`` Pillar.
The default modules are ``overlay`` and ``br_netfilter``; the default sysctls
enable IP forwarding and bridge netfilter for IPv4 and IPv6. The states write
``/etc/modules-load.d/containerd.conf`` and
``/etc/sysctl.d/90-containerd.conf`` with root ownership and mode ``0644``.
On a VM, the states also load the modules and apply the sysctl values.
Docker Kitchen tests verify only the persistent files.

``containerd.kernel.clean`` removes those two files when explicitly applied.
It does not unload modules or restore live sysctl values.

``containerd.preflight``
^^^^^^^^^^^^^^^^^^^^^^^^

This state checks that the mapped architecture is ``amd64`` or ``arm64``.
By default it fails when any package in ``conflicts.packages`` is installed.
Set ``conflicts.remove: true`` to remove those packages with ``pkg.removed``.
The default package list is ``containerd``, ``containerd.io``, ``docker.io``,
``docker-ce`` and ``runc``. The package installation state requires preflight
to succeed before it creates any artifact directories.

``containerd.package``
^^^^^^^^^^^^^^^^^^^^^^

This state extracts the pinned containerd tarball into
``<prefix>/containerd/<version>/`` and links ``containerd``,
``containerd-shim-runc-v2`` and ``ctr`` from ``paths.bin_dir``. Set
``components.containerd.enabled: false`` to skip installation. The version,
download URL, checksums, prefix and binary directory are configurable through
the ``containerd`` Pillar; see ``pillar.example`` and ``parameters/defaults.yaml``.
The package state also includes ``containerd.package.retention``. After a
successful archive extraction, retention keeps the selected version and the
``keep_versions`` most recently modified older version directories under
``<paths.prefix>/containerd/``. The default is two; set it to zero to keep
only the selected version. Retention considers immediate directories whose
names start with a digit, does not follow symlinks, and leaves binary links
unchanged. Set an older version in Pillar to roll back while its directory is
still retained.

``containerd.package.retention``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state can be applied directly to prune older containerd version
directories after installing the selected version. It requires
``containerd-artifact-containerd-tarball`` before removing a directory.

``containerd.runc``
^^^^^^^^^^^^^^^^^^^

This state includes ``containerd.runc.install``. When
``components.runc.enabled`` is true (the default), the install state downloads
the pinned binary to ``<prefix>/runc/<version>/runc`` with mode ``0755`` and
links it from ``paths.sbin_dir``. The download uses the configured URL and
``components.runc.checksums[version][arch]``. A missing checksum stops rendering.
Set ``components.runc.enabled: false`` to skip runc installation. Applying
``containerd.runc`` by itself does not start the containerd service.

``containerd.cni``
^^^^^^^^^^^^^^^^^^

This state includes ``containerd.cni.install``. CNI installation is opt-in:
set ``components.cni.enabled: true``. It extracts the pinned CNI plugins
tarball into ``<paths.prefix>/cni/<version>/`` and links ``bridge``,
``loopback`` and ``host-local`` into ``components.cni.dir`` (default
``/opt/cni/bin``). The tarball uses ``components.cni.url`` and
``components.cni.checksums[version][arch]``; a missing checksum stops
rendering. The default version is ``1.9.1``. Applying this state alone does
not manage the containerd service. Network configuration under
``/etc/cni/net.d`` belongs to the network plugin and is not managed here.

``containerd.crictl``
^^^^^^^^^^^^^^^^^^^^^

This state includes ``containerd.crictl.install`` and
``containerd.crictl.config``. Set ``components.crictl.enabled: true`` to
install the optional pinned tarball and link ``crictl`` into
``paths.bin_dir``. The artifact uses ``components.crictl.version``, ``url``
and ``checksums[version][arch]``; a missing checksum stops rendering.
The config state serializes ``components.crictl.config`` as YAML to
``/etc/crictl.yaml`` with root ownership and mode ``0644``. The default
runtime and image endpoints are both
``unix:///run/containerd/containerd.sock``. Applying this state alone does
not start containerd; ``crictl info`` requires a running CRI service.
Apply ``containerd.crictl.clean`` explicitly to remove the config file,
binary symlink and configured version directory.

``containerd.nerdctl``
^^^^^^^^^^^^^^^^^^^^^^

This state includes ``containerd.nerdctl.install`` and
``containerd.nerdctl.config``. Set ``components.nerdctl.enabled: true`` to
extract the minimal nerdctl tarball into
``<paths.prefix>/nerdctl/<version>/`` and link ``nerdctl`` into
``paths.bin_dir``. The artifact uses ``components.nerdctl.version``, ``url``
and ``checksums[version][arch]``; a missing checksum stops rendering.
The config state serializes ``components.nerdctl.config`` as TOML to
``/etc/nerdctl/nerdctl.toml`` with root ownership and mode ``0644``.
Applying this state alone does not start containerd; ``nerdctl version``
shows server information when the containerd service is running.
Apply ``containerd.nerdctl.clean`` explicitly to remove the config file,
binary symlink and configured version directory. Other version directories
and files in ``/etc/nerdctl`` are retained.

``containerd.config``
^^^^^^^^^^^^^^^^^^^^^

This state includes ``containerd.config.file``, ``containerd.config.dropins``
and ``containerd.config.registries``.
It serializes the merged ``containerd:config`` Pillar and formula defaults to
``<paths.config_dir>/config.toml`` with the ``containerd_toml`` serializer.
Set a key to ``null`` in Pillar to omit that key from the TOML output.
The file state depends on ``containerd.package.install`` and can be applied
without starting the service.

``containerd.config.dropins`` writes one TOML file for each ``config_d`` entry
under ``<paths.config_dir>/conf.d/``. The entry name becomes the filename with
``.toml`` appended. It removes files in that directory that are absent from
``config_d``. The default ``config.toml`` imports these files. Applying this
state by itself does not start the service.

``containerd.config.registries`` writes ``hosts.toml`` and the files in each
``registries.<host>.files`` mapping under ``<paths.certs_dir>/<host>/``. The
``hosts`` mapping becomes the TOML ``host`` table; ``files`` is excluded from
``hosts.toml``. Files are owned by root and have mode ``0644``. Unlisted files
inside a managed host directory are removed. Other host directories are kept
unless ``registries_purge: true`` is set. Applying this state does not start
or restart the service.

``containerd.service``
^^^^^^^^^^^^^^^^^^^^^^

This state includes ``containerd.service.unit`` and
``containerd.service.running``. The unit state installs
``/etc/systemd/system/<service.name>.service`` and its
``<service.name>.service.d/override.conf`` drop-in. Both files use TOFS sources.
When either file changes, Salt runs ``systemctl daemon-reload`` before managing
the service. The running state also includes ``containerd.config.file`` and
restarts the service when the containerd archive, executable symlink, config,
unit, or drop-in changes. Setting ``service.restart_on_change: false`` makes
these resources prerequisites without restarting the service when they change.
The default ``service.state: running`` enables and starts the service.
``service.state: enabled`` installs and enables it without starting it. Other
values fail during rendering. When running, the socket is at
``/run/containerd/containerd.sock`` and ``ctr version`` reports a server.

``service.environment`` adds variables to the drop-in's ``[Service]`` section
(for example ``HTTPS_PROXY`` and ``NO_PROXY``). ``service.overrides`` adds
other ``[Service]`` directives, such as ``LimitNOFILE: 1048576``. Both default
to empty mappings. The service name defaults to ``containerd`` and the unit's
``ExecStart`` uses ``paths.bin_dir``.

``containerd.service.unit`` can be applied directly to install the unit and
drop-in without starting the service. Its package install dependency ensures
the configured binary is present.

``containerd.clean``
^^^^^^^^^^^^^^^^^^^^

*Meta-state (This is a state that includes other states)*.

Apply this state explicitly to stop and disable the service, remove the
formula's configuration, unit files, binary links, versioned artifact
directories, and kernel prerequisite files. It includes the clean states for
containerd, runc, CNI, crictl, and nerdctl. Registry directories configured
under ``registries`` are removed; other registry directories are preserved.
``/var/lib/containerd`` is preserved by default. Set
``clean.purge_data: true`` to remove it when applying ``containerd.clean``.

``containerd.service.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state stops and disables the service, removes its managed systemd unit and
override file, and reloads systemd when either file changes.

``containerd.config.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state removes the main configuration, ``conf.d``, and configured registry
directories after ``containerd.service.clean`` completes.

``containerd.package.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state removes the three managed binary links and all containerd version
directories after ``containerd.config.clean`` completes.

``containerd.runc.clean`` and ``containerd.cni.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

These states remove their managed binary links and version directories after
the service stops. CNI network configuration in ``/etc/cni/net.d`` is retained.
``containerd.crictl.clean`` and ``containerd.nerdctl.clean`` also remove their
managed configuration files, links, and version directories.

Testing
-------

Linux testing is done with ``kitchen-salt``.

Requirements
^^^^^^^^^^^^

* Ruby
* Docker

.. code-block:: bash

   $ gem install bundler
   $ bundle install
   $ bin/kitchen test [platform]

Where ``[platform]`` is the platform name defined in ``kitchen.yml``,
e.g. ``debian-9-2019-2-py3``.

``bin/kitchen converge``
^^^^^^^^^^^^^^^^^^^^^^^^

Creates the docker instance and runs the ``containerd`` main state, ready for testing.

``bin/kitchen verify``
^^^^^^^^^^^^^^^^^^^^^^

Runs the ``inspec`` tests on the actual instance.

``bin/kitchen destroy``
^^^^^^^^^^^^^^^^^^^^^^^

Removes the docker instance.

``bin/kitchen test``
^^^^^^^^^^^^^^^^^^^^

Runs all of the stages above in one go: i.e. ``destroy`` + ``converge`` + ``verify`` + ``destroy``.

``bin/kitchen login``
^^^^^^^^^^^^^^^^^^^^^

Gives you SSH access to the instance for manual testing.
