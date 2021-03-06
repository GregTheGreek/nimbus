{ stdenv, lib, makeWrapper, git, nodejs, openssl, pcre, readline, sqlite }:

stdenv.mkDerivation rec {
  # This derivation may be a bit confusing at first, because it builds the Status'
  # Nimbus branch of Nim using the standard Nim compiler provided by Nix.
  #
  # It's mostly a copy of the original Nim recipe, but uses git to obtain the
  # sources and have a simplified `buildPhase`.
  #
  # For maintainance, you only need to bump the obtained git revision from time
  # to time.

  name = "status-nim";
  version = "0.18.1";

  src = fetchGit {
    url = "git://github.com/status-im/Nim";
    ref = "nimbus";

    # Set this to the hash of the head commit in the nimbus branch:
    rev = "c240806756579c3375b1a79e1e65c40087a52ac5";
  };

  doCheck = true;

  enableParallelBuilding = true;

  NIX_LDFLAGS = [
    "-lcrypto"
    "-lpcre"
    "-lreadline"
    "-lsqlite3"
  ];

  # 1. nodejs is only needed for tests
  # 2. we could create a separate derivation for the "written in c" version of nim
  #    used for bootstrapping, but koch insists on moving the nim compiler around
  #    as part of building it, so it cannot be read-only

  buildInputs  = [
    makeWrapper nodejs
    openssl pcre readline sqlite git
  ];

  buildPhase   = ''
    export HOME=$TMP
    export GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt
    sh build_all.sh
  '';

  installPhase = ''
    install -Dt $out/bin bin/* koch
    ./koch install $out
    mv $out/nim/bin/* $out/bin/ && rmdir $out/nim/bin
    mv $out/nim/*     $out/     && rmdir $out/nim
    wrapProgram $out/bin/nim \
      --suffix PATH : ${lib.makeBinPath [ stdenv.cc ]}
  '';

  meta = with stdenv.lib; {
    description = "Status's build of Nim";
    homepage = https://nim-lang.org/;
    license = licenses.mit;
    maintainers = with maintainers; [ ehmry peterhoeg ];
    platforms = with platforms; linux ++ darwin; # arbitrary
  };
}

