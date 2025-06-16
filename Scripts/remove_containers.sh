#!/bin/bash

echo "=== Eliminando contenedores de estrés ==="

# Eliminar contenedores de estrés
docker rm -f $(docker ps -aq --filter name=stress_) 2>/dev/null || true

echo "=== Limpieza completada ==="