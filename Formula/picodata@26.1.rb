class PicodataAT261 < Formula
  desc "Picodata in-memory database and Rust application server"
  homepage "https://picodata.io/"
  url "https://download.picodata.io/tarantool-picodata/sources/picodata-26.1.1.0.tar.xz"
  sha256 "6861d4877a66d3b5d9ff3b0194081a7446163331bfdefba00b71d569621921eb"
  license "BSD-2-Clause"
  version_scheme 1
  head "https://git.picodata.io/core/picodata.git", branch: "26.1"

  livecheck do
    url :head
    strategy :git
  end

  bottle do
    root_url "https://download.picodata.io/tarantool-picodata/macos"
    sha256 cellar: :any,  arm64_sonoma:     "cac95889ce5565c226e7859fa157df067a352fc45b2765df1e6d5864f55463df"
    sha256 cellar: :any,  arm64_sequoia:    "cac95889ce5565c226e7859fa157df067a352fc45b2765df1e6d5864f55463df"
    sha256 cellar: :any,  arm64_tahoe:      "cac95889ce5565c226e7859fa157df067a352fc45b2765df1e6d5864f55463df"
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

    if OS.mac?
      if MacOS.version >= :big_sur
        sdk = MacOS.sdk_path_if_needed
        lib_suffix = "tbd"
      else
        sdk = ""
        lib_suffix = "dylib"
      end
    end

    system "make"
    system "make", "install"
  end

  test do
    system bin/"picodata", "test"
  end
end
