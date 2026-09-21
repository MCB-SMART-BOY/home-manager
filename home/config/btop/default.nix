{ lib, pkgs, ... }:

let
  btopWithNixOSDriver = pkgs.writeShellApplication {
    name = "btop";
    text = ''
      export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.btop}/bin/btop "$@"
    '';
  };
in
{
  programs.btop = {
    enable = true;
    # Home Manager's portable profile is also used directly on NixOS.
    # Keep the explicit NixOS module authoritative when it is imported.
    package = lib.mkDefault (if builtins.pathExists /etc/NIXOS then btopWithNixOSDriver else pkgs.btop);
    settings = {
      # Catppuccin Mocha/Purple: opaque and consistent with the desktop theme.
      color_theme = "catppuccin";
      theme_background = true;
      truecolor = true;
      force_tty = false;
      disable_presets = "Off";
      vim_keys = false;
      disable_mouse = false;
      rounded_corners = true;
      terminal_sync = true;

      # High-resolution graphs for the full monitoring layout.
      graph_symbol = "braille";
      graph_symbol_cpu = "braille";
      graph_symbol_gpu = "braille";
      graph_symbol_mem = "braille";
      graph_symbol_net = "braille";
      graph_symbol_proc = "braille";
      shown_boxes = "cpu mem net proc gpu0";
      update_ms = 2000;

      # Processes: useful hierarchy, stable ordering, readable resource data.
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = true;
      proc_colors = true;
      proc_gradient = false;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = true;
      proc_follow_detailed = true;
      proc_aggregate = true;
      keep_dead_proc_usage = false;

      # CPU: temperature, per-core data, average frequency and power when
      # the kernel exposes the required counters.
      show_gpu_info = "On";
      cpu_graph_upper = "Auto";
      cpu_graph_lower = "Auto";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      show_cpu_watts = true;
      check_temp = true;
      show_coretemp = true;
      temp_scale = "celsius";
      show_cpu_freq = true;
      freq_mode = "average";
      background_update = true;

      # Memory, swap and disks: retain capacity information while showing
      # read/write activity in the disk panel.
      base_10_sizes = false;
      mem_graphs = true;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = false;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = true;
      io_graph_combined = false;
      io_graph_speeds = "";
      disks_filter = "";

      # Network: automatically select the active interface and scale both
      # directions together so bursts remain readable.
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;
      net_iface = "";
      base_10_bitrate = "Auto";
      swap_upload_download = false;

      # Laptop battery and NVIDIA/AMD/Intel GPU telemetry.
      show_battery = true;
      selected_battery = "Auto";
      show_battery_watts = true;
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      gpu_mirror_graph = false;
      shown_gpus = "nvidia amd intel apple";

      # Keep the declarative Home Manager file authoritative.
      save_config_on_exit = false;
    };
    themes.catppuccin = ./themes/catppuccin.theme;
  };
}
