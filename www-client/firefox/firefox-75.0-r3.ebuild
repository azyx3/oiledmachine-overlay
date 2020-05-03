# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
VIRTUALX_REQUIRED="pgo"
WANT_AUTOCONF="2.1"
MOZ_ESR=""

PYTHON_COMPAT=( python3_{6,7,8} )
PYTHON_REQ_USE='ncurses,sqlite,ssl,threads(+)'

# This list can be updated with scripts/get_langs.sh from the mozilla overlay
MOZ_LANGS=(ach af an ar ast az be bg bn br bs ca cak cs cy da de dsb el en en-CA
en-GB en-US eo es-AR es-CL es-ES es-MX et eu fa ff fi fr fy-NL ga-IE gd gl gn gu-IN
he hi-IN hr hsb hu hy-AM ia id is it ja ka kab kk km kn ko lij lt lv mk mr ms my
nb-NO nl nn-NO oc pa-IN pl pt-BR pt-PT rm ro ru si sk sl son sq sr sv-SE ta te
th tr uk ur uz vi xh zh-CN zh-TW )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_alpha/a}" # Handle alpha for SRC_URI
MOZ_PV="${MOZ_PV/_beta/b}" # Handle beta for SRC_URI
MOZ_PV="${MOZ_PV%%_rc*}" # Handle rc for SRC_URI

if [[ ${MOZ_ESR} == 1 ]] ; then
	# ESR releases have slightly different version numbers
	MOZ_PV="${MOZ_PV}esr"
fi

# Patch version
PATCH="${PN}-75.0-patches-7"

MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"
MOZ_SRC_URI="${MOZ_HTTP_URI}/${MOZ_PV}/source/firefox-${MOZ_PV}.source.tar.xz"

