#!/bin/bash

# Directorio donde están los módulos
MODULES_DIR="$HOME/Documentos/LabSopes1/Proyecto1_Fase1/Modulos"

# Nombres de los módulos
CPU_MODULE="cpu_202201947"
RAM_MODULE="ram_202201947"

# Colores para los mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # Sin color

# Función para verificar si un comando fue exitoso
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: $1${NC}"
        exit 1
    fi
}

echo "=== Eliminando módulos y limpiando servicios ==="

# 1. Cambiar al directorio de los módulos
cd "$MODULES_DIR" || {
    echo -e "${RED}No se pudo acceder al directorio $MODULES_DIR${NC}"
    exit 1
}

# 2. Descargar los módulos
echo "Descargando el módulo $CPU_MODULE..."
if lsmod | grep -q "$CPU_MODULE"; then
    sudo rmmod "$CPU_MODULE"
    check_error "No se pudo descargar el módulo $CPU_MODULE"
    echo -e "${GREEN}Módulo $CPU_MODULE descargado correctamente${NC}"
else
    echo "Módulo $CPU_MODULE no está cargado"
fi

echo "Descargando el módulo $RAM_MODULE..."
if lsmod | grep -q "$RAM_MODULE"; then
    sudo rmmod "$RAM_MODULE"
    check_error "No se pudo descargar el módulo $RAM_MODULE"
    echo -e "${GREEN}Módulo $RAM_MODULE descargado correctamente${NC}"
else
    echo "Módulo $RAM_MODULE no está cargado"
fi

# 3. Limpiar los archivos generados por la compilación
echo "Limpiando archivos generados..."
make clean
check_error "No se pudo limpiar los archivos generados"

# 4. Verificar que los archivos /proc hayan sido eliminados
echo "Verificando eliminación de archivos en /proc..."
if [ ! -f "/proc/$CPU_MODULE" ]; then
    echo -e "${GREEN}/proc/$CPU_MODULE eliminado correctamente${NC}"
else
    echo -e "${RED}/proc/$CPU_MODULE aún existe${NC}"
    exit 1
fi

if [ ! -f "/proc/$RAM_MODULE" ]; then
    echo -e "${GREEN}/proc/$RAM_MODULE eliminado correctamente${NC}"
else
    echo -e "${RED}/proc/$RAM_MODULE aún existe${NC}"
    exit 1
fi

echo -e "${GREEN}=== Limpieza completada ===${NC}"