{ stdenv, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "smokeping_prober";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "SuperQ";
    repo = pname;
    rev = "v${version}";
    sha256 = "088c8lp07k7j7d76ikk6j1sz8hh2jh12bgbxpdj59s93nn4ccsfa";
  };

  modSha256 = "1rpjq31674dly2vjznbq8m3zbzrwp4x937z64x12qlwxw0bxdi7b";

  meta = with stdenv.lib; {
    description = "Prometheus style 'smokeping' prober";
    homepage = "https://github.com/SuperQ/smokeping_prober";
    license = licenses.asl20;
    maintainers = with maintainers; [ b4dm4n ];
  };
}