if [[ "${PV}" == *_rc* ]]; then
	MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/candidates/${MOZ_PV}-candidates/build${PV##*_rc}"
	MOZ_LANGPACK_PREFIX="linux-i686/xpi/"
	MOZ_SRC_URI="${MOZ_HTTP_URI}/source/${PN}-${MOZ_PV}.source.tar.xz -> $P.tar.xz"
fi

LLVM_MAX_SLOT=10

inherit check-reqs eapi7-ver flag-o-matic toolchain-funcs eutils \
		gnome2-utils llvm mozcoreconf-v6 multiprocessing \
		pax-utils xdg-utils autotools mozlinguas-v2 virtualx \
		eapi7-ver
inherit multilib-minimal

DESCRIPTION="Firefox Web Browser"
HOMEPAGE="https://www.mozilla.com/firefox"

KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"

SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist clang cpu_flags_x86_avx2 debug eme-free geckodriver
	+gmp-autoupdate hardened hwaccel jack lto cpu_flags_arm_neon pgo
	pulseaudio +screenshot selinux startup-notification +system-av1
	+system-harfbuzz +system-icu +system-jpeg +system-libevent +system-libvpx
	+system-webp test wayland wifi"
_ABIS="abi_x86_32 abi_x86_64 abi_x86_x32 abi_mips_n32 abi_mips_n64 abi_mips_o32 abi_ppc_32 abi_ppc_64 abi_s390_32 abi_s390_64"
IUSE+=" ${_ABIS}"
IUSE+=" +jemalloc"

REQUIRED_USE="pgo? ( lto )"
REQUIRED_USE+=" ^^ ( ${_ABIS} )"

RESTRICT="!bindist? ( bindist )
	!test? ( test )"

PATCH_URIS=( https://dev.gentoo.org/~{whissi,anarchy,polynomial-c,axs}/mozilla/patchsets/${PATCH}.tar.xz )
SRC_URI="${SRC_URI}
	${MOZ_SRC_URI}
	${PATCH_URIS[@]}"

CDEPEND="
	>=dev-libs/nss-3.51[${MULTILIB_USEDEP}]
	>=dev-libs/nspr-4.25[${MULTILIB_USEDEP}]
	dev-libs/atk[${MULTILIB_USEDEP}]
	dev-libs/expat[${MULTILIB_USEDEP}]
	>=x11-libs/cairo-1.10[X,${MULTILIB_USEDEP}]
	>=x11-libs/gtk+-2.18:2[${MULTILIB_USEDEP}]
	>=x11-libs/gtk+-3.4.0:3[X,${MULTILIB_USEDEP}]
	x11-libs/gdk-pixbuf[${MULTILIB_USEDEP}]
	>=x11-libs/pango-1.22.0[${MULTILIB_USEDEP}]
	>=media-libs/libpng-1.6.35:0=[apng,${MULTILIB_USEDEP}]
	>=media-libs/mesa-10.2:*[${MULTILIB_USEDEP}]
	media-libs/fontconfig[${MULTILIB_USEDEP}]
	>=media-libs/freetype-2.4.10[${MULTILIB_USEDEP}]
	kernel_linux? ( !pulseaudio? ( media-libs/alsa-lib[${MULTILIB_USEDEP}] ) )
	virtual/freedesktop-icon-theme
	sys-apps/dbus[${MULTILIB_USEDEP}]
	dev-libs/dbus-glib[${MULTILIB_USEDEP}]
	startup-notification? ( >=x11-libs/startup-notification-0.8[${MULTILIB_USEDEP}] )
	>=x11-libs/pixman-0.19.2[${MULTILIB_USEDEP}]
	>=dev-libs/glib-2.26:2[${MULTILIB_USEDEP}]
	>=sys-libs/zlib-1.2.3[${MULTILIB_USEDEP}]
	>=dev-libs/libffi-3.0.10:=[${MULTILIB_USEDEP}]
	|| ( >=media-video/libav-9.12[${MULTILIB_USEDEP}]
	     >=media-video/ffmpeg-1.2.6-r1:0[${MULTILIB_USEDEP}] )
	x11-libs/libX11[${MULTILIB_USEDEP}]
	x11-libs/libXcomposite[${MULTILIB_USEDEP}]
	x11-libs/libXdamage[${MULTILIB_USEDEP}]
	x11-libs/libXext[${MULTILIB_USEDEP}]
	x11-libs/libXfixes[${MULTILIB_USEDEP}]
	x11-libs/libXrender[${MULTILIB_USEDEP}]
	x11-libs/libXt[${MULTILIB_USEDEP}]
	system-av1? (
		>=media-libs/dav1d-0.3.0:=[${MULTILIB_USEDEP}]
		>=media-libs/libaom-1.0.0:=[${MULTILIB_USEDEP}]
	)
	system-harfbuzz? ( >=media-libs/harfbuzz-2.6.4:0=[${MULTILIB_USEDEP}] >=media-gfx/graphite2-1.3.13[${MULTILIB_USEDEP}] )
	system-icu? ( >=dev-libs/icu-64.1:=[${MULTILIB_USEDEP}] )
	system-jpeg? ( >=media-libs/libjpeg-turbo-1.2.1[${MULTILIB_USEDEP}] )
	system-libevent? ( >=dev-libs/libevent-2.0:0=[threads,${MULTILIB_USEDEP}] )
	system-libvpx? ( >=media-libs/libvpx-1.8.2:0=[postproc,${MULTILIB_USEDEP}] )
	system-webp? ( >=media-libs/libwebp-1.1.0:0=[${MULTILIB_USEDEP}] )
	wifi? (
		kernel_linux? (
			net-misc/networkmanager[${MULTILIB_USEDEP}]
		)
	)
	jack? ( virtual/jack[${MULTILIB_USEDEP}] )
	selinux? ( sec-policy/selinux-mozilla )"

RDEPEND="${CDEPEND}
	jack? ( virtual/jack[${MULTILIB_USEDEP}] )
	pulseaudio? (
		|| (
			media-sound/pulseaudio[${MULTILIB_USEDEP}]
			>=media-sound/apulse-0.1.12-r4[${MULTILIB_USEDEP}]
		)
	)
	selinux? ( sec-policy/selinux-mozilla )"

DEPEND="${CDEPEND}
	app-arch/zip
	app-arch/unzip
	>=dev-util/cbindgen-0.13.0
	>=net-libs/nodejs-10.19.0
	>=sys-devel/binutils-2.30
	sys-apps/findutils
	|| (
		(
			sys-devel/clang:10[${MULTILIB_USEDEP}]
			!clang? ( sys-devel/llvm:10[${MULTILIB_USEDEP}] )
			clang? (
				=sys-devel/lld-10*
				sys-devel/llvm:10[gold,${MULTILIB_USEDEP}]
				pgo? ( =sys-libs/compiler-rt-sanitizers-10*[profile] )
			)
		)
		(
			sys-devel/clang:9[${MULTILIB_USEDEP}]
			!clang? ( sys-devel/llvm:9[${MULTILIB_USEDEP}] )
			clang? (
				=sys-devel/lld-9*
				sys-devel/llvm:9[gold,${MULTILIB_USEDEP}]
				pgo? ( =sys-libs/compiler-rt-sanitizers-9*[profile] )
			)
		)
		(
			sys-devel/clang:8[${MULTILIB_USEDEP}]
			!clang? ( sys-devel/llvm:8[${MULTILIB_USEDEP}] )
			clang? (
				=sys-devel/lld-8*
				sys-devel/llvm:8[gold,${MULTILIB_USEDEP}]
				pgo? ( =sys-libs/compiler-rt-sanitizers-8*[profile] )
			)
		)
		(
			sys-devel/clang:7[${MULTILIB_USEDEP}]
			!clang? ( sys-devel/llvm:7[${MULTILIB_USEDEP}] )
			clang? (
				=sys-devel/lld-7*
				sys-devel/llvm:7[gold,${MULTILIB_USEDEP}]
				pgo? ( =sys-libs/compiler-rt-sanitizers-7*[profile] )
			)
		)
	)
	pulseaudio? (
		|| (
			media-sound/pulseaudio[${MULTILIB_USEDEP}]
			>=media-sound/apulse-0.1.12-r4[sdk,${MULTILIB_USEDEP}]
		)
	)
	>=dev-lang/rust-1.41.0[${MULTILIB_USEDEP}]
	!dev-lang/rust-bin
	wayland? ( >=x11-libs/gtk+-3.11:3[wayland,${MULTILIB_USEDEP}] )
	abi_x86_64? ( >=dev-lang/yasm-1.1 virtual/opengl[${MULTILIB_USEDEP}] )
	abi_x86_32? ( >=dev-lang/yasm-1.1 virtual/opengl[${MULTILIB_USEDEP}] )
	!system-av1? (
		abi_x86_64? ( >=dev-lang/nasm-2.13 )
		abi_x86_32? ( >=dev-lang/nasm-2.13 )
	)"
# Gentoo's rust-bin package doesn't install the i686 libs.  Use only the
# compiled version.

S="${WORKDIR}/firefox-${PV%_*}"
S_BAK="${WORKDIR}/firefox-${PV%_*}"

QA_PRESTRIPPED="usr/lib*/${PN}/firefox"

MOZILLA_FIVE_HOME=""
BUILD_OBJ_DIR=""


# allow GMP_PLUGIN_LIST to be set in an eclass or
# overridden in the enviromnent (advanced hackers only)
if [[ -z $GMP_PLUGIN_LIST ]] ; then
	GMP_PLUGIN_LIST=( gmp-gmpopenh264 gmp-widevinecdm )
fi

fix_path() {
	local value_to_move=${1}
	local new_path path_value
	IFS=:; local -a path_values=( ${PATH} )
	for path_value in "${path_values[@]}" ; do
		if [[ ${path_value} == *"${value_to_move}"* ]] ; then
			new_path="${path_value}${new_path:+:}${new_path}"
		else
			new_path+="${new_path:+:}${path_value}"
		fi
	done

	echo "${new_path}"
}

llvm_check_deps() {
	if ! has_version --host-root "sys-devel/clang:${LLVM_SLOT}" ; then
		ewarn "sys-devel/clang:${LLVM_SLOT} is missing! Cannot use LLVM slot ${LLVM_SLOT} ..." >&2
		return 1
	fi

	if use clang ; then
		if ! has_version --host-root "=sys-devel/lld-${LLVM_SLOT}*" ; then
			ewarn "=sys-devel/lld-${LLVM_SLOT}* is missing! Cannot use LLVM slot ${LLVM_SLOT} ..." >&2
			return 1
		fi

		if use pgo ; then
			if ! has_version --host-root "=sys-libs/compiler-rt-sanitizers-${LLVM_SLOT}*" ; then
				ewarn "=sys-libs/compiler-rt-sanitizers-${LLVM_SLOT}* is missing! Cannot use LLVM slot ${LLVM_SLOT} ..." >&2
				return 1
			fi
		fi
	fi

	einfo "Will use LLVM slot ${LLVM_SLOT}!" >&2
}

pkg_pretend() {
	if use pgo ; then
		if ! has usersandbox $FEATURES ; then
			die "You must enable usersandbox as X server can not run as root!"
		fi

		if ! use clang ; then
			# Force user decision so they don't find out firefox was build
			# without pgo after spending some hours
			eerror "USE=pgo when using GCC is currently known to be broken."
			eerror "Either switch to USE=clang or temporarily set USE=-pgo."
			die "USE=pgo without USE=clang is currently known to be broken."
		fi
	fi

	# Ensure we have enough disk space to compile
	if use pgo || use lto || use debug || use test ; then
		CHECKREQS_DISK_BUILD="8G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi

	check-reqs_pkg_pretend
}

pkg_setup() {
	moz_pkgsetup

	# Ensure we have enough disk space to compile
	if use pgo || use lto || use debug || use test ; then
		CHECKREQS_DISK_BUILD="8G"
	else
		CHECKREQS_DISK_BUILD="4G"
	fi

	check-reqs_pkg_setup

	# Avoid PGO profiling problems due to enviroment leakage
	# These should *always* be cleaned up anyway
	unset DBUS_SESSION_BUS_ADDRESS \
		DISPLAY \
		ORBIT_SOCKETDIR \
		SESSION_MANAGER \
		XDG_CACHE_HOME \
		XDG_SESSION_COOKIE \
		XAUTHORITY

	if ! use bindist ; then
		einfo
		elog "You are enabling official branding. You may not redistribute this build"
		elog "to any users on your network or the internet. Doing so puts yourself into"
		elog "a legal problem with Mozilla Foundation."
		elog "You can disable it by emerging ${PN} _with_ the bindist USE-flag."
	fi

	addpredict /proc/self/oom_score_adj

	llvm_pkg_setup

	# Workaround for #627726
	if has ccache ${FEATURES} ; then
		if use clang && use pgo ; then
			die "Using FEATURES=ccache with USE=clang and USE=pgo is currently known to be broken (bug #718632)."
		fi

		einfo "Fixing PATH for FEATURES=ccache ..."
		PATH=$(fix_path 'ccache/bin')
	elif has distcc ${FEATURES} ; then
		einfo "Fixing PATH for FEATURES=distcc ..."
		PATH=$(fix_path 'distcc/bin')
	fi
}

src_unpack() {
	default

	# Unpack language packs
	mozlinguas_src_unpack
}

src_prepare() {
	eapply "${WORKDIR}/firefox"
	eapply "${FILESDIR}/${PN}-68.4.2-dont-check-rustc-host.patch"
	eapply "${FILESDIR}/${PN}-68.4.2-force-cross-compile.patch"

	# Make LTO respect MAKEOPTS
	sed -i \
		-e "s/multiprocessing.cpu_count()/$(makeopts_jobs)/" \
		"${S}"/build/moz.configure/lto-pgo.configure \
		|| die "sed failed to set num_cores"

	# Allow user to apply any additional patches without modifing ebuild
	eapply_user

	einfo "Removing pre-built binaries ..."
	find "${S}"/third_party -type f \( -name '*.so' -o -name '*.o' \) -print -delete || die

	# Enable gnomebreakpad
	if use debug ; then
		sed -i -e "s:GNOME_DISABLE_CRASH_DIALOG=1:GNOME_DISABLE_CRASH_DIALOG=0:g" \
			"${S}"/build/unix/run-mozilla.sh || die "sed failed!"
	fi

	# Drop -Wl,--as-needed related manipulation for ia64 as it causes ld sefgaults, bug #582432
	if use ia64 ; then
		sed -i \
		-e '/^OS_LIBS += no_as_needed/d' \
		-e '/^OS_LIBS += as_needed/d' \
		"${S}"/widget/gtk/mozgtk/gtk2/moz.build \
		"${S}"/widget/gtk/mozgtk/gtk3/moz.build \
		|| die "sed failed to drop --as-needed for ia64"
	fi

	# Fix sandbox violations during make clean, bug 372817
	sed -e "s:\(/no-such-file\):${T}\1:g" \
		-i "${S}"/config/rules.mk \
		-i "${S}"/nsprpub/configure{.in,} \
		|| die

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}"/browser/installer/Makefile.in || die

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}"/toolkit/mozapps/installer/packager.mk || die

	# Keep codebase the same even if not using official branding
	sed '/^MOZ_DEV_EDITION=1/d' \
		-i "${S}"/browser/branding/aurora/configure.sh || die

	# rustfmt, a tool to format Rust code, is optional and not required to build Firefox.
	# However, when available, an unsupported version can cause problems, bug #669548
	sed -i -e "s@check_prog('RUSTFMT', add_rustup_path('rustfmt')@check_prog('RUSTFMT', add_rustup_path('rustfmt_do_not_use')@" \
		"${S}"/build/moz.configure/rust.configure || die

	# Autotools configure is now called old-configure.in
	# This works because there is still a configure.in that happens to be for the
	# shell wrapper configure script
	eautoreconf old-configure.in

	# Must run autoconf in js/src
	cd "${S}"/js/src || die
	eautoconf old-configure.in

	# Clear checksums that present a problem
	sed -i 's/\("files":{\)[^}]*/\1/' "${S}"/third_party/rust/target-lexicon-0.9.0/.cargo-checksum.json || die

	if [[ "${CFLAGS}" =~ "fast-math" || "${CXXFLAGS}" =~ "fast-math" ]] ; then
		epatch "${FILESDIR}/firefox-52.2.0-opus-fast-math.patch"
	fi

	multilib_copy_sources
}

