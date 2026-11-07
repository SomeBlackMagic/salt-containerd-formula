# Changelog

## 1.0.0 (2026-11-07)

### ⚠ BREAKING CHANGES

* changed all state names and ids

### Features

* add `containerd_toml` serializer with tests and unit test setup ([b1024d1](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/b1024d13be4aa78dcee2efd0bdb943aa33d2ed6c))
* **artifact:** add versioned artifact installation macro ([92c0620](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/92c0620d11596692e22449771952e3c1d6e9f231))
* **containerd:** add full pillar schema with pinned versions ([a186eb5](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/a186eb5c3d65c6a614c0258c611aae7951cc421d))
* convert `template-formula` to `containerd-formula` ([2f004d8](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/2f004d874926cdc78c85bb3a525da1f1f80356e2))
* initial commit ([33f11f7](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/33f11f79086ce73c7032594665934728c1657cd7))
* **WP-03:** add support for pinned binaries and improve config handling ([91e8356](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/91e83567660bdbff6b1dd5c43238fabf535517d4))
* **WP-04-preflight:** add preflight checks for architecture and conflicts ([de55872](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/de558724ce35698339c807c0ce2fd92348c60e60))
* **WP-06:** add support for pinned runc binary installation ([fd828a2](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/fd828a2949d4b41893fd03d0292033cb1914a969))
* **WP-07:** add containerd systemd unit management ([9d8418f](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/9d8418f49e1957092fb31a5e09ec59c8f3420c09))
* **WP-07:** enhance containerd service management with unit and drop-in support ([2b58fe5](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/2b58fe52c7feecb521ba9a838d4fe247ad172b0f))
* **WP-08:** serialize containerd config from merged defaults ([6a5e3bc](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/6a5e3bcce630b3f30985711a4d40ad1507e16d6c))
* **WP-09:** add containerd config drop-in management ([0224c1a](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/0224c1ae059380ad35f913bb82481d78c4bef8af))
* **WP-10:** add containerd registry config management ([77ce30f](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/77ce30f4c30c14a27ce794122560187df918c85a))
* **WP-11:** add enable-only service state ([f3d610f](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/f3d610fc4e8adbba2dfe63772a491f535bed1ee7))
* **WP-12:** add containerd kernel prerequisite management ([9bcccf0](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/9bcccf0ff0dba86e3352c4889059edbe88842267))
* **WP-13:** add CNI plugin installation ([cc0cb9a](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/cc0cb9aa7e6605b0ea3bdec403dbff4bbf96b484))
* **WP-14:** add crictl installation and configuration ([5d65c6a](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/5d65c6a4b11cf258f474a604573573feb4e0264c))
* **WP-15:** add nerdctl installation and configuration ([0db1414](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/0db14140037b5d9a24fb729834f68a04792281f4))
* **WP-16:** add containerd package retention ([14c076b](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/14c076bcf8e68e9c1ae780be2c1b122d92f38794))
* **WP-17:** expand containerd clean state coverage ([39f6a9d](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/39f6a9de682118331274499fee17f3a1514193f7))

### Code Refactoring

* **containerd:** remove legacy template formula files ([824db7d](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/824db7d4d97597ecb296a0eea2e295a1f451787f))

### Testing

* **WP-05:** add controls for binary symlinks and version checks ([5242c4e](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/5242c4eeacea6b1f06eb8a7207641d46f3adae58))
* **WP-18:** add full Kitchen suite ([22ceeb6](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/22ceeb6fbf836cbbe01c3d36e33fc600a2f60809))
* **WP-18:** add full suite InSpec controls ([3e396b0](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/3e396b0e22c5d15c1a41e1e56ac54c3d365f78fb))

### Style Changes

* **WP-18:** wrap long InSpec control lines ([1edcf72](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/1edcf72f4f98a4f5afe3759362ac306171c6afb3))

### Continuous Integration

* remove legacy GitLab and Travis configs ([7ba3261](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/7ba32616d76e5e4666f904c08950229f960c031c))
* split release workflow from tests ([8f9d4a2](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/8f9d4a2bdda29351e138f18fec4cf2ab0b0b4137))

### Maintenance

* update repository URL in release config ([c9fa4a1](https://github.com/SomeBlackMagic/salt-containerd-formula/commit/c9fa4a172a38184fe6c8e7e4ea1e19c9f185532e))
