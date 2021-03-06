# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# For requirements, see
# https://github.com/emscripten-core/emscripten/blob/master/site/source/docs/building_from_source/toolchain_what_is_needed.rst

EAPI=7
DESCRIPTION="Emscripten LLVM backend - Fastcomp is the default compiler core for Emscripten"
HOMEPAGE="http://emscripten.org/"
LICENSE="all-rights-reserved BSD BSD-2 emscripten-fastcomp-md5 GPL-2+ LLVM-Grant MIT rc UoI-NCSA"
# for emscripten-fastcomp:
#   ARM contributions (lib/Target/ARM) - LLVM-Grant
#   cmake/config.guess - GPL-2+
#   googlemock (utils/unittest/googlemock) - BSD
#   Google Test (utils/unittest/googletest) - BSD
#   LLVM System Interface Library (include/llvm/Support) - UoI-NCSA
#   lib/Support/xxhash.cpp - BSD-2
#   md5 contributions (lib/Support/MD5.cpp) - public domain + emscripten-fastcomp-md5 (no warranty)
#   pyyaml tests (test/YAMLParser) - MIT
#   OpenBSD regex (lib/Support/reg*) - BSD rc
#   tools/gold (for lto, not installed, uses system's plugin-api.h) - GPL-3+ if built
#
# for emscripten-fastcomp-clang:
#   ClangFormat, clang-format-vs - UoI-NCSA
#
# The MIT license in LICENSE file doesn't have all rights reserved like it did
# with the dev-util/emscripten package, but it is understood that the src is
#   all-rights-reserved || ( MIT UoI-NCSA )
#
KEYWORDS="~amd64 ~x86"
PYTHON_COMPAT=( python3_{6,7,8} )
inherit python-single-r1
SLOT="0"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
MY_DEPEND="${PYTHON_DEPS}
	>=net-libs/nodejs-0.12.6"
RDEPEND="${MY_DEPEND}
	>=virtual/jre-1.5"
DEPEND="${MY_DEPEND}
	>=dev-util/cmake-3.4.3"
BDEPEND="dev-cpp/gtest
	>=dev-util/cmake-3.4.3
	>=net-libs/nodejs-0.12.6"
inherit cmake-utils
SRC_URI="\
https://github.com/kripken/${PN}/archive/${PV}.tar.gz \
	-> ${P}.tar.gz
https://github.com/kripken/${PN}-clang/archive/${PV}.tar.gz \
	-> ${PN}-clang-${PV}.tar.gz"
_PATCHES=(
	"${FILESDIR}/${PN}-1.39.11-cmake.patch"
	"${FILESDIR}/${PN}-1.39.11-version_cpp.patch"
)
RESTRICT="mirror"

src_prepare() {
	pushd "${WORKDIR}" || die
		eapply ${_PATCHES[@]}
		eapply_user
	popd
	CMAKE_USE_DIR="${WORKDIR}/${PN}-${PV}" \
	cmake-utils_src_prepare
}

src_configure() {
	# create symlink to tools/clang
	ln -s "${WORKDIR}/${PN}-clang-${PV}/" "${WORKDIR}/${P}/tools/clang" \
		|| die "Could not create symlink to tools/clang"
	ln -s "${WORKDIR}/${P}/tools/clang/emscripten-version.txt" \
		"${WORKDIR}/${P}/tools/clang/lib/Basic/emscripten-version.txt" \
		|| die "Could not create symlink to tools/clang/emscripten-version.txt"
	local mycmakeargs=(
		-DCLANG_INCLUDE_DOCS=OFF
		-DCLANG_INCLUDE_EXAMPLES=OFF
		-DCLANG_INCLUDE_TESTS=OFF
		# avoid clashes with sys-devel/llvm
		-DCMAKE_INSTALL_PREFIX="/usr/share/${P}"
		-DLLVM_TARGETS_TO_BUILD="X86;JSBackend"
		-DLLVM_INCLUDE_DOCS=OFF
		-DLLVM_INCLUDE_EXAMPLES=OFF
		-DLLVM_INCLUDE_TESTS=OFF
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
	cat "${WORKDIR}/${PN}-${PV}/lib/Support/xxhash.cpp" \
		| head -n 33 > "${T}/LICENSE.xxhash" || die
	dodoc "${T}/LICENSE.xxhash"
	cat "${WORKDIR}/${PN}-${PV}/lib/Support/MD5.cpp" \
		| head -n 38 > "${T}/LICENSE.MD5" || die
	dodoc "${T}/LICENSE.MD5"
	dodoc "${WORKDIR}/${PN}-${PV}/LICENSE.TXT"
	cat "${WORKDIR}/${PN}-${PV}/include/llvm/Support/LICENSE.TXT" \
		> "${T}/LICENSE.LLVM_System_Interface_Library.TXT" || die
	dodoc "${T}/LICENSE.LLVM_System_Interface_Library.TXT"
	cat "${WORKDIR}/${PN}-${PV}/CODE_OWNERS.TXT" \
		> "${T}/CODE_OWNERS.LLVM.TXT"
	dodoc "${T}/CODE_OWNERS.LLVM.TXT"
	cat "${WORKDIR}/${PN}-clang-${PV}/CODE_OWNERS.TXT" \
		> "${T}/CODE_OWNERS.Clang.TXT"
	dodoc "${T}/CODE_OWNERS.Clang.TXT"
}