# corrections based on the ABI being compiled
_fix_paths() {
	MOZILLA_FIVE_HOME="/usr/$(get_libdir)/${PN}"
	BUILD_OBJ_DIR="${BUILD_DIR}/ff"
	if use clang && ! tc-is-clang ; then
		CC=${chost}-clang
		CXX=${chost}-clang++
	elif ! use clang && ! tc-is-gcc ; then
		CC=${chost}-gcc
		CXX=${chost}-g++
	fi
	tc-export CC CXX
}

multilib_src_configure() {
	local chost=$(get_abi_CHOST ${ABI})
	MEXTENSIONS="default"
	# Google API keys (see http://www.chromium.org/developers/how-tos/api-keys)
	# Note: These are for Gentoo Linux use ONLY. For your own distribution, please
	# get your own set of keys.
	_google_api_key=AIzaSyDEAOvatFo0eTgsV_ZlEzx0ObmepsMzfAc

	# Add information about TERM to output (build.log) to aid debugging
	# blessings problems
	if [[ -n "${TERM}" ]] ; then
		einfo "TERM is set to: \"${TERM}\""
	else
		einfo "TERM is unset."
	fi

	einfo "Cross-compile: chost=${chost}"
	if use clang && ! tc-is-clang ; then
		# Force clang
		einfo "Enforcing the use of clang due to USE=clang ..."
		CC=${chost}-clang
		CXX=${chost}-clang++
		strip-unsupported-flags
	elif ! use clang && ! tc-is-gcc ; then
		# Force gcc
		einfo "Enforcing the use of gcc due to USE=-clang ..."
		CC=${chost}-gcc
		CXX=${chost}-g++
		strip-unsupported-flags
	fi

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	mozconfig_init
	_fix_paths
	# common config components
	mozconfig_annotate 'system_libs' \
		--with-system-zlib \
		--with-system-bz2

	# Must pass release in order to properly select linker
	mozconfig_annotate 'Enable by Gentoo' --enable-release

	# libclang.so is not properly detected work around issue
	mozconfig_annotate '' --with-libclang-path="$(llvm-config --libdir)"

	if use pgo ; then
		if ! has userpriv $FEATURES ; then
			eerror "Building firefox with USE=pgo and FEATURES=-userpriv is not supported!"
		fi
	fi

	# Don't let user's LTO flags clash with upstream's flags
	filter-flags -flto*

	if use lto ; then
		local show_old_compiler_warning=

		if use clang ; then
			# At this stage CC is adjusted and the following check will
			# will work
			if [[ $(clang-major-version) -lt 7 ]] ; then
				show_old_compiler_warning=1
			fi

			# Upstream only supports lld when using clang
			mozconfig_annotate "forcing ld=lld due to USE=clang and USE=lto" --enable-linker=lld
		else
			if [[ $(gcc-major-version) -lt 8 ]] ; then
				show_old_compiler_warning=1
			fi

			if ! use cpu_flags_x86_avx2 ; then
				local _gcc_version_with_ipa_cdtor_fix="8.3"
				local _current_gcc_version="$(gcc-major-version).$(gcc-minor-version)"

				if ver_test "${_current_gcc_version}" -lt "${_gcc_version_with_ipa_cdtor_fix}" ; then
					# due to a GCC bug, GCC will produce AVX2 instructions
					# even if the CPU doesn't support AVX2, https://gcc.gnu.org/ml/gcc-patches/2018-12/msg01142.html
					einfo "Disable IPA cdtor due to bug in GCC and missing AVX2 support -- triggered by USE=lto"
					append-ldflags -fdisable-ipa-cdtor
				else
					einfo "No GCC workaround required, GCC version is already patched!"
				fi
			else
				einfo "No GCC workaround required, system supports AVX2"
			fi

			# Linking only works when using ld.gold when LTO is enabled
			mozconfig_annotate "forcing ld=gold due to USE=lto" --enable-linker=gold
		fi

		if [[ -n "${show_old_compiler_warning}" ]] ; then
			# Checking compiler's major version uses CC variable. Because we allow
			# user to control used compiler via USE=clang flag, we cannot use
			# initial value. So this is the earliest stage where we can do this check
			# because pkg_pretend is not called in the main phase function sequence
			# environment saving is not guaranteed so we don't know if we will have
			# correct compiler until now.
			ewarn ""
			ewarn "USE=lto requires up-to-date compiler (>=gcc-8 or >=clang-7)."
			ewarn "You are on your own -- expect build failures. Don't file bugs using that unsupported configuration!"
			ewarn ""
			sleep 5
		fi

		mozconfig_annotate '+lto' --enable-lto=thin

		if use pgo ; then
			mozconfig_annotate '+pgo' MOZ_PGO=1
		fi
	else
		# Avoid auto-magic on linker
		if use clang ; then
			# This is upstream's default
			mozconfig_annotate "forcing ld=lld due to USE=clang" --enable-linker=lld
		elif tc-ld-is-gold ; then
			mozconfig_annotate "linker is set to gold" --enable-linker=gold
		else
			mozconfig_annotate "linker is set to bfd" --enable-linker=bfd
		fi
	fi

	# It doesn't compile on alpha without this LDFLAGS
	use alpha && append-ldflags "-Wl,--no-relax"

	# Add full relro support for hardened
	use hardened && append-ldflags "-Wl,-z,now"

	# Modifications to better support ARM, bug 553364
	if use cpu_flags_arm_neon ; then
		mozconfig_annotate '' --with-fpu=neon

		if ! tc-is-clang ; then
			# thumb options aren't supported when using clang, bug 666966
			mozconfig_annotate '' --with-thumb=yes
			mozconfig_annotate '' --with-thumb-interwork=no
		fi
	fi

	if [[ ${chost} == armv*h* ]] ; then
		mozconfig_annotate '' --with-float-abi=hard
		if ! use system-libvpx ; then
			sed -i -e "s|softfp|hard|" \
				"${BUILD_DIR}"/media/libvpx/moz.build
		fi
	fi

	mozconfig_use_enable !bindist official-branding

	mozconfig_use_enable debug
	mozconfig_use_enable debug tests
	if ! use debug ; then
		mozconfig_annotate 'disabled by Gentoo' --disable-debug-symbols
	else
		mozconfig_annotate 'enabled by Gentoo' --enable-debug-symbols
	fi
	# These are enabled by default in all mozilla applications
	mozconfig_annotate '' --with-system-nspr --with-nspr-prefix="${SYSROOT}${EPREFIX}"/usr
	mozconfig_annotate '' --with-system-nss --with-nss-prefix="${SYSROOT}${EPREFIX}"/usr
	mozconfig_annotate '' --x-includes="${SYSROOT}${EPREFIX}"/usr/include \
		--x-libraries="${SYSROOT}${EPREFIX}"/usr/$(get_libdir)
	mozconfig_annotate '' --prefix="${EPREFIX}"/usr
	mozconfig_annotate '' --libdir="${EPREFIX}"/usr/$(get_libdir)
	mozconfig_annotate '' --disable-crashreporter
	mozconfig_annotate 'Gentoo default' --with-system-png
	mozconfig_annotate '' --enable-system-ffi
	mozconfig_annotate '' --disable-gconf
	mozconfig_annotate '' --with-intl-api
	mozconfig_annotate '' --enable-system-pixman
	# Instead of the standard --build= and --host=, mozilla uses --host instead
	# of --build, and --target intstead of --host.
	# Note, mozilla also has --build but it does not do what you think it does.
	# Set both --target and --host as mozilla uses python to guess values otherwise
	mozconfig_annotate '' --target="${chost}"
	mozconfig_annotate '' --host="${CBUILD:-${chost}}"
	if use system-libevent ; then
		mozconfig_annotate '' --with-system-libevent="${SYSROOT}${EPREFIX}"/usr
	fi

	if ! use x86 && [[ ${chost} != armv*h* ]] ; then
		mozconfig_annotate '' --enable-rust-simd
	fi

	# use the gtk3 toolkit (the only one supported at this point)
	# TODO: Will this result in automagic dependency on x11-libs/gtk+[wayland]?
	if use wayland ; then
		mozconfig_annotate '' --enable-default-toolkit=cairo-gtk3-wayland
	else
		mozconfig_annotate '' --enable-default-toolkit=cairo-gtk3
	fi

	mozconfig_use_enable startup-notification
	mozconfig_use_with system-av1
	mozconfig_use_with system-harfbuzz
	mozconfig_use_with system-harfbuzz system-graphite2
	mozconfig_use_with system-icu
	mozconfig_use_with system-jpeg
	mozconfig_use_with system-libvpx
	mozconfig_use_with system-webp
	mozconfig_use_enable pulseaudio
	# force the deprecated alsa sound code if pulseaudio is disabled
	if use kernel_linux && ! use pulseaudio ; then
		mozconfig_annotate '-pulseaudio' --enable-alsa
	fi

	# Disable built-in ccache support to avoid sandbox violation, #665420
	# Use FEATURES=ccache instead!
	mozconfig_annotate '' --without-ccache
	sed -i -e 's/ccache_stats = None/return None/' \
		python/mozbuild/mozbuild/controller/building.py || \
		die "Failed to disable ccache stats call"

	mozconfig_use_enable wifi necko-wifi

	mozconfig_use_enable geckodriver

	# enable JACK, bug 600002
	mozconfig_use_enable jack

	# Enable/Disable eme support
	use eme-free && mozconfig_annotate '+eme-free' --disable-eme

	# Setup api key for location services and safebrowsing, https://bugzilla.mozilla.org/show_bug.cgi?id=1531176#c34
	echo -n "${_google_api_key}" > "${BUILD_DIR}"/google-api-key
	mozconfig_annotate '' --with-google-location-service-api-keyfile="${BUILD_DIR}/google-api-key"
	mozconfig_annotate '' --with-google-safebrowsing-api-keyfile="${BUILD_DIR}/google-api-key"

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"

	# allow elfhack to work in combination with unstripped binaries
	# when they would normally be larger than 2GiB.
	append-ldflags "-Wl,--compress-debug-sections=zlib"

	if use clang && ! use arm64; then
		# https://bugzilla.mozilla.org/show_bug.cgi?id=1482204
		# https://bugzilla.mozilla.org/show_bug.cgi?id=1483822
		mozconfig_annotate 'elf-hack is broken when using Clang' --disable-elf-hack
	fi

	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${BUILD_DIR}"/.mozconfig
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${BUILD_DIR}"/.mozconfig

	if ! use jemalloc ; then
		 mozconfig_annotate '-jemalloc' --disable-jemalloc
	else
		 mozconfig_annotate '+jemalloc' --enable-jemalloc
	fi

	einfo "Cross-compile: ${ABI} CFLAGS=${CFLAGS}"
	einfo "Cross-compile: CC=${CC} CXX=${CXX}"
	echo "export PKG_CONFIG_PATH=/usr/$(get_libdir)/pkgconfig:/usr/share/pkgconfig" >> .mozconfig
	mozconfig_annotate '' --target=${chost%-*}

	# Finalize and report settings
	mozconfig_final

	mkdir -p "${BUILD_DIR}"/third_party/rust/libloading/.deps

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX}/bin/bash}" MOZ_NOSPAM=1 \
	./mach configure || die
}

