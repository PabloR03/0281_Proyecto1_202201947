#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cambiar al directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Verificar Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker no está corriendo"
    exit 1
fi

# Verificar docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml en: $PROJECT_DIR"
    exit 1
fi

# Proteger imagen alpine-stress
ALPINE_STRESS_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
if [ -n "$ALPINE_STRESS_ID" ]; then
    docker tag containerstack/alpine-stress:latest alpine-stress-backup:safe 2>/dev/null || true
else
    print_error "CRÍTICO: Imagen alpine-stress no encontrada"
    read -p "¿Continuar sin protección alpine-stress? (y/N): " continue_without
    if [[ ! "$continue_without" =~ ^[Yy]$ ]]; then
        print_error "Operación cancelada"
        exit 1
    fi
fi

# Menú de opciones
echo "Selecciona el tipo de apagado:"
echo "1) Apagado suave (solo detener contenedores)"
echo "2) Apagado completo (detener + limpiar volúmenes)"
echo "3) Apagado con limpieza (+ limpiar imágenes no utilizadas)"
echo "4) Limpieza agresiva (+ eliminar imágenes DockerHub)"
echo "5) Cancelar"
echo ""
read -p "Opción (1-5): " choice

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
        print_warning "Esta opción eliminará imágenes de DockerHub"
        read -p "¿Continuar? (y/N): " confirm_aggressive
        
        if [[ "$confirm_aggressive" =~ ^[Yy]$ ]]; then
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
        else
            print_warning "Limpieza agresiva cancelada"
            exit 0
        fi
        ;;
    5)
        print_warning "Operación cancelada"
        exit 0
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

# Verificar protección de alpine-stress
CURRENT_ALPINE_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
BACKUP_ALPINE_ID=$(docker images -q alpine-stress-backup:safe 2>/dev/null)

if [ -n "$CURRENT_ALPINE_ID" ] && [ "$ALPINE_STRESS_ID" = "$CURRENT_ALPINE_ID" ]; then
    print_success "Imagen alpine-stress protegida exitosamente"
elif [ -n "$BACKUP_ALPINE_ID" ]; then
    print_warning "Restaurando alpine-stress desde respaldo"
    docker tag alpine-stress-backup:safe containerstack/alpine-stress:latest
    print_success "Imagen alpine-stress restaurada"
else
    print_error "CRÍTICO: Imagen alpine-stress perdida - requiere re-descarga"
fi

# Limpiar respaldo si todo está bien
if [ -n "$CURRENT_ALPINE_ID" ] && [ "$ALPINE_STRESS_ID" = "$CURRENT_ALPINE_ID" ]; then
    docker rmi alpine-stress-backup:safe 2>/dev/null || true
fi

print_success "Apagado completado"

# Estado final
if ! docker inspect containerstack/alpine-stress:latest &> /dev/null; then
    print_error "alpine-stress NO disponible (requiere: docker pull containerstack/alpine-stress:latest)"
fi