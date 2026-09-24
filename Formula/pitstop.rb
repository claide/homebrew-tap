class Pitstop < Formula
  desc "Menu bar AI quota tracker with a quota check for ticket workflows"
  homepage "https://github.com/claide/pitstop"
  url "https://github.com/claide/pitstop/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "75fcc766882f799302f34be7f82792daac9edf41bbec53d68c20d8587e692c9b"
  license "MIT"

  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "--configuration", "release"

    contents = prefix/"Pitstop.app/Contents"
    (contents/"MacOS").install ".build/release/Pitstop"
    (contents/"Helpers").install ".build/release/PitstopCLI" => "pitstop"
    contents.install "Resources/Info.plist"

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
