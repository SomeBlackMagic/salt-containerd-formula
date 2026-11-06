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

control 'containerd.preflight.remove_conflict' do
  title 'The removal option removes a conflict and is idempotent'

  fixture_pkg = 'containerd-preflight-fixture'
  pillar = <<~PILLAR.strip
    '{"containerd":{"conflicts":{"remove":true,"packages":["#{fixture_pkg}"]}}}'
  PILLAR
  exercise_removal = <<~SH
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
    #{salt_call} #{state} pillar=#{pillar} > "$dir/first.json"
    if sudo dpkg-query -W -f='${Status}' #{fixture_pkg} 2>/dev/null | grep -q '^install ok installed$'; then
      echo 'Fixture package remains installed after removal'
      exit 1
    fi
    echo 'Fixture package removed'
    #{salt_call} #{state} pillar=#{pillar} > "$dir/second.json"
    grep -q 'All specified packages are already absent' "$dir/second.json"
    echo 'Removal is idempotent'
  SH

  describe command(exercise_removal) do
    its('exit_status') { should eq 0 }
    its('stdout') { should include 'Fixture package removed' }
    its('stdout') { should include 'Removal is idempotent' }
  end
end
