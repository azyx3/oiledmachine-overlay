# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="Command-line cloud music player for Linux with support for \
Spotify, Google Play Music, YouTube, SoundCloud, TuneIn, Plex \
servers and Chromecast devices."
HOMEPAGE="http://tizonia.org"
LICENSE="LGPL-3.0+"
KEYWORDS="~amd64 ~x86"
PYTHON_COMPAT=( python3_{6,7,8} )
inherit autotools distutils-r1 eutils flag-o-matic multilib-minimal
SLOT="0/${PV}"
IUSE="+aac +alsa +bash-completion blocking-etb-ftb blocking-sendcommand
 +boost +curl +dbus +file-io +flac +fuzzywuzzy +inproc-io
 mp4 +ogg +opus +lame +libsndfile +mad +mp3-metadata-eraser +mp2 +mpg123
 +player +pulseaudio +python +sdl +icecast-client +icecast-server
 -test +vorbis +vpx +webm +zsh-completion openrc systemd
 +chromecast +google-music +plex +soundcloud +spotify +tunein +youtube"
REQUIRED_USE="chromecast? ( player python boost curl dbus google-music )
	      dbus? ( || ( openrc systemd ) )
	      google-music? ( player python boost fuzzywuzzy curl )
	      icecast-client? ( player curl )
	      icecast-server? ( player )
	      mp2? ( mpg123 )
	      mp3-metadata-eraser? ( mpg123 )
	      ogg? ( curl )
	      openrc? ( dbus )
	      player? ( boost )
	      plex? ( player python boost fuzzywuzzy curl )
	      python? ( || ( chromecast google-music plex soundcloud spotify
			tunein youtube ) )
	      !python? ( !chromecast !google-music !plex !soundcloud !spotify
			!tunein !youtube )
	      soundcloud? ( player python boost fuzzywuzzy curl )
	      spotify? ( player python boost fuzzywuzzy )
	      tunein? ( player python boost fuzzywuzzy curl )
	      systemd? ( dbus )
	      youtube? ( player python boost fuzzywuzzy curl )
	      ^^ ( python_targets_python3_6
		   python_targets_python3_7
		   python_targets_python3_8 )"
# 3rd party repos may be required and add to package.unmask.  use layman -a
# =media-sound/tizonia-0.18.0::oiledmachine-overlay
# =dev-python/casttube-0.2.0::HomeAssistantRepository
# =dev-python/fuzzywuzzy-0.12.0::gentoo
# =dev-python/gmusicapi-12.1.1::palmer
# =dev-python/gpsoauth-0.4.1::palmer
# =dev-python/proboscis-1.2.6.0::palmer
# =dev-python/PyChromecast-3.2.2::HomeAssistantRepository
# =dev-python/pycryptodomex-3.7.3::palmer
# =dev-python/python-plexapi-3.0.6::oiledmachine-overlay
# =dev-python/soundcloud-python-9999.20151015::oiledmachine-overlay
# =dev-python/validictory-1.1.2::palmer
# =media-libs/nestegg-9999.20190603::oiledmachine-overlay

# keywords/unmask if using multilib with 32 bit
# dev-libs/libspotify::oiledmachine-overlay
# dev-libs/log4c::oiledmachine-overlay
# media-libs/liboggz::oiledmachine-overlay
# media-libs/opusfile::oiledmachine-overlay
# media-libs/libmp4v2::oiledmachine-overlay
# media-libs/libfishsound::oiledmachine-overlay

# masks if using multilib with 32 bit
# dev-libs/libspotify::gentoo
# media-libs/liboggz::gentoo
# media-libs/opusfile::gentoo
# media-libs/libmp4v2::gentoo
# media-libs/libfishsound::gentoo

