_: prev: {
  tela-circle-icon-theme = prev.tela-circle-icon-theme.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # Upstream 2026-07-07 installs these aliases without their targets.
      # Keep noBrokenSymlinks enabled and leave future repaired links intact.
      for icon in \
        "$out/share/icons/Tela-circle-dracula/symbolic/apps/xsi-addon-symbolic.svg" \
        "$out/share/icons/Tela-circle-dracula/scalable/apps/org.xfce.appfinder.svg" \
        "$out/share/icons/Tela-circle-dracula-dark/symbolic/apps/xsi-addon-symbolic.svg"; do
        if [ -L "$icon" ] && [ ! -e "$icon" ]; then
          rm -- "$icon"
        fi
      done
    '';
  });
}
