#!/bin/bash

# Colores para los mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # Sin color

# Definir las opciones de consumo (usando stress)
OPTIONS=(
    "--cpu 1"                     # CPU
    "--io 1"                      # I/O
    "--vm 1 --vm-bytes 256M"      # RAM
    "--hdd 1"                     # Disco
)

echo "=== Script para desplegar 10 contenedores de estrés ==="

# 1. Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker no está instalado. Por favor, instala Docker primero.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker está instalado: $(docker --version)${NC}"

# 2. Verificar si la imagen containerstack/alpine-stress está presente
echo "Verificando imagen containerstack/alpine-stress..."
if ! docker image inspect containerstack/alpine-stress > /dev/null 2>&1; then
    echo -e "${RED}La imagen containerstack/alpine-stress no está disponible${NC}"
    exit 1
fi
echo -e "${GREEN}Imagen containerstack/alpine-stress lista${NC}"

# 3. Crear 10 contenedores con nombres únicos
echo "Desplegando 10 contenedores para estresar recursos..."
for i in {1..10}; do
    # Seleccionar un tipo de estrés aleatoriamente
    RANDOM_INDEX=$((RANDOM % 4))
    OPTION="${OPTIONS[$RANDOM_INDEX]}"
    
    # Extraer el tipo de estrés (cpu, io, vm, hdd)
    TYPE=$(echo "$OPTION" | awk '{print $1}' | sed 's/--//')

    # Generar un ID aleatorio de 8 caracteres usando /dev/urandom
    RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 8)
    
    # Generar el nombre del contenedor con tipo y ID aleatorio
    CONTAINER_NAME="stress_${TYPE}_${RANDOM_ID}"

    # Ejecutar el contenedor en segundo plano con un timeout de 60 segundos
    docker run -d --name "$CONTAINER_NAME" containerstack/alpine-stress sh -c "stress $OPTION --timeout 60s"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Contenedor $CONTAINER_NAME creado con opción $OPTION${NC}"
    else
        echo -e "${RED}Error al crear $CONTAINER_NAME${NC}"
    fi
done

# 4. Mostrar métricas de uso con docker stats
# echo "Mostrando métricas de uso (presiona Ctrl+C para salir)..."
# docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo -e "${GREEN}=== Despliegue completado ===${NC}"