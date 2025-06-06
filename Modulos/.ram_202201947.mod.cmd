savedcmd_ram_202201947.mod := printf '%s\n'   ram_202201947.o | awk '!x[$$0]++ { print("./"$$0) }' > ram_202201947.mod
