{ fetchurl
, fetchpatch
, stdenv
, perl
, libxml2
, postgresql
, geos
, proj
, flex
, gdal
, json_c
, pkgconfig
, file
}:

  /*

  ### NixOS - usage:
  ==================

    services.postgresql.extraPlugins = [ (pkgs.postgis.override { postgresql = pkgs.postgresql95; }) ];


  ### important Postgis implementation details:
  =============================================

    Postgis provides a shared library implementing many operations. They are
    exposed to the Postgres SQL interpreter by special SQL queries eg:

      CREATE FUNCTION [...]
              AS '[..]liblwgeom', 'lwhistogram2d_in' LANGUAGE 'C' IMMUTABLE STRICT; -- WITH (isstrict);

   where liblwgeom is the shared library.
   Postgis < 1.5 used absolute paths, in NixOS $libdir is always used.

   Thus if you want to use postgresql dumps which were created by non NixOS
   systems you have to adopt the library path.


   ### TODO:
   =========
   the bin commands to have gtk gui:
  */


let
  version = "2.4.3";
  sha256 = "1fg4pmla5m903m76ndjd8q5dkcykf67v1p4dcajmnr3bvg2p8lza";
in stdenv.mkDerivation rec {
  name = "postgis-${version}";

  src = fetchurl {
    url = "http://download.osgeo.org/postgis/source/postgis-${builtins.toString version}.tar.gz";
    inherit sha256;
  };

  patches = [
    (fetchpatch {
      url = "https://trac.osgeo.org/postgis/changeset/16417?format=diff&new=16417";
      name = "json-c-0.13.patch";
      sha256 = "1hk2fh4nsvq76ksi7z4shlgj7fik6ac3sjsb0khsypsjfhz7ic8z";
      stripLen = 3;
      extraPrefix = "";
      excludes = [ "NEWS" ];
    })
  ];

  # don't pass these vars to the builder
  removeAttrs = ["sql_comments" "sql_srcs"];

  preInstall = ''
    mkdir -p $out/bin
  '';

  # create aliases for all commands adding version information
  postInstall = ''
    sql_srcs=$(for sql in ${builtins.toString sql_srcs}; do echo -n "$(find $out -iname "$sql") "; done )

    for prog in $out/bin/*; do # */
      ln -s $prog $prog-${version}
    done

    cp -r doc $out
  '';

  buildInputs = [ libxml2 postgresql geos proj perl gdal json_c pkgconfig ];

  sql_comments = "postgis_comments.sql";

  sql_srcs = ["postgis.sql" "spatial_ref_sys.sql"];

  # postgis config directory assumes /include /lib from the same root for json-c library
  NIX_LDFLAGS = "-L${stdenv.lib.getLib json_c}/lib";

  dontDisableStatic = true;
  preConfigure = ''
    sed -i 's@/usr/bin/file@${file}/bin/file@' configure
    configureFlags="--datadir=$out/share --datarootdir=$out/share --bindir=$out/bin --with-gdalconfig=${gdal}/bin/gdal-config --with-jsondir=${json_c.dev}"
    makeFlags="PERL=${perl}/bin/perl datadir=$out/share pkglibdir=$out/lib bindir=$out/bin"
  '';
  postConfigure = ''
    sed -i "s|@mkdir -p \$(DESTDIR)\$(PGSQL_BINDIR)||g ;
            s|\$(DESTDIR)\$(PGSQL_BINDIR)|$prefix/bin|g
            " \
        "raster/loader/Makefile";
    sed -i "s|\$(DESTDIR)\$(PGSQL_BINDIR)|$prefix/bin|g
            " \
        "raster/scripts/python/Makefile";
  '';

  meta = with stdenv.lib; {
    description = "Geographic Objects for PostgreSQL";
    homepage = http://postgis.refractions.net;
    license = licenses.gpl2;
    maintainers = [ maintainers.marcweber ];
    platforms = platforms.linux;
  };
}