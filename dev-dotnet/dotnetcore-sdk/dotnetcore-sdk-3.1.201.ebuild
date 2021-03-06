# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# This package is like a virtual package
# The https://github.com/dotnet/cli is the ".NET Core SDK" package on the GitHub
# release page not the https://github.com/dotnet/sdk

EAPI=7
DESCRIPTION="Core functionality needed to create .NET Core projects, that is \
shared between Visual Studio and CLI"
HOMEPAGE="https://github.com/dotnet/sdk"
LICENSE="MIT"
KEYWORDS="~amd64 ~arm ~arm64 ~x86"
IUSE="samples docs"
RESTRICT="fetch"
SLOT="0"
# split due to flaky servers
CORE_V=3.1.3
RDEPEND="=dev-dotnet/core-${CORE_V}[samples?,docs?]
	 =dev-dotnet/coreclr-${CORE_V}
	 =dev-dotnet/corefx-${CORE_V}
	 =dev-dotnet/cli-tools-${PV}
	 =dev-dotnet/aspnetcore-${CORE_V}"
