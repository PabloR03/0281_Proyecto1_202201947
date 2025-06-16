#!/bin/bash

# Definir las opciones de consumo (usando stress)
OPTIONS=(
    "--cpu 1"                     # CPU
    "--io 1"                      # I/O
    "--vm 1 --vm-bytes 256M"      # RAM
    "--hdd 1"                     # Disco
)

echo "=== Script para desplegar 10 contenedores de estrés ==="

# Crear 10 contenedores con nombres únicos
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
    echo "Contenedor $CONTAINER_NAME creado con opción $OPTION"
done

echo "=== Despliegue completado ==="