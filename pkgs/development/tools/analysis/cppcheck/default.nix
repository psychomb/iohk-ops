{ stdenv, fetchurl, libxslt, docbook_xsl, docbook_xml_dtd_45, pcre }:

stdenv.mkDerivation rec {
  pname = "cppcheck";
  version = "1.83";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "mirror://sourceforge/${pname}/${name}.tar.bz2";
    sha256 = "14d4afjz0jshwpqryvwvzrs3rrqnd7cgg3x19awgy116591ibd83";
  };

  buildInputs = [ pcre ];
  nativeBuildInputs = [ libxslt docbook_xsl docbook_xml_dtd_45 ];

  makeFlags = ''PREFIX=$(out) CFGDIR=$(out)/cfg HAVE_RULES=yes'';

  outputs = [ "out" "man" ];

  enableParallelBuilding = true;

  postInstall = ''
    make DB2MAN=${docbook_xsl}/xml/xsl/docbook/manpages/docbook.xsl man
    mkdir -p $man/share/man/man1
    cp cppcheck.1 $man/share/man/man1/cppcheck.1
  '';

  meta = with stdenv.lib; {
    description = "A static analysis tool for C/C++ code";
    longDescription = ''
      Check C/C++ code for memory leaks, mismatching allocation-deallocation,
      buffer overruns and more.
    '';
    homepage = http://cppcheck.sourceforge.net/;
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ joachifm ];
  };
}