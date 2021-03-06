#
# spec file for package yast2-registration
#
# Copyright (c) 2014 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-registration
Version:        3.1.2
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0

Requires:       yast2 >= 2.23.13
Requires:       yast2-pkg-bindings >= 2.17.20
Requires:       yast2-ruby-bindings >= 1.0.0
# provides "lscpu"
Requires:       util-linux

BuildRequires:  yast2 >= 2.23.13
BuildRequires:  update-desktop-files
BuildRequires:  yast2-devtools >= 3.1.6

BuildArch:      noarch

Summary:        YaST2 - Registration Module

%description
The registration module to register products and/or to fetch an update
source (mirror) automatically.


Authors:
--------
    Ladislav Slezak <lslezak@suse.cz>

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%{yast_desktopdir}/customer_center.desktop
%{yast_clientdir}/*.rb
%dir %{yast_libdir}
%dir %{yast_libdir}/registration
%{yast_libdir}/registration/*.rb
%doc %{yast_docdir}

%changelog
