# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="w3crapcli/last.fm provides a command line interface for the
last.fm web service"
HOMEPAGE="https://github.com/l29ah/w3crapcli"
LICENSE="WTFPL-2"
KEYWORDS="~amd64 ~arm ~arm64 ~mips ~ppc ~ppc64 ~x86"
SLOT="0"
IUSE="doc download-tracks gettracks glistfm grab-lastfm-userpic lastfmpost \
mpv mplayerfm savedconfig"
DEPEND="download-tracks? ( app-shells/zsh
			   app-text/tidy-html5
			   dev-haskell/haxml
			   net-misc/curl
			   net-misc/wget )
	gettracks? ( dev-lang/ghc
			net-misc/curl )
	glistfm? ( net-misc/curl )
	grab-lastfm-userpic? ( net-misc/wget )
	lastfmpost? ( net-misc/wget )
	mplayerfm? ( media-sound/scrobbler
		     media-libs/mutagen )
	mpv? ( dev-lang/lua
		media-sound/scrobbler
		media-video/mpv[lua] )"
# use media-sound/scrobbler from booboo overlay
EGIT_COMMIT="b8fc6007bb33e69a4dd00b2417b55ead55ec6ec1"
FN_PREFIX="w3crapcli-last.fm-${EGIT_COMMIT}-"
BASE_URL=\
"https://raw.githubusercontent.com/l29ah/w3crapcli/${EGIT_COMMIT}/last.fm/"
N_FILES=6 # N-1
REMOTE_FNS=(
	download-tracks
	gettracks.hs
	glistfm.sh
	grab-lastfm-userpic
	lastfmpost
	mplayerfm
	mpv-lastfm.lua
)
CACHED_FNS=( ${REMOTE_FNS[@]/#/${FN_PREFIX}} )
url_generator() {
	local s=""
	local i
	for ((i=0 ; i <= ${N_FILES} ; i+=1)) ; do
		s+=" ${BASE_URL}${REMOTE_FNS[${i}]} -> ${FN_PREFIX}${REMOTE_FNS[${i}]}"
	done
	echo ${s}
}
SRC_URI=\
"$(url_generator)
https://github.com/l29ah/w3crapcli/blob/${EGIT_COMMIT}/LICENSE -> w3crapcli-${EGIT_COMMIT}-LICENSE
https://github.com/l29ah/w3crapcli/blob/${EGIT_COMMIT}/README.md -> w3crapcli-${EGIT_COMMIT}-README.md"
inherit eutils
RESTRICT="mirror"
S="${WORKDIR}/${PN}-${PV}"
DOCS=( README.md )

pkg_setup() {
	if use savedconfig ; then
		if [[ ! -f /etc/portage/savedconfig/media-sound/${PN}-${PV} ]] ; then
cat \
<<EOF
------------------ CUT BELOW -------------------------------
USERFOLDER="/home/myname"
USEROWNER="myowner"
USERGROUP="mygroup"
LFM_NAME="mylastfmname"
LFM_PASS="mylastfmpass"
APP_NAME="myappname"
APP_API_KEY="myappapikey"
APP_SHARED_SECRET="myappsharedsecret"
------------------ CUT ABOVE -------------------------------
EOF
		die \
"You must fill out your own savedconfig before preceeding.  Copy and edit the\n\
into /etc/portage/savedconfig/media-sound/${PN}-${PV} and try again."
		fi
	fi
}

src_unpack() {
	mkdir -p "${S}"
	cd "${S}"
	unpack ${A}
	for i in $(seq 0 ${N_FILES}) ; do
		einfo "copying ${DISTDIR}/${FN_PREFIX}${REMOTE_FNS[${i}]}"
		cat "${DISTDIR}/${FN_PREFIX}${REMOTE_FNS[${i}]}" \
			> "${REMOTE_FNS[${i}]}" || die
	done
	cat "${DISTDIR}/w3crapcli-${EGIT_COMMIT}-LICENSE" \
			> LICENSE
	cat "${DISTDIR}/w3crapcli-${EGIT_COMMIT}-README.md" \
			> README.md
}

src_prepare() {
	default
	if use mplayerfm ; then
		ewarn "mplayerfm uses deleted script.  Provide user patch to fix"
		:;
		#eapply "${FILESDIR}/mplayerfm-use-hauzer-scrobbler.patch"
	fi
}

src_install() {
	exeinto "/usr/share/${PN}"
	doexe ${REMOTE_FNS[@]}
	dodoc LICENSE
}

_set_settings() {
	local d="${USERFOLDER}/.local/bin"
	mkdir -p "${d}" || die
	local s="/usr/share/${PN}"
	if use download-tracks ; then
		cp -a "${s}/download-tracks" \
			"${d}" || die
		einfo "Copied download-tracks to ${d}"
	fi
	if use gettracks ; then
		cp -a "${s}/gettracks.hs" \
			"${d}" || die
		sed -i -e "s|ae26d4892e373c6fc188acf7e3cb36c3|${APP_API_KEY}|g" \
			"${d}/gettracks.hs" || die
		einfo "Copied gettracks.hs to ${d}"
	fi
	if use glistfm ; then
		cp -a "${s}/glistfm.sh" \
			"${d}" || die
		sed -i -e "s|b25b959554ed76058ac220b7b2e0a026|${APP_API_KEY}|g" \
			"${d}/glistfm.sh" || die
		einfo "Copied glistfm.sh to ${d}"
	fi
	if use grab-lastfm-userpic ; then
		cp -a "${s}/grab-lastfm-userpic" \
			"${d}" || die
		einfo "Copied grab-lastfm-userpic to ${d}"
	fi
	if use lastfmpost ; then
		cp -a "${s}/lastfmpost" \
			"${d}" || die
		sed -i -e "s|<USERNAME>|${LFM_NAME}|g" \
			"${d}/lastfmpost" || die
		sed -i -e "s|<PASSWORD>|${LFM_PASS}|g" \
			"${d}/lastfmpost" || die
		einfo "Copied lastfmpost to ${d}"
	fi
	if use mplayerfm ; then
		cp -a "${s}/mplayerfm" \
			"${d}" || die
		einfo "Copied mplayerfm to ${d}"
	fi
	if use mpv ; then
		mkdir -p "${USERFOLDER}/.config/mpv/scripts/" || die
		cp -a "${s}/mpv-lastfm.lua" \
			"${USERFOLDER}/.config/mpv/scripts/"
		chown ${USEROWNER}:${USERGROUP} \
			"${USERFOLDER}/.config/mpv/scripts/mpv-lastfm.lua"
		einfo "Copied mpv-lastfm.lua to ${USERFOLDER}/.config/mpv/scripts/"
	fi
	einfo "Fixing permissions in ${d}"
	chown ${USEROWNER}:${USERGROUP} "${d}"/*
	einfo "Add ${d} to your profile's PATH"
	unset LFM_PASS
	unset APP_API_KEY
	unset APP_SHARED_SECRET
}

pkg_postinst() {
	einfo \
"Obtain an API key from http://www.last.fm/api/accounts .  You need to add\n\
the user home directory to the PATH environmental variable in ~/.bashrc ."
	if ! use savedconfig ; then
		einfo \
"Do a \`emerge ${PN} --config\` to manually complete the installation."
	else
		source "/etc/portage/savedconfig/media-sound/${PN}-${PV}"
		_set_settings
	fi
}

pkg_config() {
	if ! use savedconfig ; then
		einfo "Enter the full path of the user home dir (/home/<username>)"
		read USERFOLDER
		einfo "Enter the file owner"
		read USEROWNER
		einfo "Enter the file group"
		read USERGROUP
		einfo "Enter your last.fm username:"
		read LFM_NAME
		einfo "Enter your last.fm password:"
		read LFM_PASS
		einfo "Enter the app name:"
		read APP_NAME
		einfo "Enter the app api key:"
		read APP_API_KEY
		einfo "Enter the shared secret:"
		read APP_SHARED_SECRET
		_set_settings
	fi
}
