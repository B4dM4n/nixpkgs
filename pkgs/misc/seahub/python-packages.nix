{ python, fetchFromGitHub }:

python.override {
  packageOverrides = self: super: {
    django = self.django_1_11;
    django-webpack_loader = self.django-webpack-loader;

    captcha = self.buildPythonPackage rec {
      pname = "captcha";
      version = "0.3";

      src = self.fetchPypi {
        inherit pname version;
        sha256 = "1ql38qnrn43s9i3z4cq1ji2jcsz3g1cj4w2y8527r8z01l98mcm6";
      };

      propagatedBuildInputs = with self; [ pillow ];
      checkInputs = with self;[ nose ];
    };

    django-formtools = self.buildPythonPackage rec {
      pname = "django-formtools";
      version = "2.2";

      src = self.fetchPypi {
        inherit pname version;
        sha256 = "1chkbl188yj6hvhh1wgjpfgql553k6hrfwxzb8vv4lfdq41jq9y5";
      };

      propagatedBuildInputs = with self; [ django ];

      doCheck = false;
    };

    django-post_office = self.buildPythonPackage rec {
      pname = "django-post_office";
      version = "3.2.1";

      src = self.fetchPypi {
        inherit pname version;
        sha256 = "195j6hw1zw11n263gs60gs1gkycyjk591xwla1bijxv45y12f973";
      };

      propagatedBuildInputs = with self; [ django jsonfield ];

      doCheck = false;
    };

    jsonfield = self.buildPythonPackage rec {
      pname = "jsonfield";
      version = "2.1.1";

      src = self.fetchPypi {
        inherit pname version;
        sha256 = "1ivdkb2n91xqw3q2dcznvvk05r7z0bkz3gmym0j3wig954c5wz7d";
      };

      propagatedBuildInputs = with self; [ django six ];
    };

    django-statici18n = self.buildPythonPackage rec {
      pname = "django-statici18n";
      version = "1.9.0";

      src = self.fetchPypi {
        inherit pname version;
        sha256 = "1l6iyijflhwhn9p7v1bygl3w88dqrys6r06vn4ly3jxbq5bd0gci";
      };

      propagatedBuildInputs = with self; [ six django-appconf ];
    };

    django-appconf = self.buildPythonPackage rec {
      pname = "django-appconf";
      version = "1.0.4";

      src = self.fetchPypi {
        inherit pname version;
        sha256 = "101k8nkc7xlffpjdi2qbrp9pc4v8hzvmkzi12qp7vms39asxwn5y";
      };

      propagatedBuildInputs = with self; [ django ];

      doCheck = false;
    };
  };
}
