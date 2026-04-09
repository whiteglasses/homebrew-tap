class TarantoolPicodataAT211 < Formula
  desc "Picodata fork tarantool in-memory database and Lua application server"
  homepage "https://picodata.io/"
  url "https://download.picodata.io/tarantool-picodata/sources/tarantool-picodata-2.11.8.341.tar.xz"
  sha256 "9c5b9f0cf7e1992f918bd398b528ba0437e240d3c00020de14193284183bee9b"
  license "BSD-2-Clause"
  version_scheme 1
  head "https://git.picodata.io/picodata/tarantool.git", branch: "2.11.8-picodata"

  livecheck do
    url :head
    strategy :git
  end

  bottle do
    root_url "https://download.picodata.io/tarantool-picodata/macos"
    sha256 cellar: "/opt/homebrew/Cellar",  arm64_sonoma:    "1aa87c59254edaa6b11569a67283f823a5a8e60a1f296ba89c44e4158ef736d9"
    sha256 cellar: "/opt/homebrew/Cellar",  arm64_sequoia:   "1aa87c59254edaa6b11569a67283f823a5a8e60a1f296ba89c44e4158ef736d9"
    sha256 cellar: "/opt/homebrew/Cellar",  arm64_tahoe:     "1aa87c59254edaa6b11569a67283f823a5a8e60a1f296ba89c44e4158ef736d9"
  end

  depends_on "cmake" => :build
  depends_on "icu4c"
  depends_on "libyaml"
  depends_on "openssl@3"
  depends_on "readline"
  depends_on "zstd"

  uses_from_macos "curl"
  uses_from_macos "ncurses"

  def install
    # Avoid keeping references to Homebrew's clang/clang++ shims
    inreplace "src/trivia/config.h.cmake",
              "#define COMPILER_INFO \"@CMAKE_C_COMPILER_ID@-@CMAKE_C_COMPILER_VERSION@\"",
              "#define COMPILER_INFO \"/usr/bin/clang /usr/bin/clang++\""

    args = std_cmake_args
    args << "-DCMAKE_INSTALL_MANDIR=#{doc}"
    args << "-DCMAKE_INSTALL_SYSCONFDIR=#{etc}"
    args << "-DCMAKE_INSTALL_LOCALSTATEDIR=#{var}"
    args << "-DENABLE_DIST=ON"
    args << "-DOPENSSL_ROOT_DIR=#{Formula["openssl@1.1"].opt_prefix}"
    args << "-DREADLINE_ROOT=#{Formula["readline"].opt_prefix}"
    args << "-DENABLE_BUNDLED_LIBCURL=OFF"
    args << "-DENABLE_BUNDLED_LIBYAML=OFF"
    args << "-DENABLE_BUNDLED_ZSTD=OFF"

    if OS.mac?
      if MacOS.version >= :big_sur
        sdk = MacOS.sdk_path_if_needed
        lib_suffix = "tbd"
      else
        sdk = ""
        lib_suffix = "dylib"
      end

      args << "-DCURL_INCLUDE_DIR=#{sdk}/usr/include"
      args << "-DCURL_LIBRARY=#{sdk}/usr/lib/libcurl.#{lib_suffix}"
      args << "-DCURSES_NEED_NCURSES=ON"
      args << "-DCURSES_NCURSES_INCLUDE_PATH=#{sdk}/usr/include"
      args << "-DCURSES_NCURSES_LIBRARY=#{sdk}/usr/lib/libncurses.#{lib_suffix}"
      args << "-DICONV_INCLUDE_DIR=#{sdk}/usr/include"
    else
      args << "-DCURL_ROOT=#{Formula["curl"].opt_prefix}"
    end

    system "cmake", ".", *args
    system "make"
    system "make", "install"
  end

  def post_install
    local_user = ENV["USER"]
    inreplace etc/"default/tarantool", /(username\s*=).*/, "\\1 '#{local_user}'"

    (var/"lib/tarantool").mkpath
    (var/"log/tarantool").mkpath
    (var/"run/tarantool").mkpath
  end

  test do
    (testpath/"test.lua").write <<~EOS
      box.cfg{}
      local s = box.schema.create_space("test")
      s:create_index("primary")
      local tup = {1, 2, 3, 4}
      s:insert(tup)
      local ret = s:get(tup[1])
      if (ret[3] ~= tup[3]) then
        os.exit(-1)
      end
      os.exit(0)
    EOS
    system bin/"tarantool", "#{testpath}/test.lua"
  end
end
