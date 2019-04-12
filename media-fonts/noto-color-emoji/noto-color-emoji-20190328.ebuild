# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

PYTHON_COMPAT=( python2_7 )

inherit eutils font python-single-r1

DESCRIPTION="NotoColorEmoji is colored emojis"
HOMEPAGE="https://www.google.com/get/noto/#emoji-qaae-color"
NOTO_EMOJI_COMMIT="e7490e1841094da518f4672398bdd74ee3c5fcac"
NOTO_TOOLS_COMMIT="9c4375f07c9adc00c700c5d252df6a25d7425870"
SRC_URI="https://github.com/googlei18n/noto-emoji/archive/${NOTO_EMOJI_COMMIT}.zip -> noto-emoji-${NOTO_EMOJI_COMMIT}.zip
         https://github.com/googlei18n/nototools/archive/${NOTO_TOOLS_COMMIT}.zip -> noto-tools-${NOTO_TOOLS_COMMIT}.zip"
# renamed from upstream's unversioned NotoColorEmoji-unhinted.zip
# version number based on the timestamp of most recently updated file in the zip

S="${WORKDIR}"

LICENSE="OFL-1.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="zopflipng optipng black-smiling-emoji" # black smiling emoji breaks utr#51
REQUIRED_USE="^^ ( zopflipng optipng ) ^^ ( $(python_gen_useflags 'python2*') )"

RDEPEND=">=media-libs/fontconfig-2.11.91
         >=x11-libs/cairo-1.16
	 media-libs/freetype[png]
         !media-fonts/noto-color-emoji-bin
	 !media-fonts/noto-emoji"

DEPEND="${RDEPEND}
        ${PYTHON_DEPS}
	dev-python/six
        media-gfx/imagemagick
        >=dev-python/fonttools-3.15.1[${PYTHON_USEDEP}]
        optipng? ( media-gfx/optipng )
	zopflipng? ( app-arch/zopfli )
	media-gfx/pngquant"

FONT_SUFFIX="ttf"
FONT_CONF=( )

S="${WORKDIR}/noto-emoji-${NOTO_EMOJI_COMMIT}"

pkg_setup() {
	python_setup
}

src_unpack() {
	unpack ${A}
	if use black-smiling-emoji ; then
		cp "${FILESDIR}/emoji_u263b.svg" "${S}/svg/"
		cp "${FILESDIR}/emoji_u263b.png" "${S}/png/128/"
	fi
}

src_prepare() {
	sed -i -e "s|from fontTools.misc.py23 import unichr|from six import unichr|" "${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}/nototools/unicode_data.py" || die "patch failed 1"
	if use zopflipng ; then
		sed -i -e 's|emoji: \$(EMOJI_FILES)|MISSING_OPTIPNG = fail\nundefine MISSING_ZOPFLI\nemoji: \$(EMOJI_FILES)|g' Makefile
	else
		sed -i -e 's|emoji: \$(EMOJI_FILES)|MISSING_ZOPFLI = fail\nundefine MISSING_OPTIPNG\nemoji: \$(EMOJI_FILES)|g' Makefile
	fi

	cd "${WORKDIR}/noto-emoji-${NOTO_EMOJI_COMMIT}"

	# Allow output
	sed -i -e "s|@(\$(PNGQUANT)|(\$(PNGQUANT)|g" Makefile || die
	sed -i -e "s|@convert|convert|g" Makefile || die
	sed -i -e "s|@./waveflag|./waveflag|g" Makefile || die
	if use optipng ; then
		sed -i -e "s|@\$(OPTIPNG)|\$(OPTIPNG)|g" Makefile || die
	fi
	if use zopflipng ; then
		sed -i -e "s|@\$(ZOPFLIPNG)|\$(ZOPFLIPNG)|g" Makefile || die
	fi

	epatch_user
}

src_compile() {
	if use optipng ; then
		export ZOPFLIPNG=
	else
		export OPTIPNG=
	fi

	export PYTHONPATH="${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}:${PYTHONPATH}"
	export PATH="${WORKDIR}/nototools-${NOTO_TOOLS_COMMIT}/nototools:${PATH}"
	emake || die "failed to compile font"
}

rebuild_fontfiles() {
        einfo "Refreshing fonts.scale and fonts.dir..."
        cd ${FONT_ROOT}
        mkfontdir -- ${FONT_TARGETS}
        if [ "${ROOT}" = "/" ] &&  [ -x /usr/bin/fc-cache ]
        then
                einfo "Updating font cache..."
                HOME="/root" /usr/bin/fc-cache -f ${FONT_TARGETS}
        fi
}

pkg_postinst() {
        rebuild_fontfiles
	fc-cache -fv
	einfo "To see emojis in your x11-term you need to switch to a utf8 locale."
	einfo "\`emerge media-fonts/noto-color-emoji-config\` to fix emojis on firefox, google-chrome, etc systemwide."
}

pkg_postrm() {
        rebuild_fontfiles
	fc-cache -fv
}
