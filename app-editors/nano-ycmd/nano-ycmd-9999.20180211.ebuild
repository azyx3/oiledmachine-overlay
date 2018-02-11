# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

PYTHON_COMPAT=( python{2_7,3_4,3_5} )

inherit eutils flag-o-matic python-r1
COMMIT="14e4255c52c9f64cabaa2af28354e9752d27ae65"
SRC_URI="https://github.com/orsonteodoro/nano-ycmd/archive/${COMMIT}.zip -> ${P}.zip"
KEYWORDS="~amd64 ~x86"

DESCRIPTION="GNU GPL'd Pico clone with more functionality with ycmd support"
HOMEPAGE="https://www.nano-editor.org/ https://wiki.gentoo.org/wiki/Nano/Basics_Guide"

LICENSE="GPL-3 LGPL-2+"
SLOT="0"
IUSE="debug justify +magic minimal ncurses nls slang +spell static unicode nettle openssl libgcrypt openmp"
REQUIRED_USE="^^ ( nettle openssl libgcrypt ) python_targets_python2_7 ${PYTHON_REQUIRED_USE}"

LIB_DEPEND=">=sys-libs/ncurses-5.9-r1:0=[unicode?]
	sys-libs/ncurses:0=[static-libs(+)]
	magic? ( sys-apps/file[static-libs(+)] )
	nls? ( virtual/libintl )
	!ncurses? ( slang? ( sys-libs/slang[static-libs(+)] ) )"
RDEPEND="${PYTHON_DEPS}
         !static? ( ${LIB_DEPEND//\[static-libs(+)]} )
         app-editors/nano
         openssl? ( dev-libs/openssl
                    dev-libs/glib )
         nettle? ( dev-libs/nettle )
         libgcrypt? ( dev-libs/libgcrypt )
         net-libs/neon
         >=dev-util/ycmd-9999.20171228[${PYTHON_USEDEP}]
	 >=app-shells/bash-4
	 dev-util/bear
         dev-libs/nxjson
         dev-util/ninja
	 dev-util/ycm-generator[python_targets_python2_7]
         dev-util/compdb"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	virtual/pkgconfig
	static? ( ${LIB_DEPEND} )"
S="${WORKDIR}/${PN}-${COMMIT}"

src_prepare() {
	eapply "${FILESDIR}/${PN}-9999.20180201-rename-as-ynano.patch"

	#eautoreconf
	./autogen.sh
	default
}

src_configure() {
	use static && append-ldflags -static
	local myconf=()
	case ${CHOST} in
	*-gnu*|*-uclibc*) myconf+=( "--with-wordbounds" ) ;; #467848
	esac

	local ycmd_python=
	local ycmd_python_impl=

	if use python_targets_python3_5 ; then
		ycmd_python="/usr/bin/python3"
		ycmd_python_impl="python3.5"
	elif use python_targets_python3_4 ; then
		ycmd_python="/usr/bin/python3"
		ycmd_python_impl="python3.4"
	elif use python_targets_python2_7 ; then
		ycmd_python="/usr/bin/python2"
		ycmd_python_impl="python2.7"
	fi

	einfo "ycmd_python_impl=$ycmd_python_impl"
	einfo "ycmd_python=$ycmd_python"

	NINJA_PATH="/usr/bin/ninja" \
        YCMG_PATH="/usr/bin/config_gen.py" YCMD_PYTHON_PATH="$ycmd_python" YCMG_PYTHON_PATH="/usr/bin/python2" RACERD_PATH="/usr/bin/racerd" RUST_SRC_PATH="/usr/share/rust/src" GODEF_PATH="/usr/bin/godef" GOCODE_PATH="/usr/bin/gocode" YCMD_PATH="/usr/$(get_libdir)/${ycmd_python_impl}/site-packages/ycmd" \
	econf \
		--bindir="${EPREFIX}"/bin \
		--htmldir=/trash \
		$(use_enable !minimal color) \
		$(use_enable !minimal multibuffer) \
		$(use_enable !minimal nanorc) \
		--disable-wrapping-as-root \
		$(use_enable magic libmagic) \
		$(use_enable spell speller) \
		$(use_enable justify) \
		$(use_enable debug) \
		$(use_enable nls) \
		$(use_enable unicode utf8) \
		$(use_enable minimal tiny) \
		$(usex ncurses --without-slang $(use_with slang)) \
                --enable-ycmd \
                $(use_with openssl) \
                $(use_with nettle) \
                $(use_with libgcrypt) \
		$(use_with openmp) \
		"${myconf[@]}"
}

src_install() {
	default
	rm -rf "${D}"/trash

	dodoc doc/sample.nanorc
	docinto html
	dodoc doc/faq.html
	insinto /etc
	newins doc/sample.nanorc nanorc
	if ! use minimal ; then
		# Enable colorization by default.
		sed -i \
			-e '/^# include /s:# *::' \
			"${ED}"/etc/nanorc || die
	fi

	dodir /usr/bin
	dosym /bin/ynano /usr/bin/ynano

	#remove merge conflicts
	rm -rf "${D}/usr/share"
	rm -rf "${D}/etc/"
	rm -rf "${D}/bin/rnano"
}
