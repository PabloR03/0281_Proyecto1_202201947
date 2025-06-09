#!/bin/bash

echo "🧹 Limpiando contenedores..."

# Detener contenedores
docker stop nodejs-data-fetcher-container express-frontend-container 2>/dev/null

# Eliminar contenedores
docker rm nodejs-data-fetcher-container express-frontend-container 2>/dev/null

# Eliminar red
docker network rm app-network 2>/dev/null

# Eliminar imágenes (opcional, comentar si quieres conservarlas)
# docker rmi nodejs-data-fetcher express-frontend 2>/dev/null

echo "✅ Limpieza completada"