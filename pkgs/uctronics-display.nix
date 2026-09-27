{
  lib,
  stdenv,
  fetchFromGitHub,
  gnumake,
}:

stdenv.mkDerivation {
  pname = "uctronics-rm0004-display";
  version = "unstable-2025-06-09";

  src = fetchFromGitHub {
    owner = "UCTRONICS";
    repo = "SKU_RM0004";
    rev = "a9cfa2345f83d4e2f0ea8013d3634eee42105bb0";
    hash = "sha256-LVyBDiLn+DmBg0knHMH6vlplaprezRAj4IstEkOhdzo=";
  };

  nativeBuildInputs = [ gnumake ];

  buildPhase = ''
    runHook preBuild
    make
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 display "$out/bin/uctronics-display"
    runHook postInstall
  '';

  meta = {
    description = "Status-screen driver for the UCTRONICS RM0004 / UC-B86 Raspberry Pi NVMe hat's onboard display";
    homepage = "https://github.com/UCTRONICS/SKU_RM0004";
    license = lib.licenses.unfree;
    platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];
    mainProgram = "uctronics-display";
  };
}
