# NixOS Configuration for a Tor Middle Relay on Hetzner Cloud
# 
# Features:
# - Tor Middle Relay on Port 443 (IPv4 & IPv6)
# - Traffic limitation (15TB/Month) and Bandwidth throttling (100Mbit)
# - Automatic nightly updates & reboot
# - Hardened with Fail2Ban
# - Configured for GRUB on GPT (Hetzner BIOS Compatibility)

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # NOTE: You must generate this file locally using 'nixos-generate-config'
      ./hardware-configuration.nix
    ];

  # ---------------------------------------------------------
  # BOOTLOADER SETTINGS
  # ---------------------------------------------------------
  # Hetzner Cloud VPS often starts in Legacy BIOS mode even with GPT partitions.
  # We use GRUB instead of systemd-boot to ensure compatibility.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # Install GRUB to MBR
  boot.loader.systemd-boot.enable = false; # Disable UEFI bootloader

  # ---------------------------------------------------------
  # SYSTEM BASICS
  # ---------------------------------------------------------
  time.timeZone = "Europe/Berlin"; # TODO: Set your timezone
  i18n.defaultLocale = "en_US.UTF-8";
  
  # This value determines the NixOS release with which your system is to be compatible.
  # Do not change this after the initial install.
  system.stateVersion = "24.11"; 

  # ---------------------------------------------------------
  # NETWORK & FIREWALL
  # ---------------------------------------------------------
  networking.hostName = "YOUR_HOSTNAME"; # TODO: Set your hostname
  networking.enableIPv6 = true;
  
  # Open necessary ports:
  # 22  = SSH Access
  # 443 = Tor ORPort
  networking.firewall.allowedTCPPorts = [ 22 443 ];

  # ---------------------------------------------------------
  # USER & SECURITY
  # ---------------------------------------------------------
  users.users.mainuser = {
    name = "YOUR_USERNAME"; # TODO: Set your username
    isNormalUser = true;
    description = "Primary User";
    extraGroups = [ "wheel" ]; # Enable 'sudo' for this user
    
    # NOTE: It is highly recommended to use SSH keys instead of passwords.
    # If you want to use keys, uncomment the following lines and add your key:
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
  };

  services.openssh = {
    enable = true;
    settings = {
      # TODO: Set to 'false' if you use SSH keys (Recommended!)
      PasswordAuthentication = true; 
      PermitRootLogin = "no";
    };
  };

  # Fail2Ban: Protects SSH against brute-force attacks
  # Bans IP for 1 hour after 5 failed login attempts
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
  };

  # ---------------------------------------------------------
  # TOR RELAY CONFIGURATION
  # ---------------------------------------------------------
  services.tor = {
    enable = true;
    relay = {
      enable = true;
      role = "relay"; # Middle Relay (Non-Exit)
    };

    settings = {
      # TODO: Choose a nickname (Max 19 characters, A-Z, 0-9)
      Nickname = "YOUR_RELAY_NICKNAME"; 
      
      # TODO: (Optional) Add your email so Tor admins can contact you if needed
      # ContactInfo = "email@example.com";

      # ORPort Configuration
      # Listens on Port 443 for both IPv4 and IPv6
      ORPort = [
        { port = 443; addr = "0.0.0.0"; }
        { port = 443; addr = "[::]"; }
      ];
      
      # Bandwidth Limits (100 Mbit/s)
      RelayBandwidthRate = "12.5 MBytes";
      RelayBandwidthBurst = "15 MBytes";
      
      # Monthly Traffic Limit (15 TB)
      # Resets on the 1st of every month
      AccountingMax = "15 TBytes";
      AccountingStart = "month 1 00:00";
      
      # Exit Policy: Reject all exit traffic (Middle Node only)
      ExitPolicy = [
        "reject *:*"
        "reject6 *:*"
      ];
    };
  };

  # ---------------------------------------------------------
  # MAINTENANCE & TOOLS
  # ---------------------------------------------------------
  environment.systemPackages = with pkgs; [ 
    nyx   # Tor monitoring tool
    vim
    htop
    git
  ];

  # Automatic System Updates
  # Checks daily at 04:00 AM and reboots if necessary
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    channel = "https://nixos.org/channels/nixos-24.11";
    dates = "04:00";
  };

  # Garbage Collection
  # Deletes configuration generations older than 2 days to save disk space
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 2d";
  };
  
  # Optimize Nix Store automatically
  nix.settings.auto-optimise-store = true;
}