multilib_src_compile() {
	local chost=$(get_abi_CHOST ${ABI})
	_fix_paths
	local _virtx=
	if use pgo ; then
		_virtx=virtx

		# Reset and cleanup environment variables used by GNOME/XDG
		gnome2_environment_reset

		addpredict /root
		addpredict /etc/gconf
	fi

	GDK_BACKEND=x11 \
		MOZ_MAKE_FLAGS="${MAKEOPTS} -O" \
		SHELL="${SHELL:-${EPREFIX}/bin/bash}" \
		MOZ_NOSPAM=1 \
		${_virtx} \
		./mach build --verbose \
		|| die
}

multilib_src_install() {
	local chost=$(get_abi_CHOST ${ABI})
	_fix_paths
	cd "${BUILD_OBJ_DIR}" || die

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}"/dist/bin/xpcshell

	# Add our default prefs for firefox
	cp "${FILESDIR}"/gentoo-default-prefs.js-3 \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	# set dictionary path, to use system hunspell
	echo "pref(\"spellchecker.dictionary_path\", \"${EPREFIX}/usr/share/myspell\");" \
		>>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" || die

	# force the graphite pref if system-harfbuzz is enabled, since the pref cant disable it
	if use system-harfbuzz ; then
		echo "sticky_pref(\"gfx.font_rendering.graphite.enabled\",true);" \
			>>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" || die
	fi

	# force cairo as the canvas renderer on platforms without skia support
	if [[ $(tc-endian) == "big" ]] ; then
		echo "sticky_pref(\"gfx.canvas.azure.backends\",\"cairo\");" \
			>>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" || die
		echo "sticky_pref(\"gfx.content.azure.backends\",\"cairo\");" \
			>>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" || die
	fi

	# Augment this with hwaccel prefs
	if use hwaccel ; then
		cat "${FILESDIR}"/gentoo-hwaccel-prefs.js-1 >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die
	fi

	if ! use screenshot ; then
		echo "pref(\"extensions.screenshots.disabled\", true);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	fi

	echo "pref(\"extensions.autoDisableScopes\", 3);" >> \
		"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
		|| die

	local plugin
	use gmp-autoupdate || use eme-free || for plugin in "${GMP_PLUGIN_LIST[@]}" ; do
		echo "pref(\"media.${plugin}.autoupdate\", false);" >> \
			"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" \
			|| die
	done

	cd "${BUILD_DIR}"
	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX}/bin/bash}" MOZ_NOSPAM=1 \
	DESTDIR="${D}" ./mach install || die

	if use geckodriver ; then
		cp "${BUILD_OBJ_DIR}"/dist/bin/geckodriver "${ED%/}"${MOZILLA_FIVE_HOME} || die
		pax-mark m "${ED%/}"${MOZILLA_FIVE_HOME}/geckodriver

		dosym ${MOZILLA_FIVE_HOME}/geckodriver /usr/bin/geckodriver
	fi

	# Install language packs
	MOZEXTENSION_TARGET="distribution/extensions" MOZ_INSTALL_L10N_XPIFILE="1" mozlinguas_src_install

	local size sizes icon_path icon name
	if use bindist ; then
		sizes="16 32 48"
		icon_path="${BUILD_DIR}/browser/branding/aurora"
		# Firefox's new rapid release cycle means no more codenames
		# Let's just stick with this one...
		icon="aurora"
		name="Aurora"

		# Override preferences to set the MOZ_DEV_EDITION defaults, since we
		# don't define MOZ_DEV_EDITION to avoid profile debaucles.
		# (source: browser/app/profile/firefox.js)
		cat >>"${BUILD_OBJ_DIR}/dist/bin/browser/defaults/preferences/all-gentoo.js" <<PROFILE_EOF
