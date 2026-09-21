{ pkgs, ... }:

let
  mcbToolchain = pkgs.writeShellApplication {
    name = "mcb-toolchain";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.jq
    ];
    text = builtins.readFile ./mcb-toolchain;
  };

  pack = pkgs.writeShellApplication {
    name = "pack";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnutar
      pkgs.pv
      pkgs.xz
      pkgs.zstd
    ];
    text = ''
      set -euo pipefail

      temp_output=
      cleanup() {
        if [ -n "$temp_output" ]; then
          rm -f -- "$temp_output"
        fi
      }
      trap cleanup EXIT

      usage() {
        cat <<'EOF'
      Usage:
        pack [OPTIONS] [MODE] <path> [output]

      Create a tar archive with progress reporting.

      Modes:
        fast                  zstd -T0 -3   (fastest)
        normal                zstd -T0 -10  (default)
        high                  zstd -T0 -19
        max                   xz -T0 -9e

      Options:
        -h, --help            show this help and exit
        -V, --version         show version and exit
        --                    stop parsing options

      Examples:
        pack folder
        pack high folder
        pack max folder backup.tar.xz
      EOF
      }

      version() {
        printf '%s\n' 'pack 1.0.0'
      }

      fail() {
        printf 'pack: %s\n' "$1" >&2
        printf 'Try "pack --help" for usage.\n' >&2
        exit 2
      }

      resolve_path() {
        realpath --canonicalize-missing -- "$1"
      }

      is_inside_source() {
        [ -n "$source_root" ] || return 1
        if [ "$source_root" = "/" ]; then
          return 0
        fi
        case "$1" in
          "$source_root"|"$source_root"/*) return 0 ;;
          *) return 1 ;;
        esac
      }

      if [ "$#" -eq 0 ]; then
        usage >&2
        exit 2
      fi

      case "$1" in
        -h|--help)
          usage
          exit 0
          ;;
        -V|--version)
          version
          exit 0
          ;;
        --)
          shift
          ;;
        -* )
          fail "unknown option: $1"
          ;;
      esac

      mode=normal
      if [ "$#" -ge 2 ]; then
        case "$1" in
          fast|normal|high|max)
            mode="$1"
            shift
            ;;
        esac
      fi

      if [ "''${1:-}" = "--" ]; then
        shift
      elif case "''${1:-}" in -* ) true ;; *) false ;; esac; then
        fail "unknown option: $1"
      fi

      if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        usage >&2
        exit 2
      fi

      src="$1"
      if [ "$src" != "/" ]; then
        while [ "''${src%/}" != "$src" ]; do
          src="''${src%/}"
        done
      fi
      [ -n "$src" ] || fail 'source path is empty'
      [ -e "$src" ] || [ -L "$src" ] || fail "source does not exist: $src"

      case "$mode" in
        fast)
          extension=tar.zst
          compressor=(zstd -T0 -3)
          algorithm='zstd -T0 -3'
          ;;
        normal)
          extension=tar.zst
          compressor=(zstd -T0 -10)
          algorithm='zstd -T0 -10'
          ;;
        high)
          extension=tar.zst
          compressor=(zstd -T0 -19)
          algorithm='zstd -T0 -19'
          ;;
        max)
          extension=tar.xz
          compressor=(xz -T0 -9e)
          algorithm='xz -T0 -9e'
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac

      if [ "$src" = "/" ]; then
        archive_parent=/
        archive_base=.
      else
        case "$src" in
          */*)
            archive_parent="''${src%/*}"
            archive_base="''${src##*/}"
            [ -n "$archive_parent" ] || archive_parent=/
            ;;
          *)
            archive_parent=.
            archive_base="$src"
            ;;
        esac
      fi

      source_root=
      if [ -d "$src" ] && [ ! -L "$src" ]; then
        source_root=$(resolve_path "$src")
      fi

      if [ "$#" -eq 2 ]; then
        output="$2"
      else
        output="$archive_base.$extension"
      fi
      [ -n "$output" ] || fail 'output path is empty'

      if [ "$#" -eq 1 ] && [ -n "$source_root" ]; then
        output_path=$(resolve_path "$output")
        if is_inside_source "$output_path"; then
          if [ "$source_root" = "/" ]; then
            fail 'cannot safely archive /; choose a source path smaller than the filesystem root'
          fi
          default_parent="''${source_root%/*}"
          default_base="''${source_root##*/}"
          output="$default_parent/$default_base.$extension"
        fi
      fi

      case "$output" in
        */*)
          output_parent="''${output%/*}"
          output_name="''${output##*/}"
          [ -n "$output_parent" ] || output_parent=/
          ;;
        *)
          output_parent=.
          output_name="$output"
          ;;
      esac
      [ -n "$output_name" ] || fail "output must be a file path: $output"
      [ -d "$output_parent" ] || fail "output directory does not exist: $output_parent"
      [ ! -L "$output" ] || fail "refusing to replace symbolic link: $output"
      if [ -e "$output" ] && [ "$output" -ef "$src" ]; then
        fail "output refers to the source: $output"
      fi
      [ ! -d "$output" ] || fail "output is a directory: $output"

      output_path=$(resolve_path "$output")
      if is_inside_source "$output_path"; then
        fail "output must be outside the source directory: $output"
      fi

      if ! size=$(du -sb --apparent-size -- "$src" | cut -f1); then
        fail "cannot determine source size: $src"
      fi

      if ! temp_output=$(mktemp -- "$output_parent/.pack.XXXXXX"); then
        fail "cannot create temporary output in: $output_parent"
      fi
      printf 'Compressing: %s\nOutput:      %s\nAlgorithm:   %s\n\n' "$src" "$output" "$algorithm"

      if ! tar -C "$archive_parent" -cf - -- "$archive_base" \
        | pv -s "$size" \
        | "''${compressor[@]}" > "$temp_output"; then
        fail "compression failed for: $src"
      fi

      if ! mv -f -- "$temp_output" "$output"; then
        fail "cannot install output: $output"
      fi
      temp_output=
    '';
  };
in
{
  home.packages = [
    mcbToolchain
    pack
  ];
}
