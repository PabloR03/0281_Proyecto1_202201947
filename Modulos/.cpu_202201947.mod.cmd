savedcmd_cpu_202201947.mod := printf '%s\n'   cpu_202201947.o | awk '!x[$$0]++ { print("./"$$0) }' > cpu_202201947.mod
