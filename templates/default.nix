# flakelight-chez -- Chez Scheme module for flakelight
# Copyright (C) 2023 Archit Gupta <archit@accelbread.com>
# SPDX-License-Identifier: MIT

rec {
  default = chez-bin;
  chez-bin = {
    path = ./chez-bin;
    description = "Template Chez Scheme application.";
    welcomeText = ''
      # Flakelight Chez Scheme template
      To use, create a main.ss file with your Scheme code.
      Run `nix develop` to enter the development environment.
    '';
  };
}
