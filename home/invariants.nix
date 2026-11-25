{
  config,
  lib,
  system,
  ...
}:
{
  assertions = [
    {
      assertion = !config.gtk.enable || lib.hasSuffix "linux" system;
      message = "GTK theming is only supported on Linux.";
    }
  ];
}
