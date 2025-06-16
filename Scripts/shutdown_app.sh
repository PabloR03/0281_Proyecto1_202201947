#!/bin/bash

# Cambiar al directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Menú de opciones
echo "Selecciona el tipo de apagado:"
echo "1) Apagado suave (solo detener contenedores)"
echo "2) Apagado completo (detener + limpiar volúmenes)"
echo "3) Apagado con limpieza (+ limpiar imágenes no utilizadas)"
echo "4) Limpieza agresiva (+ eliminar imágenes DockerHub)"
echo ""
read -p "Opción (1-4): " choice

case $choice in
    1)
        if command -v docker-compose &> /dev/null; then
            docker-compose stop
        else
            docker compose stop
        fi
        ;;
    2)
        if command -v docker-compose &> /dev/null; then
            docker-compose down -v
        else
            docker compose down -v
        fi
        ;;
    3)
        if command -v docker-compose &> /dev/null; then
            docker-compose down -v
        else
            docker compose down -v
        fi
        docker image prune -f &> /dev/null
        docker container prune -f &> /dev/null
        docker network prune -f &> /dev/null
        ;;
    4)
        if command -v docker-compose &> /dev/null; then
            docker-compose down -v
        else
            docker compose down -v
        fi
        
        docker rmi pablo03r/202201947-sopes1-fase1-backend:latest 2>/dev/null || true
        docker rmi pablo03r/202201947-sopes1-fase1-api:v1.1 2>/dev/null || true
        docker rmi pablo03r/202201947-sopes1-fase1-frontend:v1.1 2>/dev/null || true
        
        docker image prune -f &> /dev/null
        docker container prune -f &> /dev/null
        docker network prune -f &> /dev/null
        ;;
    *)
        echo "Opción inválida"
        exit 1
        ;;
esac

echo "Apagado completado"