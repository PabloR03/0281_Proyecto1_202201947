savedcmd_sysinfos.mod := printf '%s\n'   sysinfos.o | awk '!x[$$0]++ { print("./"$$0) }' > sysinfos.mod
