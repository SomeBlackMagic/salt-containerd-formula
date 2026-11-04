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

This installs the pinned containerd binaries,
manages the containerd configuration file and then
starts the associated containerd service.

``containerd.package``
^^^^^^^^^^^^^^^^^^^^^^

This state extracts the pinned containerd tarball into
``<prefix>/containerd/<version>/`` and links ``containerd``,
``containerd-shim-runc-v2`` and ``ctr`` from ``paths.bin_dir``. Set
``components.containerd.enabled: false`` to skip installation. The version,
download URL, checksums, prefix and binary directory are configurable through
the ``containerd`` Pillar; see ``pillar.example`` and ``parameters/defaults.yaml``.

``containerd.config``
^^^^^^^^^^^^^^^^^^^^^

This state will configure the containerd service and has a dependency on ``containerd.install``
via include list.

``containerd.service``
^^^^^^^^^^^^^^^^^^^^^^

This state will start the containerd service and has a dependency on ``containerd.config``
via include list.

``containerd.clean``
^^^^^^^^^^^^^^^^^^^^

*Meta-state (This is a state that includes other states)*.

this state will undo everything performed in the ``containerd`` meta-state in reverse order, i.e.
stops the service,
removes the configuration file and
then uninstalls the package.

``containerd.service.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state will stop the containerd service and disable it at boot time.

``containerd.config.clean``
^^^^^^^^^^^^^^^^^^^^^^^^^^^

This state will remove the configuration of the containerd service and has a
dependency on ``containerd.service.clean`` via include list.

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
