# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="Drivers and libraries for the Xbox Kinect device on Windows,"
DESCRIPTION+=" Linux, and OS X"
HOMEPAGE="https://github.com/OpenKinect/libfreenect"
LICENSE="|| ( Apache-2.0 GPL-2 )"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"
USE_DOTNET="net35 net45"
IUSE="${USE_DOTNET} debug +gac"
REQUIRED_USE="|| ( ${USE_DOTNET} ) gac? ( net45 )"
RDEPEND="=dev-libs/libfreenect-${PV}"
DEPEND="${RDEPEND}"
PYTHON_DEPEND="!bindist? 2"
SLOT="0"
inherit dotnet
EGIT_COMMIT="7cb0d3c3c43c9cc25a39492668858fd554c46e99"
SRC_URI="https://github.com/OpenKinect/${PN}/archive/${EGIT_COMMIT}.tar.gz
		-> ${P}.tar.gz"
inherit gac
S="${WORKDIR}/${PN}-${EGIT_COMMIT}"

src_prepare() {
	default
	sed -i -e "s|\"freenect\"|\"libfreenect.dll\"|g" \
		wrappers/csharp/src/lib/KinectNative.cs || die
	estrong_assembly_info "using System.Runtime.CompilerServices;" \
		"${DISTDIR}/mono.snk" \
		"wrappers/csharp/src/test/ConsoleTest/AssemblyInfo.cs"
	estrong_assembly_info "using System.Runtime.CompilerServices;" \
		"${DISTDIR}/mono.snk" \
		"wrappers/csharp/src/lib/AssemblyInfo.cs"
	dotnet_copy_sources
}

src_compile() {
	compile_impl() {
		dotnet_copy_dllmap_config \
			"${FILESDIR}/freenectdotnet.dll.config"
		cd "wrappers/csharp/src/lib/VS2010"
	        einfo "Building solution"
	        exbuild "freenectdotnet.sln" || die
	}
	dotnet_foreach_impl compile_impl
}

src_install() {
	local mydebug=$(usex debug "Debug" "Release")
	install_impl() {
		dotnet_install_loc
		use developer && \
			doins "wrappers/csharp/bin/freenectdotnet.dll.mdb"
                doins freenectdotnet.dll.config
		doins wrappers/csharp/bin/freenectdotnet.dll
		if [[ "${EDOTNET}" == net45 ]]; then
	                egacinstall "wrappers/csharp/bin/freenectdotnet.dll"
			dotnet_distribute_file_matching_dll_in_gac \
				"wrappers/csharp/bin/freenectdotnet.dll" \
				"freenectdotnet.dll.config"
		fi
	}
	dotnet_foreach_impl install_impl
	dotnet_multilib_comply
}