pref("app.feedback.baseURL", "https://input.mozilla.org/%LOCALE%/feedback/firefoxdev/%VERSION%/");
sticky_pref("lightweightThemes.selectedThemeID", "firefox-devedition@mozilla.org");
sticky_pref("browser.devedition.theme.enabled", true);
sticky_pref("devtools.theme", "dark");
PROFILE_EOF

	else
		sizes="16 22 24 32 48 64 128 256"
		icon_path="${BUILD_DIR}/browser/branding/official"
		icon="${PN}"
		name="Mozilla Firefox"
	fi

	# Disable built-in auto-update because we update firefox through package manager
	insinto ${MOZILLA_FIVE_HOME}/distribution/
	newins "${FILESDIR}"/disable-auto-update.policy.json policies.json

	# Install icons and .desktop for menu entry
	for size in ${sizes} ; do
		insinto "/usr/share/icons/hicolor/${size}x${size}/apps"
		newins "${icon_path}/default${size}.png" "${icon}.png"
	done
	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}/default48.png" "${icon}.png"

	# Add StartupNotify=true bug 237317
	local startup_notify="false"
	if use startup-notification ; then
		startup_notify="true"
	fi

	local display_protocols="auto X11" use_wayland="false"
	if use wayland ; then
		display_protocols+=" Wayland"
		use_wayland="true"
	fi

	local app_name desktop_filename display_protocol exec_command
	for display_protocol in ${display_protocols} ; do
		app_name="${name} on ${display_protocol}"
		desktop_filename="${PN}-${display_protocol,,}.desktop"

		case ${display_protocol} in
			Wayland)
				exec_command='firefox-wayland --name firefox-wayland'
				newbin "${FILESDIR}"/firefox-wayland.sh firefox-wayland
				;;
			X11)
				if ! use wayland ; then
					# Exit loop here because there's no choice so
					# we don't need wrapper/.desktop file for X11.
					continue
				fi

				exec_command='firefox-x11 --name firefox-x11'
				newbin "${FILESDIR}"/firefox-x11.sh firefox-x11
				;;
			*)
				app_name="${name}"
				desktop_filename="${PN}.desktop"
				exec_command='firefox'
				;;
		esac

		newmenu "${FILESDIR}/icon/${PN}-r1.desktop" "${desktop_filename}"
		sed -i \
			-e "s:@NAME@:${app_name}:" \
			-e "s:@EXEC@:${exec_command}:" \
			-e "s:@ICON@:${icon}:" \
			-e "s:@STARTUP_NOTIFY@:${startup_notify}:" \
			"${ED%/}/usr/share/applications/${desktop_filename}" || die
	done

	rm "${ED%/}"/usr/bin/firefox || die
	newbin "${FILESDIR}"/firefox.sh firefox

	local wrapper
	for wrapper in \
		"${ED%/}"/usr/bin/firefox \
		"${ED%/}"/usr/bin/firefox-x11 \
		"${ED%/}"/usr/bin/firefox-wayland \
	; do
		[[ ! -f "${wrapper}" ]] && continue

		sed -i \
			-e "s:@PREFIX@:${EPREFIX%/}/usr:" \
			-e "s:@DEFAULT_WAYLAND@:${use_wayland}:" \
			"${wrapper}" || die
	done

	# Don't install llvm-symbolizer from sys-devel/llvm package
	[[ -f "${ED%/}${MOZILLA_FIVE_HOME}/llvm-symbolizer" ]] && \
		rm "${ED%/}${MOZILLA_FIVE_HOME}/llvm-symbolizer"

	# firefox and firefox-bin are identical
	rm "${ED%/}"${MOZILLA_FIVE_HOME}/firefox-bin || die
	dosym firefox ${MOZILLA_FIVE_HOME}/firefox-bin

	# Required in order to use plugins and even run firefox on hardened.
	pax-mark m "${ED%/}"${MOZILLA_FIVE_HOME}/{firefox,plugin-container}
}

