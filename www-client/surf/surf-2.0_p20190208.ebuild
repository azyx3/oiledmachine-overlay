# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="a simple web browser based on WebKit/GTK+"
HOMEPAGE="https://surf.suckless.org/"
# The GPL-3+ on the adblock comes from EasyList blocklist
LICENSE="MIT SURF
	 mod_adblock? ( CC-BY-NA-SA-3.0 CC-BY-SA-3.0 CC-BY-SA-4.0 GPL-3+ MIT
			SURF-MOD_ADBLOCKER SURF-MOD_ADBLOCKER-EASYLIST
			SURF-MOD_ADBLOCKER-SPAM404 )
	 mod_autoopen? ( all-rights-reserved )
	 mod_link_hints? ( all-rights-reserved )
	 mod_searchengines? ( all-rights-reserved )
	 mod_simple_bookmarking_redux? ( all-rights-reserved )"
KEYWORDS="~alpha amd64 ~amd64-fbsd ~amd64-linux ~arm arm64 ~ia64 ~ppc ~ppc64 \
~sparc x86 ~x86-linux ~x86-macos"
SLOT="0"
IUSE="mod_adblock mod_autoopen mod_link_hints mod_searchengines \
mod_simple_bookmarking_redux update_adblock"
REQUIRED_USE="mod_searchengines? ( savedconfig )
	      mod_simple_bookmarking_redux? ( savedconfig )
	      update_adblock? ( mod_adblock )"
inherit multilib-minimal
COMMON_DEPEND=" app-crypt/gcr[gtk,${MULTILIB_USEDEP}]
		dev-libs/glib:2[${MULTILIB_USEDEP}]
		net-libs/webkit-gtk:4[${MULTILIB_USEDEP}]
		x11-libs/gtk+:3[${MULTILIB_USEDEP}]
		x11-libs/libX11[${MULTILIB_USEDEP}]"
DEPEND="${COMMON_DEPEND}
	virtual/pkgconfig[${MULTILIB_USEDEP}]"
RDEPEND="${COMMON_DEPEND}
	 !savedconfig? (   net-misc/curl[${MULTILIB_USEDEP}]
			   x11-apps/xprop
			 >=x11-misc/dmenu-4.7
			   x11-terms/st )
	 !sci-chemistry/surf"
EGIT_BRANCH="surf-webkit2"
EGIT_COMMIT="d068a3878b6b9f2841a49cd7948cdf9d62b55585"
EGIT_REPO_URI="https://git.suckless.org/surf"
AUTOOPEN_FN="surf-0.3-autoopen.diff"
LINK_HINTS_FN="surf-9999-link-hints.diff"
SEARCHENGINES_FN="surf-git-20170323-webkit2-searchengines.diff"
SRC_URI="mod_autoopen? ( ${AUTOOPEN_FN} )
	 mod_link_hints? ( ${LINK_HINTS_FN} )
	 mod_searchengines? ( ${SEARCHENGINES_FN} )"
inherit git-r3 savedconfig toolchain-funcs
PATCHES=( "${FILESDIR}"/${PN}-9999-gentoo.patch )

_boilerplate_dl() {
	local fn_s="${1}"
	local fn_d="${2}"
	local dl_location="${3}"
	local distdir=${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
	einfo
	einfo "Please download"
	einfo "  - ${fn_s}"
	einfo "from ${dl_location} and rename it to ${fn_d} place them in"
	einfo "${distdir}"
	einfo
}

_boilerplate_dl_link_hints() {
	local fn_d="${1}"
	local dl_location="${2}"
	local msg="${3}"
	local hash="${4}"
	local distdir=${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}
	einfo "\n\
${msg}\n\
from ${dl_location} and rename it to ${fn_d} place them in ${distdir} .\n\
If copied correctly, the sha1sum should be ${hash} .\n\
\n"
}

pkg_setup() {
	if ! use savedconfig; then
		einfo \
"The default config.h assumes you have\n\
  net-misc/curl\n\
  x11-terms/st\n\
installed to support the download function.  Without those, downloads will\n\
fail (gracefully).  You can fix this by:\n\
1) Installing these packages, or\n\
2) Setting USE=savedconfig and changing config.h accordingly."
	fi
	if use mod_link_hints ; then
		_boilerplate_dl_link_hints "${LINK_HINTS_FN}" \
			"https://surf.suckless.org/files/link_hints/" \
			"Copy and paste the Code section into a file" \
			"9527d1240cd4a2c3cde077ae2b287d2f1a5ae758"
	fi
	if use mod_autoopen ; then
		_boilerplate_dl "${AUTOOPEN_FN}" "${AUTOOPEN_FN}" \
			"https://surf.suckless.org/patches/autoopen/"
	fi
	if use mod_searchengines ; then
		_boilerplate_dl "${SEARCHENGINES_FN}" "${SEARCHENGINES_FN}" \
			"https://surf.suckless.org/patches/searchengines/"
	fi
}

src_prepare() {
	default

	cd "${S}"

	if use mod_simple_bookmarking_redux ; then
		if [ ! -e /etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR} ] ; then
			eerror \
"Please run\n\
\n\
mkdir -p \"/etc/portage/savedconfig/www-client\" ; cp \"${S}/config.def.h\" \"/etc/portage/savedconfig/www-client/surf-${PV}\"
\n\
or provide your edited config.h saved as\n\
\n\
/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}"
			die
		fi
		if ! grep -F -q -e "define BM_PICK" \
			"/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}" ; \
		then
			die \
