# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

USE_DOTNET="net461 netstandard20"

RDEPEND=">=media-libs/libsdl2-2.0.7
         media-libs/sdl2-ttf
         media-libs/sdl2-mixer"
DEPEND="${RDEPEND}"
IUSE="${USE_DOTNET} debug +gac"
REQUIRED_USE="|| ( ${USE_DOTNET} ) gac"

inherit dotnet eutils mono

DESCRIPTION="SDL2-CS is a C# wrapper for SDL2"
HOMEPAGE="https://github.com/flibitijibibo/SDL2-CS"
PROJECT_NAME="SDL2-CS"
COMMIT="499ad108b93f28c7a8aa2f357206ddc98980614e"
SRC_URI="https://github.com/flibitijibibo/${PROJECT_NAME}/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

inherit gac

LICENSE="zlib"
SLOT="0"
KEYWORDS="~amd64 ~x86"

S="${WORKDIR}/${PROJECT_NAME}-${COMMIT}"

src_prepare() {
	default
	cp -a "${FILESDIR}/SDL2-CS.dll.config" "${S}"
	dotnet_copy_sources
}

src_compile() {
	mydebug="release"
	if use debug; then
		mydebug="debug"
	fi

	compile_impl() {
		if [[ "${EDOTNET}" =~ netcore || "${EDOTNET}" =~ netstandard ]] ; then
		        exbuild SDL2-CS.Core.csproj ${STRONG_ARGS_NETCORE}"${DISTDIR}/mono.snk" -p:Configuration=${mydebug} || die
		else
		        exbuild ${STRONG_ARGS_NETFX}"${DISTDIR}/mono.snk" /p:Configuration=${mydebug} SDL2-CS.csproj || die
		fi

		local wordsize
		if [[ "$(get_libdir)" == "lib64" ]]; then
			wordsize="64"
		elif [[ "$(get_libdir)" == "lib32" ]]; then
			wordsize="32"
		else
			die "${ABI} not supported"
		fi

		sed -i -e "s|wordsize=\"[0-9]+\"|wordsize=\"${wordsize}\"|g" "${f}" || die
		sed -i -e "s|lib64|$(get_libdir)|g" "${f}" || die
	}

	dotnet_foreach_impl compile_impl
}

src_install() {
	install_impl() {
		mydebug="Release"
		if use debug; then
			mydebug="Debug"
		fi

		local d
		if [[ "${EDOTNET}" =~ netstandard ]] ; then
			mydebug="${mydebug,,}"
			d=$(dotnet_netcore_install_loc ${EDOTNET})
		elif dotnet_is_netfx "${EDOTNET}" ; then
			d=$(dotnet_netfx_install_loc ${EDOTNET})
		fi

		insinto "${d}"
		if [[ "${EDOTNET}" =~ netstandard ]] ; then
			doins bin/${mydebug}/$(dotnet_use_flag_moniker_to_ms_moniker ${ENETCORE})/SDL2-CS.dll
			doins SDL2-CS.dll.config
			doins bin/${mydebug}/$(dotnet_use_flag_moniker_to_ms_moniker ${ENETCORE})/SDL2-CS.deps.json
			doins bin/${mydebug}/$(dotnet_use_flag_moniker_to_ms_moniker ${ENETCORE})/SDL2-CS.pdb
		elif dotnet_is_netfx "${EDOTNET}" ; then
			if use gac ; then
				estrong_resign "bin/${mydebug}/${PROJECT_NAME}.dll" "${DISTDIR}/mono.snk"
			fi
			doins SDL2-CS.dll.config
			doins bin/${mydebug}/SDL2-CS.dll
			if use gac ; then
				egacinstall "bin/${mydebug}/${PROJECT_NAME}.dll"
				d=$(find "${D}"/usr/$(get_libdir)/mono/gac/${PROJECT_NAME}/ -maxdepth 1 -name "[0-9.]*__[0-9a-z]*")
				d=$(echo "${d}" | sed -e "s|${D}||")
				dosym "$(dotnet_netfx_install_loc ${EDOTNET})/${PROJECT_NAME}.dll.config" "${d}/${PROJECT_NAME}.dll.config"
			fi
		fi
	}

	dotnet_foreach_impl install_impl

	dotnet_multilib_comply
}
