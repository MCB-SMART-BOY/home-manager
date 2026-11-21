substituteInPlace autoload/mkdp/rpc.vim \
  --replace-fail "executable('node')" "executable('bun')" \
  --replace-fail "['node'," "['bun',"
substituteInPlace autoload/health/mkdp.vim \
  --replace-fail "executable('node')" "executable('bun')" \
  --replace-fail "'node --version'" "'bun --version'" \
  --replace-fail "Using node" "Using bun" \
  --replace-fail "Node version" "Bun version"
substituteInPlace app/lib/app/load.js \
  --replace-fail "userModule.require = userModule.require.bind(userModule);" \
  "userModule.require = module_1.default.createRequire(scriptPath);"
