class Trafshow < Formula
  desc "Continuous network traffic display"
  # Upstream homepage down since late 2014, but only displays a manpage.
  homepage "https://web.archive.org/web/20130707021442/soft.risp.ru/trafshow/index_en.shtml"
  url "https://pkg.freebsd.org/ports-distfiles/trafshow-5.2.3.tgz"
  mirror "https://dl.bintray.com/homebrew/mirror/trafshow-5.2.3.tgz"
  sha256 "ea7e22674a66afcc7174779d0f803c1f25b42271973b4f75fab293b8d7db11fc"
  revision 1

  bottle do
    cellar :any_skip_relocation
    sha256 "a2a1419d6adb4663c41ae2f2d0eaaa750f0815caa34e9165a572c65d117173d3" => :big_sur
    sha256 "99d67c50de491e45032798b67f2b2ce424ff2b5031e453ac1bdcb1807f1af702" => :arm64_big_sur
    sha256 "f976f69242af3e7c14acd6cc99f0f6b14c31f15793a090a9fa1b562662efbf2d" => :catalina
    sha256 "27f0fa0ce96139f6958efdd964b3ef4741d39a05f86ce33567eb622c55b10717" => :mojave
    sha256 "d7d2f4fc92f234fd9fda9ec65a03b37aaf43d40203682ee3821526bb18f1ad13" => :high_sierra
    sha256 "c6324418840429d76f53035ae9e013190b8190f75f9fc1eaa8100bc9e7df27f8" => :sierra
    sha256 "c6bd1f502ddbcc756a400958f1f79da193c5784b7cd71361e1e6742412ae442c" => :el_capitan
    sha256 "fd7be4933f9be5a4a3ebaf0e31086e0f5566608305dd88779f0b0790fdc75c05" => :yosemite
  end

  depends_on "libtool" => :build

  {
    "domain_resolver.c" => "43b97d4ea025ed2087e4525a0b1acffc887082148df6dd2603b91fa70f79b678",
    "colormask.c"       => "04121b295d22a18aaf078611c75401a620570fbd89362bba2dd1abc042ea3c4a",
    "trafshow.c"        => "3164a612689d8ec310453a50fbb728f9bae3c356b88c41b6eab7ba7e925b1bf1",
    "trafshow.1"        => "8072e52acc56dd6f64c75f5d2e8a814431404b3fdfbc15149aaad1d469c47ff1",
    "configure"         => "c6e34dddd6c159cbd373b2b593f7643642cb10449c6bc6c606e160586bc5b794",
  }.each do |name, sha|
    patch :p0 do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/be6fd4a/trafshow/patch-#{name}"
      sha256 sha
    end
  end

  # libpcap on 10.12 has pcap_lib_version() instead of pcap_version
  if MacOS.version >= :sierra
    patch :p0 do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/7ad7c77/trafshow/patch-pcap-version-sierra.diff"
      sha256 "03213c8b8b46241ecef8f427cdbec9b09f5fdc35b9d67672ad4b370a1186aed5"
    end
  end

  def install
    cp Dir["#{Formula["libtool"].opt_pkgshare}/*/config.{guess,sub}"], buildpath

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--disable-slang"
    system "make"
    bin.install "trafshow"
    man1.install "trafshow.1"
    etc.install ".trafshow" => "trafshow.default"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/trafshow -v 2>&1", 1)
  end
end
