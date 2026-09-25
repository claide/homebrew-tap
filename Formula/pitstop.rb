require "shellwords"

class Pitstop < Formula
  desc "Menu bar AI quota tracker with a quota check for ticket workflows"
  homepage "https://github.com/claide/pitstop"
  url "https://github.com/claide/pitstop/archive/refs/tags/v0.4.4.tar.gz"
  sha256 "eff232819e4dafd1d64044d80d765f7649e7151b0d4f5ff4601059290debbcbd"
  license "MIT"

  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "--configuration", "release"

    contents = prefix/"Pitstop.app/Contents"
    (contents/"MacOS").install ".build/release/Pitstop"
    (contents/"Helpers").install ".build/release/PitstopCLI" => "pitstop"
    contents.install "Resources/Info.plist"

    # Swift's generated Bundle.module accessor looks for this bundle inside
    # Pitstop.app, at its own root (sibling of Contents) — confirmed directly
    # from its runtime error message. It must NOT go in Contents/MacOS or
    # Contents/Resources: codesign rejects a plain resource bundle there, and
    # Bundle.module doesn't look there anyway. Note: `prefix` is this keg's
    # own root, not Pitstop.app — the bundle has to go inside the .app itself.
    bundle = Dir[".build/release/Pitstop_Pitstop.bundle"].first
    FileUtils.cp_r bundle, prefix/"Pitstop.app" if bundle

    # Ad-hoc signatures. Built locally, so Gatekeeper doesn't quarantine it.
    system "codesign", "--force", "--sign", "-", contents/"Helpers/pitstop"

    # codesign warns "unsealed contents present in the bundle root" because
    # the resource bundle sits outside Contents/ on purpose (see above) —
    # expected and harmless, but it exits non-zero on this codesign version,
    # which `system` would treat as a hard failure. Only actually fail on a
    # different error.
    codesign_output = %x(codesign --force --sign - #{(prefix/"Pitstop.app").to_s.shellescape} 2>&1)
    unless $?.success? || codesign_output.include?("unsealed contents present in the bundle root")
      odie "codesign failed:\n#{codesign_output}"
    end

    bin.install_symlink contents/"Helpers/pitstop"
  end

  def caveats
    <<~EOS
      Copy the menu bar app into Applications and start it:
        pitstop app install

      Run that again after every `brew upgrade pitstop`.
    EOS
  end

  test do
    assert_match "pitstop", shell_output("#{bin}/pitstop help")
  end
end