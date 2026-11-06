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

``containerd.runc``
^^^^^^^^^^^^^^^^^^^

This state includes ``containerd.runc.install``. When
``components.runc.enabled`` is true (the default), the install state downloads
the pinned binary to ``<prefix>/runc/<version>/runc`` with mode ``0755`` and
links it from ``paths.sbin_dir``. The download uses the configured URL and
``components.runc.checksums[version][arch]``. A missing checksum stops rendering.
Set ``components.runc.enabled: false`` to skip runc installation. Applying
``containerd.runc`` by itself does not start the containerd service.

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

this state will undo everything performed in the ``containerd`` meta-state in reverse order, i.e.
stops the service,
removes the configuration file and
then uninstalls the package.
It also removes the two formula-owned kernel prerequisite files.

``containerd.service.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state will stop the containerd service and disable it at boot time.

``containerd.config.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state will remove the configuration of the containerd service and has a
dependency on ``containerd.service.clean`` via include list.
It also removes the ``conf.d`` directory after stopping the service.

``containerd.package.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state removes the three managed binary links and the currently selected
version directory after ``containerd.config.clean``. Older version directories
remain available for rollback.

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