#
# ogg_muxer requires curl, oggmuxsnkprc.c is work in progress.  ogg should
# work without curl for just strictly local playback only (as in non streaming
# player) tizonia
#
# >=dev-python/dnspython-1.16.0 added to avoid merge conflict between pycrypto
# and pycryptodome.  It should not be here but resolved in dnspython.
RDEPEND="aac? (  media-libs/faad2[${MULTILIB_USEDEP}] )
	 alsa? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] )
	 bash-completion? ( app-shells/bash )
	 boost? ( >=dev-libs/boost-1.54[${MULTILIB_USEDEP},python,${PYTHON_USEDEP}] )
	 chromecast? ( || ( dev-python/PyChromecast[${PYTHON_USEDEP}]
			    dev-python/pychromecast[${PYTHON_USEDEP}] ) )
	 curl? ( >=net-misc/curl-7.18.0[${MULTILIB_USEDEP}] )
	 flac? ( >=media-libs/flac-1.3.0[${MULTILIB_USEDEP}] )
	 fuzzywuzzy? ( dev-python/fuzzywuzzy[${PYTHON_USEDEP}] )
	 google-music? ( dev-python/gmusicapi[${PYTHON_USEDEP}] )
	 inproc-io? ( >=net-libs/zeromq-4.0.4[${MULTILIB_USEDEP}] )
	 lame? ( media-sound/lame[${MULTILIB_USEDEP}] )
	 ogg? ( >=media-libs/liboggz-1.1.1[${MULTILIB_USEDEP}] )
	 opus? ( >=media-libs/opusfile-0.5[${MULTILIB_USEDEP}] )
	 dbus? ( sys-apps/dbus[${MULTILIB_USEDEP}] )
	 libsndfile? ( >=media-libs/libsndfile-1.0.25[${MULTILIB_USEDEP}] )
	 mp4? ( media-libs/libmp4v2[${MULTILIB_USEDEP}] )
	 mad? ( media-libs/libmad[${MULTILIB_USEDEP}] )
	 mpg123? ( >=media-sound/mpg123-1.16.0[${MULTILIB_USEDEP}] )
	 opus? ( >=media-libs/opus-1.1[${MULTILIB_USEDEP}] )
	 player? ( >=media-libs/libmediainfo-0.7.65[${MULTILIB_USEDEP}]
		   >=media-libs/taglib-1.7.0[${MULTILIB_USEDEP}] )
	 plex? ( dev-python/python-plexapi[${PYTHON_USEDEP}] )
	 pulseaudio? ( >=media-sound/pulseaudio-1.1[${MULTILIB_USEDEP}] )
	 python? ( ${PYTHON_DEPS} )
	 sdl? ( media-libs/libsdl[${MULTILIB_USEDEP}] )
	 soundcloud? ( dev-python/soundcloud-python[${PYTHON_USEDEP}] )
	 spotify? ( >=dev-libs/libspotify-12.1.51[${MULTILIB_USEDEP}] )
	 >=sys-apps/util-linux-2.19.0[${MULTILIB_USEDEP}]
	 test? ( dev-db/sqlite:3[${MULTILIB_USEDEP}] )
	 vorbis? ( media-libs/libfishsound[${MULTILIB_USEDEP}] )
	 vpx? ( media-libs/libvpx[${MULTILIB_USEDEP}] )
	 youtube? ( dev-python/pafy[${PYTHON_USEDEP}]
		    net-misc/youtube-dl[${PYTHON_USEDEP}] )
	 webm? ( media-libs/nestegg[${MULTILIB_USEDEP}] )
	 zsh-completion? ( app-shells/zsh )"

DEPEND="${RDEPEND}
	>=dev-libs/check-0.9.4[${MULTILIB_USEDEP}]
	>=dev-libs/log4c-1.2.1[${MULTILIB_USEDEP}]"
SRC_URI=\
"https://github.com/tizonia/tizonia-openmax-il/archive/v${PV}.tar.gz \
	-> ${PN}-${PV}.tar.gz"
MY_PN="tizonia-openmax-il"
S="${WORKDIR}/${MY_PN}-${PV}"
RESTRICT="mirror"
_PATCHES=(
	"${FILESDIR}/tizonia-0.18.0-modular-1.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-2.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-3.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-4.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-5.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-6.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-7.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-8.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-9.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-10.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-11.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-12.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-13.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-14.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-15.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-16.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-17.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-18.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-19.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-20.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-21.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-22.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-23.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-24.patch"
	"${FILESDIR}/tizonia-0.18.0-modular-25.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-26.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-27.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-28.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-29.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-30.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-31.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-32.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-33.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-34.patch"
	"${FILESDIR}/tizonia-0.21.0-modular-35.patch"
)

src_prepare() {
	ewarn \
"You may need to completely uninstall ${PN} before building this package."
	default
	eapply ${_PATCHES[@]}
	multilib_copy_sources
	prepare_abi() {
		cd "${BUILD_DIR}" || die
		sed -i -e "s|/lib\"|/$(get_libdir)\"|g" \
			rm/tizrmd/m4/ax_lib_sqlite3.m4 || die
		eautoreconf
	}
	multilib_foreach_abi prepare_abi
}

multilib_src_configure() {
	python_foreach_impl python_configure_all
}

