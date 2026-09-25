class Pitstop < Formula
  desc "Menu bar AI quota tracker with a quota check for ticket workflows"
  homepage "https://github.com/claide/pitstop"
  url "https://github.com/claide/pitstop/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "ddd3a2c251754f6995ee798414948f450be099882ddb4ca08e5088dbb169058f"
  license "MIT"

  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "--configuration", "release"

    contents = prefix/"Pitstop.app/Contents"
    (contents/"MacOS").install ".build/release/Pitstop"
    (contents/"Helpers").install ".build/release/PitstopCLI" => "pitstop"
    contents.install "Resources/Info.plist"

    # Swift's generated Bundle.module accessor looks for this bundle next to the
    # executable (and, for an .app, at the bundle root too), so it has to ship as
    # part of the app, not just sit in .build. Its name is always <package>_<target>.
    bundle = Dir[".build/release/Pitstop_Pitstop.bundle"].first
    if bundle
      FileUtils.cp_r bundle, contents/"MacOS"
      FileUtils.cp_r bundle, prefix
    end

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
