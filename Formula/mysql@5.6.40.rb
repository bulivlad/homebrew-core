class MysqlAT5640 < Formula
  desc "Open source relational database management system"
  homepage "https://dev.mysql.com/doc/refman/5.6/en/"
  url "https://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.40.tar.gz"
  sha256 "1048a7abedba851efa62868e4d28d0be8828162b53903cd68e4f29546418d92d"
  revision 1

  bottle do
    sha256 "a3145660591369afee1c641ddcf42826b77782547fd85e54974d894e0e23e72f" => :catalina
    sha256 "965f73063ddf89afb3baa3ff1d8bd22636cd39011207bb748d465b9d881dca93" => :mojave
    sha256 "b3b0ca8146a2d477c8c37b5b9f7b775ea316fbc424ae30b04f8abe95e8c1c1f1" => :high_sierra
  end

  keg_only :versioned_formula

  depends_on "cmake" => :build
  depends_on "openssl@1.1"

  def datadir
    var/"mysql"
  end

  def install
    # Don't hard-code the libtool path. See:
    # https://github.com/Homebrew/homebrew/issues/20185
    inreplace "cmake/libutils.cmake",
      "COMMAND /usr/bin/libtool -static -o ${TARGET_LOCATION}",
      "COMMAND libtool -static -o ${TARGET_LOCATION}"

    # -DINSTALL_* are relative to `CMAKE_INSTALL_PREFIX` (`prefix`)
    args = %W[
      -DMYSQL_DATADIR=#{datadir}
      -DINSTALL_INCLUDEDIR=include/mysql
      -DINSTALL_MANDIR=share/man
      -DINSTALL_DOCDIR=share/doc/#{name}
      -DINSTALL_INFODIR=share/info
      -DINSTALL_MYSQLSHAREDIR=share/mysql
      -DWITH_SSL=yes
      -DDEFAULT_CHARSET=utf8
      -DDEFAULT_COLLATION=utf8_general_ci
      -DSYSCONFDIR=#{etc}
      -DCOMPILATION_COMMENT=Homebrew
      -DWITH_EDITLINE=system
      -DWITH_UNIT_TESTS=OFF
      -DWITH_EMBEDDED_SERVER=ON
      -DWITH_ARCHIVE_STORAGE_ENGINE=1
      -DWITH_BLACKHOLE_STORAGE_ENGINE=1
      -DENABLED_LOCAL_INFILE=1
      -DWITH_INNODB_MEMCACHED=1
    ]

    system "cmake", ".", *std_cmake_args, *args
    system "make"
    system "make", "install"

    # We don't want to keep a 240MB+ folder around most users won't need.
    (prefix/"mysql-test").cd do
      system "./mysql-test-run.pl", "status", "--vardir=#{Dir.mktmpdir}"
    end
    rm_rf prefix/"mysql-test"

    # Don't create databases inside of the prefix!
    # See: https://github.com/Homebrew/homebrew/issues/4975
    rm_rf prefix/"data"

    # Link the setup script into bin
    bin.install_symlink prefix/"scripts/mysql_install_db"

    # Fix up the control script and link into bin
    inreplace "#{prefix}/support-files/mysql.server",
              /^(PATH=".*)(")/, "\\1:#{HOMEBREW_PREFIX}/bin\\2"

    bin.install_symlink prefix/"support-files/mysql.server"

    libexec.install bin/"mysqlaccess"
    libexec.install bin/"mysqlaccess.conf"

    # Install my.cnf that binds to 127.0.0.1 by default
    (buildpath/"my.cnf").write <<~EOS
      # Default Homebrew MySQL server config
      [mysqld]
      # Only allow connections from localhost
      bind-address = 127.0.0.1
    EOS
    etc.install "my.cnf"
  end

  def post_install
    # Make sure the datadir exists
    datadir.mkpath
    unless (datadir/"mysql/general_log.CSM").exist?
      ENV["TMPDIR"] = nil
      system bin/"mysql_install_db", "--verbose", "--user=#{ENV["USER"]}",
        "--basedir=#{prefix}", "--datadir=#{datadir}", "--tmpdir=/tmp"
    end
  end

  def caveats; <<~EOS
    A "/etc/my.cnf" from another install may interfere with a Homebrew-built
    server starting up correctly.

    MySQL is configured to only allow connections from localhost by default

    To connect:
        mysql -uroot
  EOS
  end

  plist_options :manual => "#{HOMEBREW_PREFIX}/opt/mysql@5.6.40/bin/mysql.server start"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/mysqld_safe</string>
        <string>--datadir=#{datadir}</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{datadir}</string>
    </dict>
    </plist>
  EOS
  end

  test do
    # Expects datadir to be a completely clean dir, which testpath isn't.
    dir = Dir.mktmpdir
    system bin/"mysql_install_db", "--user=#{ENV["USER"]}",
    "--basedir=#{prefix}", "--datadir=#{dir}", "--tmpdir=#{dir}"

    pid = fork do
      exec bin/"mysqld", "--datadir=#{dir}"
    end
    sleep 2

    output = shell_output("curl 127.0.0.1:3306")
    output.force_encoding("ASCII-8BIT") if output.respond_to?(:force_encoding)
    assert_match version.to_s, output
  ensure
    Process.kill(9, pid)
    Process.wait(pid)
  end
end
