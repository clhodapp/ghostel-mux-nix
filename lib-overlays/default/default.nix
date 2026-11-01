# SPDX-License-Identifier: MIT
{ ... }:
{

  overlay = final: prev: {
    ghostel-mux = prev.ghostel-mux or { };
  };

}
