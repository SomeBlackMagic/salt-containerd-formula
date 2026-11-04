# frozen_string_literal: true

# Common salt-call invocation for preflight tests.
# The preflight suite does NOT converge the full formula — it runs salt-call
# inline so each control can supply its own pillar overrides.
salt_call = 'sudo salt-call --local --config-dir /tmp/kitchen/etc/salt --out=json'
state     = 'state.apply containerd.preflight'

# ---------------------------------------------------------------------------
# Architecture validation
# ---------------------------------------------------------------------------

control 'containerd.preflight.supported_architecture' do
  title 'A supported architecture (the current host) passes without error'

  describe command("#{salt_call} #{state}") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/Supported architecture: (amd64|arm64)/) }
  end
end

control 'containerd.preflight.unsupported_architecture' do
  title 'An unsupported mapped architecture fails with a clear message'

  pillar = '\'{"containerd":{"arch":"mips64","conflicts":{"packages":[]}}}\''

  describe command("#{salt_call} #{state} pillar=#{pillar}") do
    its('exit_status') { should_not eq 0 }
    its('stdout') { should match(/Unsupported architecture: mips64/) }
  end
end

# ---------------------------------------------------------------------------
# Conflict detection (remove: false — the default)
# ---------------------------------------------------------------------------

control 'containerd.preflight.conflicting_package_detected' do
  title 'An installed conflicting package is detected and causes failure'

  pillar = '\'{"containerd":{"conflicts":{"packages":["bash"]}}}\''

  describe command("#{salt_call} #{state} pillar=#{pillar}") do
    its('exit_status') { should_not eq 0 }
    its('stdout') { should match(/Conflicting packages are installed: bash/) }
  end
end

control 'containerd.preflight.conflicting_package_not_removed' do
  title 'Detection mode does not remove the conflicting package'

  describe package('bash') do
    it { should be_installed }
  end
end

# ---------------------------------------------------------------------------
# Conflict removal (remove: true) — Debian-only fixture
# ---------------------------------------------------------------------------

# Helper: build and install a disposable .deb fixture package so the removal
# control has a safe, isolated target that does not affect the test host.
fixture_pkg   = 'containerd-preflight-fixture'
fixture_setup = <<~SH
  set -eu
  dir=$(mktemp -d)
  trap 'rm -rf "$dir"' EXIT
  mkdir -p "$dir/package/DEBIAN"
  cat > "$dir/package/DEBIAN/control" <<CTRL
  Package: #{fixture_pkg}
  Version: 1.0
  Architecture: all
  Maintainer: Formula tests <tests@example.invalid>
  Description: Disposable preflight test fixture
  CTRL
  dpkg-deb --build "$dir/package" "$dir/package.deb" >/dev/null
  sudo dpkg -i "$dir/package.deb" >/dev/null
SH

control 'containerd.preflight.remove_conflict_setup' do
  title 'Install a disposable fixture package for the removal test'

  describe command(fixture_setup) do
    its('exit_status') { should eq 0 }
  end

  describe package(fixture_pkg) do
    it { should be_installed }
  end
end

control 'containerd.preflight.remove_conflict' do
  title 'The removal option removes an installed conflicting package'

  pillar = %('{"containerd":{"conflicts":{"remove":true,"packages":["#{fixture_pkg}"]}}}')

  describe command("#{salt_call} #{state} pillar=#{pillar}") do
    its('exit_status') { should eq 0 }
  end

  describe package(fixture_pkg) do
    it { should_not be_installed }
  end
end

control 'containerd.preflight.remove_conflict_idempotent' do
  title 'Re-running removal when the package is already absent is idempotent'

  pillar = %('{"containerd":{"conflicts":{"remove":true,"packages":["#{fixture_pkg}"]}}}')

  describe command("#{salt_call} #{state} pillar=#{pillar}") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/All specified packages are already absent/) }
  end
end
