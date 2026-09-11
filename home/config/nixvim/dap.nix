# DAP 复用现有 lldb-dap、dlv 与 uv debugpy。
{ config, lib, ... }:

let
  launchWithLldb = {
    type = "lldb";
    request = "launch";
    name = "Launch executable";
    program.__raw = ''
      function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end
    '';
    cwd = "\${workspaceFolder}";
    stopOnEntry = false;
  };
in
{
  programs.nixvim = {
    plugins = {
      dap = {
        enable = true;
        adapters.executables.lldb = {
          command = "lldb-dap";
          options.detached = false;
        };
        configurations = {
          c = [ launchWithLldb ];
          cpp = [ launchWithLldb ];
          rust = [ launchWithLldb ];
        };
        signs = {
          dapBreakpoint.text = "●";
          dapBreakpointCondition.text = "◆";
          dapBreakpointRejected.text = "○";
          dapLogPoint.text = "◆";
          dapStopped.text = "→";
        };
      };
      dap-go = {
        enable = true;
        settings.delve.path = "dlv";
      };
      dap-python = {
        enable = true;
        adapterPythonPath = "${config.home.homeDirectory}/.local/share/uv/tools/debugpy/bin/python";
      };
      dap-ui.enable = true;
      dap-virtual-text.enable = true;
    };

    extraConfigLua = lib.mkAfter ''
      local dap = require("dap")
      local dapui = require("dapui")

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    '';
  };
}
