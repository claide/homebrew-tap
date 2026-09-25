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

    # Swift's generated Bundle.module accessor looks for this bundle at the
    # app's own root (sibling of Contents) — confirmed directly from its
    # runtime error message. It must NOT go in Contents/MacOS or
    # Contents/Resources: codesign rejects a plain resource bundle there,
    # and Bundle.module doesn't look there anyway.
    bundle = Dir[".build/release/Pitstop_Pitstop.bundle"].first
    FileUtils.cp_r bundle, prefix/"Pitstop.app" if bundle

    # Ad-hoc signatures. Built locally, so Gatekeeper doesn't quarantine it.
    system "codesign", "--force", "--sign", "-", contents/"Helpers/pitstop"
    system "codesign", "--force", "--sign", "-", prefix/"Pitstop.app"

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
