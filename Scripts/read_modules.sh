#!/bin/bash

# Nombres de los módulos
CPU_MODULE="cpu_202201947"
RAM_MODULE="ram_202201947"

# Colores para los mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # Sin color

echo "=== Leyendo información de los módulos ==="

# 1. Verificar si los módulos están cargados
echo "Verificando módulos cargados..."
if lsmod | grep -q "$CPU_MODULE"; then
    echo -e "${GREEN}Módulo $CPU_MODULE está cargado${NC}"
else
    echo -e "${RED}Módulo $CPU_MODULE no está cargado. Por favor, carga los módulos primero con install_modules.sh${NC}"
    exit 1
fi

if lsmod | grep -q "$RAM_MODULE"; then
    echo -e "${GREEN}Módulo $RAM_MODULE está cargado${NC}"
else
    echo -e "${RED}Módulo $RAM_MODULE no está cargado. Por favor, carga los módulos primero con install_modules.sh${NC}"
    exit 1
fi

# 2. Leer los archivos /proc
echo "Leyendo métricas de CPU..."
if [ -f "/proc/$CPU_MODULE" ]; then
    cat "/proc/$CPU_MODULE"
else
    echo -e "${RED}No se encontró /proc/$CPU_MODULE${NC}"
    exit 1
fi

echo "Leyendo métricas de RAM..."
if [ -f "/proc/$RAM_MODULE" ]; then
    cat "/proc/$RAM_MODULE"
else
    echo -e "${RED}No se encontró /proc/$RAM_MODULE${NC}"
    exit 1
fi

echo -e "${GREEN}=== Lectura completada ===${NC}"