pkg_preinst() {
	# if the apulse libs are available in MOZILLA_FIVE_HOME then apulse
	# doesn't need to be forced into the LD_LIBRARY_PATH
	if use pulseaudio && has_version ">=media-sound/apulse-0.1.12-r4" ; then
		einfo "APULSE found - Generating library symlinks for sound support"
		local lib
		pushd "${ED}"${MOZILLA_FIVE_HOME} &>/dev/null || die
		for lib in ../apulse/libpulse{.so{,.0},-simple.so{,.0}} ; do
			# a quickpkg rolled by hand will grab symlinks as part of the package,
			# so we need to avoid creating them if they already exist.
			if [[ ! -L ${lib##*/} ]] ; then
				ln -s "${lib}" ${lib##*/} || die
			fi
		done
		popd &>/dev/null || die
	fi
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update

	if ! use gmp-autoupdate && ! use eme-free ; then
		elog "USE='-gmp-autoupdate' has disabled the following plugins from updating or"
		elog "installing into new profiles:"
		local plugin
		for plugin in "${GMP_PLUGIN_LIST[@]}"; do elog "\t ${plugin}" ; done
		elog
	fi

	if use pulseaudio && has_version ">=media-sound/apulse-0.1.12-r4" ; then
		elog "Apulse was detected at merge time on this system and so it will always be"
		elog "used for sound.  If you wish to use pulseaudio instead please unmerge"
		elog "media-sound/apulse."
		elog
	fi

	local show_doh_information show_normandy_information

	if [[ -z "${REPLACING_VERSIONS}" ]] ; then
		# New install; Tell user that DoH is disabled by default
		show_doh_information=yes
		show_normandy_information=yes
	else
		local replacing_version
		for replacing_version in ${REPLACING_VERSIONS} ; do
			if ver_test "${replacing_version}" -lt 70 ; then
				# Tell user only once about our DoH default
				show_doh_information=yes
			fi

			if ver_test "${replacing_version}" -lt 74.0-r2 ; then
				# Tell user only once about our Normandy default
				show_normandy_information=yes
			fi
		done
	fi

	if [[ -n "${show_doh_information}" ]] ; then
		elog
		elog "Note regarding Trusted Recursive Resolver aka DNS-over-HTTPS (DoH):"
		elog "Due to privacy concerns (encrypting DNS might be a good thing, sending all"
		elog "DNS traffic to Cloudflare by default is not a good idea and applications"
		elog "should respect OS configured settings), \"network.trr.mode\" was set to 5"
		elog "(\"Off by choice\") by default."
		elog "You can enable DNS-over-HTTPS in ${PN^}'s preferences."
	fi

	# bug 713782
	if [[ -n "${show_normandy_information}" ]] ; then
		elog
		elog "Upstream operates a service named Normandy which allows Mozilla to"
		elog "push changes for default settings or even install new add-ons remotely."
		elog "While this can be useful to address problems like 'Armagadd-on 2.0' or"
		elog "revert previous decisions to disable TLS 1.0/1.1, privacy and security"
		elog "concerns prevail, which is why we have switched off the use of this"
		elog "service by default."
		elog
		elog "To re-enable this service set"
		elog
		elog "    app.normandy.enabled=true"
		elog
		elog "in about:config."
	fi
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
