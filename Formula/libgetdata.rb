class Libgetdata < Formula
  desc "Reference implementation of the Dirfile Standards"
  homepage "https://getdata.sourceforge.io/"
  # TODO: Check if extra `make` call can be removed at version bump.
  url "https://downloads.sourceforge.net/project/getdata/getdata/0.11.0/getdata-0.11.0.tar.xz"
  sha256 "d16feae0907090047f5cc60ae0fb3500490e4d1889ae586e76b2d3a2e1c1b273"
  license "LGPL-2.1-or-later"

  bottle do
    sha256 cellar: :any,                 arm64_monterey: "4e167251c910442b10cd6c7da9c7dd0f3ded3926669c87d618f2330e8c76af82"
    sha256 cellar: :any,                 arm64_big_sur:  "e8a11d9e2b1ab217a0984ba6dffd8f7bf721df6d1846f9d7ec07c3fa9816c808"
    sha256 cellar: :any,                 monterey:       "3050afede9476adb4b8af36a097218742decd02873eb20a9dc8e3876a1c6b085"
    sha256 cellar: :any,                 big_sur:        "8d192c117f205049f5547300b397c792d35d8d5f95854043563d02ca144b1a11"
    sha256 cellar: :any,                 catalina:       "8d05ffb11f957a9dc351f4b969c4d63d5878b5099c18efd6a4c454cb2b3a7069"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "c9ea4ca51936e1f4a68e32eba62aca9e3edc2b8c1eb078c5045d34637dcc2f97"
  end

  depends_on "libtool"

  uses_from_macos "perl"
  uses_from_macos "zlib"

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--disable-fortran",
                          "--disable-fortran95",
                          "--disable-php",
                          "--disable-python",
                          "--without-liblzma",
                          "--without-libzzip"

    ENV.deparallelize # can't open file: .libs/libgetdatabzip2-0.11.0.so (No such file or directory)
    system "make"
    # The Makefile seems to try to install things in the wrong order.
    # Remove this when the following PR is merged/resolved and lands in a release:
    # https://github.com/ketiltrout/getdata/pull/6
    system "make", "-C", "bindings/perl", "install-nodist_perlautogetdataSCRIPTS"
    system "make", "install"
  end

  test do
    assert_match "GetData #{version}", shell_output("#{bin}/checkdirfile --version", 1)
  end
end
