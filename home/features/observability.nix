{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bpftrace
    bcc
    perf
    trace-cmd
    kernelshark
    valgrind
    rr
    flamegraph
    hotspot
    fio
    ioping
    sysdig
    lnav
  ];
}
