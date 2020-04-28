class Fasttext < Formula
  desc "Library for fast text representation and classification"
  homepage "https://fasttext.cc"
  url "https://github.com/facebookresearch/fastText/archive/v0.9.2.tar.gz"
  sha256 "7ea4edcdb64bfc6faaaec193ef181bdc108ee62bb6a04e48b2e80b639a99e27e"
  head "https://github.com/facebookresearch/fastText.git"

  bottle do
    cellar :any
    sha256 "ec085551ced1f55b863a65aa60ad8f31d796002702b7effaaaafbf1490df867f" => :catalina
    sha256 "79f08167fb55b478829434be84d919c08c888563e0abbdeb66bc19cd3e82457f" => :mojave
    sha256 "4602a32c2a373ed97de8fd36bf1e998299682d45e465af39026a32a3a06fe574" => :high_sierra
  end

  depends_on "cmake" => :build

  def install
    system "cmake", ".", *std_cmake_args
    system "make", "install"
  end

  test do
    (testpath/"trainingset").write("__label__brew brew")
    system "#{bin}/fasttext", "supervised", "-input", "trainingset", "-output", "model"
    assert_predicate testpath/"model.bin", :exist?
  end
end
