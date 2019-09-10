# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=6

USE_DOTNET="net45"
IUSE="${USE_DOTNET} debug gac developer gtk-sharp3 gtk-sharp2"
REQUIRED_USE="|| ( ${USE_DOTNET} ) gac? ( net45 ) || ( gtk-sharp3 gtk-sharp2 )"
RDEPEND=">=dev-util/monodevelop-5
	 gtk-sharp3? ( dev-dotnet/gtk-sharp:3 )
	 gtk-sharp2? ( dev-dotnet/gtk-sharp:2 )
         net45? ( dev-dotnet/referenceassemblies-pcl )"
DEPEND="${RDEPEND}"

inherit dotnet eutils mono gac

DESCRIPTION="Cross platform GUI framework for desktop and mobile applications in .NET"
HOMEPAGE="https://github.com/picoe/Eto"
COMMIT="d7a6d4bbdb5ac1263d3036d9177cadcfb2f0e63e"
SRC_URI="https://github.com/picoe/Eto/archive/${COMMIT}.tar.gz -> ${PN}-${PV}.tar.gz"

inherit gac

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ppc64 ~x86"
MY_PN="Eto"
S="${WORKDIR}/${MY_PN}-${COMMIT}"

src_prepare() {
	default
	epatch "${FILESDIR}/${PN}-9999.20171218-remove-projects.patch"
	epatch "${FILESDIR}/${PN}-9999.20171218-posx.patch"
	epatch "${FILESDIR}/${PN}-9999.20171218-prevnextsel.patch"
	epatch "${FILESDIR}/${PN}-9999.20171218-suppress-warnings.patch"
	epatch "${FILESDIR}/${PN}-9999.20171218-csharp6-compat.patch"
	epatch "${FILESDIR}/${PN}-9999.20171218-context.patch"
	epatch "${FILESDIR}/${PN}-9999.20171218-targets.patch"

	PCL_OLD_VERSION="259"
	PCL_NEW_VERSION="78"
	sed -i -r -e "s|Profile${PCL_OLD_VERSION}|Profile${PCL_NEW_VERSION}|g" "${S}/Source/Eto/Eto - pcl.csproj" || die
	sed -i -r -e "s|Profile${PCL_OLD_VERSION}|Profile${PCL_NEW_VERSION}|g" "${S}/Source/Eto.Serialization.Json/Eto.Serialization.Json - pcl.csproj" || die
	sed -i -r -e "s|Profile${PCL_OLD_VERSION}|Profile${PCL_NEW_VERSION}|g" "${S}/Source/Eto.Serialization.Xaml/Eto.Serialization.Xaml - pcl.csproj" || die
	sed -i -r -e "s|Profile${PCL_OLD_VERSION}|Profile${PCL_NEW_VERSION}|g" "${S}/Source/Eto.Test/Eto.Test/Eto.Test - pcl.csproj" || die

	dotnet_copy_sources
}

src_compile() {
	mydebug="Release"
	if use debug; then
		mydebug="Debug"
	fi

	compile_impl() {
		cd "Source"

	        einfo "Building solution"
	        exbuild /p:Configuration=${mydebug} ${STRONG_ARGS_NETFX}${DISTDIR}/mono.snk 'Eto - net45.sln' || die
	}

	dotnet_foreach_impl compile_impl
}

src_install() {
	mydebug="Release"
	if use debug; then
		mydebug="Debug"
	fi

	install_impl() {
		local d
		if [[ "${EDOTNET}" =~ netstandard ]] ; then
			d=$(dotnet_netcore_install_loc ${EDOTNET})
		elif dotnet_is_netfx "${EDOTNET}" ; then
			d=$(dotnet_netfx_install_loc ${EDOTNET})
		fi
		insinto "${d}"

		if use gac ; then
			egacinstall "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.dll"
			use gtk-sharp3 && egacinstall "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.Gtk3.dll"
			use gtk-sharp2 && egacinstall "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.Gtk2.dll"
			egacinstall "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.Serialization.Json.dll"
		fi
		doins "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.dll"
		use gtk-sharp3 && doins "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.Gtk3.dll"
		use gtk-sharp2 && doins "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.Gtk2.dll"
		doins "BuildOutput/$(dotnet_use_flag_moniker_to_ms_moniker ${EDOTNET})/${mydebug}/Eto.Serialization.Json.dll"
	}

	dotnet_foreach_impl install_impl

	dotnet_multilib_comply
}