"Missing define BM_PICK and/or keybindings.  Copy the define/keybindings into \
your savedconfig file (/etc/portage/savedconfig/www-client/surf-${PV}) .  See \
https://surf.suckless.org/files/simple_bookmarking_redux/ for details."
		fi
		if ! grep -q -F -e "define BM_ADD" \
			"/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}" ; \
		then
			die \
"Missing define BM_ADD and/or keybindings.  Copy the define/keybindings into \
your savedconfig file (/etc/portage/savedconfig/www-client/surf-${PV}).  See \
https://surf.suckless.org/files/simple_bookmarking_redux/ for details."
		fi
	fi

	if use mod_adblock ; then
		eapply "${FILESDIR}"/${PN}-9999-adblock.patch
		if ! grep -q -F -e "PAGE_LOAD_COMMITTED" \
			"/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}" ; then
			eerror \
"Please copy the following mod_adblock code fragment to your savedconfig\n\
(/etc/portage/savedconfig/www-client/surf-${PV}):"
			eerror "---------- cut below ----------"
			cat "${FILESDIR}/surf-9999-adblock-header-notes.txt" || die
			eerror "---------- cut above ----------"
			die
		fi
	fi

	if use mod_searchengines ; then
		einfo \
		"${SEARCHENGINES_FN} patch may break.  Will triage immediately."
		patch -p1 -i "${DISTDIR}/${SEARCHENGINES_FN}"
		eapply "${FILESDIR}/surf-9999-webkit2-searchengines-compat.patch"

		if ! grep -q -F -e "static SearchEngine searchengines[]" \
			"/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}" ; then
			eerror \
"You are missing a searchengines array in your savedconfig\n\
(/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}).  For details see\n\
https://surf.suckless.org/patches/searchengines/"
			die
		fi
		if ! grep -q -F -e "BM_PICK }," \
			"/etc/portage/savedconfig/${CATEGORY}/${PN}-${PVR}" ; then
			eerror \
"Please copy the following mod_searchengine code fragment to your savedconfig hotkeys array\n\
(static Key keys[] in /etc/portage/savedconfig/www-client/surf-${PV}):"
			eerror "---------- cut below ----------"
			cat "${FILESDIR}/surf-9999-search-engine-notes.txt" || die
			eerror "---------- cut above ----------"
			die
		fi
	fi

	restore_config config.h

	tc-export CC

	touch NEWS AUTHORS ChangeLog

	multilib_copy_sources

	prepare_abi() {
		cd "${BUILD_DIR}" || die
		sed -i -e "s|\
LIBPREFIX = \$(PREFIX)/lib|\
LIBPREFIX = \$(PREFIX)/$(get_libdir)|g" \
			config.mk || die
	}

	multilib_foreach_abi prepare_abi

	local num_abis=$(multilib_get_enabled_abi_pairs | wc -l)
	if [[ "${num_abis}" != "1" ]] ; then
		die "You can only install for one abi"
	fi
}

multilib_src_compile() {
	PKG_CONFIG="/usr/bin/$(get_abi_CHOST ${ABI})-pkg-config" \
	emake
}

multilib_src_install() {
	default

	save_config config.h

	dodoc "${FILESDIR}/LICENSES"

	if use mod_adblock ; then
		insinto /etc/surf/scripts
		doins -r \
			"${FILESDIR}/adblock" \
			"${FILESDIR}/events"
		fperms 0750 /etc/surf/scripts/adblock/adblock.py
		fperms 0750 /etc/surf/scripts/adblock/blocklists.py
		fperms 0750 /etc/surf/scripts/adblock/blocksrv.py
		fperms 0750 /etc/surf/scripts/adblock/convert.py
		fperms 0750 /etc/surf/scripts/adblock/update.sh
	fi

	if use mod_link_hints ; then
		cp -a "${DISTDIR}/surf-9999-link-hints.diff" "${T}/script.js"
		insinto /usr/share/${PN}
		doins "${T}/script.js"
	fi
}

_update_adblock() {
	einfo "Updating adblock rules"
	cd /etc/surf/scripts/adblock
	./update.sh
	einfo "Done updating adblock rules"
}

pkg_postinst() {
	if use mod_link_hints ; then
		einfo \
"If you want link hinting support copy /usr/share/${PN}/{script.js,style.css}\n\
to your /home/<USER>/.surf directory."
	fi

	if use mod_adblock ; then
		einfo \
"You must update the adblock filters manually at /etc/surf/adblock/update.sh.\n\
Make sure the current working directory is /etc/surf/adblock/ before running\n\
it."
	fi

	if use mod_adblock ; then
		einfo \
"You may run \`emerge --config ${CATEGORY}/${PN}\` to update the adblock."
		if use update_adblock ; then
			_update_adblock
		fi
	fi
}

pkg_config() {
	if use mod_adblock ; then
		_update_adblock
	fi
}
