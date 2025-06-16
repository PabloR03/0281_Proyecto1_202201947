#!/bin/bash

# Cambiar al directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Limpiar despliegue anterior
if command -v docker-compose &> /dev/null; then
    docker-compose down -v 2>/dev/null || true
else
    docker compose down -v 2>/dev/null || true
fi

# Limpiar imágenes del proyecto anterior
docker rmi proyecto1_fase1-backend proyecto1_fase1-nodejs-api proyecto1_fase1-frontend 2>/dev/null || true
docker image prune -f &> /dev/null

# Descargar imágenes
docker pull pablo03r/202201947-sopes1-fase1-backend:latest
docker pull pablo03r/202201947-sopes1-fase1-api:v1.1
docker pull pablo03r/202201947-sopes1-fase1-frontend:v1.1
docker pull postgres:15-alpine

# Iniciar contenedores
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi

# Esperar servicios
sleep 25

echo "Despliegue completado"
echo ""
echo "URLs de acceso:"
echo "  Frontend: http://localhost:3000"
echo "  API:      http://localhost:3001"
echo "  Backend:  http://localhost:8080"
echo "  DB:       localhost:5432"