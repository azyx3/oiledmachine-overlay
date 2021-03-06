# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
DESCRIPTION="Nuget - .NET Package Manager"
HOMEPAGE="http://nuget.codeplex.com"
LICENSE="Apache-2.0"
KEYWORDS="~amd64 ~x86"
USE_DOTNET="net40"
REQUIRED_USE="|| ( ${USE_DOTNET} ) gac? ( net40 )"
SLOT="0/${PV}"
DEPEND="<=dev-dotnet/xdt-for-monodevelop-2.8.2[gac]
	 !dev-dotnet/nuget-codeplex
	  app-misc/ca-certificates"
RDEPEND="${DEPEND}"
inherit dotnet eutils
# This ebuild uses a forked version of nuget modified to work with MonoDevelop.
# See https://bugzilla.xamarin.com/show_bug.cgi?id=27693
# dev-dotnet/nuget-codeplex provides the upstream version.
SRC_URI=\
"https://github.com/mrward/nuget/archive/Release-${PV}-MonoDevelop.tar.gz \
	-> ${P}.tar.gz"
inherit gac
S="${WORKDIR}/nuget-Release-${PV}-MonoDevelop"

pkg_setup() {
	dotnet_pkg_setup
	cert-sync /etc/ssl/certs/ca-certificates.crt
        if has sandbox $FEATURES || has usersandbox $FEATURES ; then
                eerror "${PN} require sandbox and usersandbox to be disabled in"
		eerror "FEATURES on a per-package basis."
		die
        fi
        if has network-sandbox $FEATURES ; then
                eerror "${PN} require network-sandbox to be disabled in"
		eerror "FEATURES on a per-package basis."
		die
        fi
}

src_prepare() {
	default
	sed -i -e 's@RunTests@ @g' "${S}/Build/Build.proj" || die
	cp "${FILESDIR}/rsa-4096.snk" "${S}/src/Core/" || die
	eapply "${FILESDIR}/add-keyfile-option-to-csproj-r2.patch"
	sed -i -E -e "s#(\[assembly: InternalsVisibleTo(.*)\])#/* \1 */#g" \
		"src/Core/Properties/AssemblyInfo.cs" || die
	eapply "${FILESDIR}/strongnames-for-ebuild-2.8.1-r2.patch"
}

src_configure() {
	export EnableNuGetPackageRestore="true"
}

src_compile() {
	source ./build.sh || die
}

src_install() {
	estrong_resign "src/Core/obj/Mono Release/NuGet.Core.dll" \
		src/Core/rsa-4096.snk
	egacinstall "src/Core/obj/Mono Release/NuGet.Core.dll"
	insinto /usr/lib/mono/NuGet/"${FRAMEWORK}"/
	doins src/CommandLine/obj/Mono\ Release/NuGet.exe
	make_wrapper nuget "mono /usr/lib/mono/NuGet/${FRAMEWORK}/NuGet.exe"
}
