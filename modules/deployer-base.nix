with (import ../lib.nix);

let
  iohk-pkgs = import ../default.nix {};
in

{ config, pkgs, ... }: {
  imports = [ ./common.nix ];

  networking.hostName = "deployer-${config.deployment.name}";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.dd-agent.tags = [ "role:deployer" "depl:${config.deployment.name}" ];

  environment.systemPackages = (with iohk-pkgs; [
    terraform
    mfa
  ]) ++ (with pkgs; [
    awscli
    gnupg
    htop
    jq
    nixops
    psmisc
    python3
    vim
    yq
  ]);

  users.groups.deployers = {};
  users.users.deployer = (import ../lib/users/deployer-users.nix).deployer;
}
