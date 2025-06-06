#!/bin/bash

# Directorio donde están los módulos
MODULES_DIR="$HOME/Documentos/LabSopes1/Proyecto1_Fase1/Modulos"
SCRIPTS_DIR="$HOME/Documentos/LabSopes1/Proyecto1_Fase1/Scripts"

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

echo "=== Instalando y configurando módulos del kernel ==="

# 1. Cambiar al directorio de los módulos
cd "$MODULES_DIR" || {
    echo -e "${RED}No se pudo acceder al directorio $MODULES_DIR${NC}"
    exit 1
}

# 2. Compilar los módulos
echo "Compilando los módulos..."
make clean && make
check_error "No se pudo compilar los módulos"

# 3. Cargar los módulos
echo "Cargando el módulo $CPU_MODULE..."
sudo insmod "$CPU_MODULE.ko"
check_error "No se pudo cargar el módulo $CPU_MODULE"

echo "Cargando el módulo $RAM_MODULE..."
sudo insmod "$RAM_MODULE.ko"
check_error "No se pudo cargar el módulo $RAM_MODULE"

# 4. Verificar que los módulos estén cargados
echo "Verificando módulos cargados..."
if lsmod | grep -q "$CPU_MODULE"; then
    echo -e "${GREEN}Módulo $CPU_MODULE cargado correctamente${NC}"
else
    echo -e "${RED}Módulo $CPU_MODULE no está cargado${NC}"
    exit 1
fi

if lsmod | grep -q "$RAM_MODULE"; then
    echo -e "${GREEN}Módulo $RAM_MODULE cargado correctamente${NC}"
else
    echo -e "${RED}Módulo $RAM_MODULE no está cargado${NC}"
    exit 1
fi

# 5. Verificar que los archivos /proc estén creados
echo "Verificando archivos en /proc..."
if [ -f "/proc/$CPU_MODULE" ]; then
    echo -e "${GREEN}/proc/$CPU_MODULE creado correctamente${NC}"
    cat "/proc/$CPU_MODULE"
else
    echo -e "${RED}/proc/$CPU_MODULE no existe${NC}"
    exit 1
fi

if [ -f "/proc/$RAM_MODULE" ]; then
    echo -e "${GREEN}/proc/$RAM_MODULE creado correctamente${NC}"
    cat "/proc/$RAM_MODULE"
else
    echo -e "${RED}/proc/$RAM_MODULE no existe${NC}"
    exit 1
fi

echo -e "${GREEN}=== Instalación y configuración completada ===${NC}"