python_configure_all() {
	cd "${WORKDIR}/${MY_PN}-${PV}-${MULTILIB_ABI_FLAG}.${ABI}" || die
	L=$(find . -name "Makefile.am")
	for l in $L ; do
		einfo "Patching $l for -lboost_python to -lboost_${EPYTHON//./}"
		sed -i "s|-lboost_python36|-lboost_${EPYTHON//./}|g" $l || die
	done
	L=$(find . -name "*.pc.in")
	for l in $L ; do
		einfo "Patching $l for -lpython3.6m to -l${EPYTHON}m"
		sed -i "s|-lpython3.6m|-l${EPYTHON}m|g" $l || die
		einfo "Patching $l for -lboost_python36 to -lboost_${EPYTHON//./}"
		sed -i "s|-lboost_python36|-lboost_${EPYTHON//./}|g" $l || die
	done
	local myconf
	if use bash-completion ; then
		myconf+=" --with-bashcompletiondir=/usr/share/bash-completion/completions"
	else
		myconf+=" --without-bashcompletiondir"
	fi
	if use zsh-completion ; then
		myconf+=" --with-zshcompletiondir=/usr/share/zsh/vendor-completions"
	else
		myconf+=" --without-zshcompletiondir"
	fi
	if use icecast-client || use google-music || use plex \
		|| use soundcloud || use tunein || use youtube ; then
		myconf+=" --with-http-source"
	else
		myconf+=" --without-http-source"
	fi

	PYTHON_LIBS="-L/usr/$(get_libdir) -l${EPYTHON}m" \
	PYTHON_SITE_PKG="/usr/$(get_libdir)/${EPYTHON}/site-packages" \
	PKG_CONFIG="/usr/bin/$(get_abi_CHOST ${ABI})-pkg-config" \
	econf \
		$(use_with aac) \
		$(use_with alsa) \
		$(use_with bash-completion) \
		$(use_enable blocking-sendcommand) \
		$(use_enable blocking-etb-ftb) \
		$(use_with boost) \
		$(multilib_native_use_with chromecast) \
		$(use_with curl) \
		$(use_with dbus) \
		$(use_with file-io) \
		$(use_with flac) \
		$(multilib_native_use_with google-music gmusic) \
		$(use_with icecast-client) \
		$(use_with icecast-server) \
		$(use_with inproc-io) \
		$(use_with lame) \
		$(use_with libsndfile) \
		$(use_with mp3-metadata-eraser) \
		$(use_with mp4) \
		$(use_with ogg) \
		$(use_with openrc) \
		$(use_with opus) \
		$(multilib_native_use_enable player) \
		$(use_with mad) \
		$(use_with mp2) \
		$(multilib_native_use_with plex) \
		$(use_with pulseaudio) \
		$(use_with sdl) \
		$(multilib_native_use_with soundcloud) \
		$(multilib_native_use_with spotify) \
		$(multilib_native_use_with tunein) \
		$(use_with systemd) \
		$(use_enable test) \
		$(use_with vorbis) \
		$(use_with vpx vp8) \
		$(use_with webm) \
		$(multilib_native_use_with youtube) \
		$(use_with zsh-completion) \
		${myconf} || die
}


multilib_src_compile() {
	python_foreach_impl python_compile_all
}

python_compile_all() {
	emake || die
}

multilib_src_install() {
	python_foreach_impl python_install_all
	if use openrc ; then
		dodir /etc/init.d
		exeinto /etc/init.d
		doexe "${FILESDIR}/tizrmd"
	fi
	if use systemd ; then
		dodir /usr/lib/systemd/system/
		mv "${D}"/usr/share/dbus-1/services/com.aratelia.tiz.rm.service \
			"${D}"/usr/lib/systemd/system/ || die
	else
		rm -rf "${D}"/usr/share/dbus-1/services/com.aratelia.tiz.rm.service \
			|| die
	fi
}

python_install_all() {
	emake DESTDIR="${D}" install
	# fixes header mismatch
	if ! multilib_is_native_abi ; then
		insinto /usr/include/tizonia/
		if use chromecast ; then
			pushd clients/chromecast/libtizchromecast/src || die
			doins tizchromecastctxtypes.h \
				tizchromecastctx_c.h \
				tizchromecast_c.h \
				tizchromecastctx.hpp \
				tizchromecast.hpp \
				tizchromecasttypes.h
			popd
		fi
		if use google-music ; then
			pushd clients/gmusic/libtizgmusic/src || die
			doins tizgmusic.hpp tizgmusic_c.h
			popd
		fi
		if use plex ; then
			pushd clients/plex/libtizplex/src || die
			doins tizplex.hpp tizplex_c.h
			popd
		fi
		if use soundcloud ; then
			pushd clients/soundcloud/libtizsoundcloud/src || die
			doins tizsoundcloud.hpp tizsoundcloud_c.h
			popd
		fi
		if use spotify ; then
			pushd clients/spotify/libtizspotify/src || die
			doins tizspotify.hpp tizspotify_c.h
			popd
		fi
		if use tunein ; then
			pushd clients/tunein/libtiztunein/src || die
			doins tiztunein.hpp tiztunein_c.h
			popd
		fi
		if use youtube ; then
			pushd clients/youtube/libtizyoutube/src || die
			doins tizyoutube.hpp tizyoutube_c.h
			popd
		fi
	fi
}

multilib_src_install_all() {
	einstalldocs
}

pkg_postrm() {
	if use openrc ; then
		rc-update add tizrmd
		/etc/init.d/tizrmd start
	fi
	if use systemd ; then
		systemctl enable com.aratelia.tiz.rm.service
		systemctl start com.aratelia.tiz.rm.service
	fi
}

pkg_prerm() {
	if use openrc ; then
		/etc/init.d/tizrmd stop
		rc-update delete tizrmd
	fi
	if use systemd ; then
		systemctl disable com.aratelia.tiz.rm.service
		systemctl stop com.aratelia.tiz.rm.service
	fi
}
