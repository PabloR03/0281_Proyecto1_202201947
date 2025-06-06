#!/bin/bash

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

echo "=== Eliminando contenedores de estrés ==="

# 1. Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker no está instalado. Por favor, instala Docker primero.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker está instalado: $(docker --version)${NC}"

# 2. Verificar si hay contenedores de estrés para eliminar
echo "Buscando contenedores de estrés..."
if docker ps -aq --filter name=stress_ | grep -q .; then
    echo "Contenedores encontrados. Eliminando..."
    docker rm -f $(docker ps -aq --filter name=stress_)
    check_error "No se pudo eliminar los contenedores de estrés"
    echo -e "${GREEN}Contenedores de estrés eliminados correctamente${NC}"
else
    echo -e "${GREEN}No hay contenedores de estrés para eliminar${NC}"
fi

echo -e "${GREEN}=== Limpieza de contenedores completada ===${NC}"