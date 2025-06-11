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

# Verificar Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose no está instalado"
    exit 1
fi

# Verificar docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml en: $PROJECT_DIR"
    exit 1
fi

# Proteger imagen alpine-stress
ALPINE_STRESS_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)

# Limpiar despliegue anterior
if command -v docker-compose &> /dev/null; then
    docker-compose down -v 2>/dev/null || true
else
    docker compose down -v 2>/dev/null || true
fi

# Limpiar imágenes del proyecto anterior
docker rmi proyecto1_fase1-backend proyecto1_fase1-nodejs-api proyecto1_fase1-frontend 2>/dev/null || true
docker image prune -f &> /dev/null

# Verificar conectividad y descargar imágenes
if docker pull hello-world &> /dev/null; then
    docker rmi hello-world &> /dev/null || true
    
    docker pull pablo03r/202201947-sopes1-fase1-backend:latest
    docker pull pablo03r/202201947-sopes1-fase1-api:v1.1
    docker pull pablo03r/202201947-sopes1-fase1-frontend:v1.1
    docker pull postgres:15-alpine
    
    print_success "Imágenes descargadas desde DockerHub"
else
    print_warning "Sin conectividad a DockerHub, verificando imágenes locales..."
    
    MISSING_IMAGES=()
    
    if ! docker inspect pablo03r/202201947-sopes1-fase1-backend:latest &> /dev/null; then
        MISSING_IMAGES+=("pablo03r/202201947-sopes1-fase1-backend:latest")
    fi

    if ! docker inspect pablo03r/202201947-sopes1-fase1-api:v1.1 &> /dev/null; then
        MISSING_IMAGES+=("pablo03r/202201947-sopes1-fase1-api:v1.1")
    fi

    if ! docker inspect pablo03r/202201947-sopes1-fase1-frontend:v1.1 &> /dev/null; then
        MISSING_IMAGES+=("pablo03r/202201947-sopes1-fase1-frontend:v1.1")
    fi

    if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
        print_error "Imágenes faltantes:"
        for img in "${MISSING_IMAGES[@]}"; do
            echo "  $img"
        done
        print_error "Verifica tu conexión a internet"
        exit 1
    fi
fi

# Iniciar contenedores
if command -v docker-compose &> /dev/null; then
    if ! docker-compose up -d; then
        print_error "Error al iniciar contenedores"
        docker-compose logs
        exit 1
    fi
else
    if ! docker compose up -d; then
        print_error "Error al iniciar contenedores"
        docker compose logs
        exit 1
    fi
fi

# Esperar servicios
sleep 20

# Verificar estado
if command -v docker-compose &> /dev/null; then
    CONTAINER_STATUS=$(docker-compose ps)
else
    CONTAINER_STATUS=$(docker compose ps)
fi

if ! echo "$CONTAINER_STATUS" | grep -q "running\|Up"; then
    print_error "Servicios no están corriendo correctamente"
    echo "$CONTAINER_STATUS"
    if command -v docker-compose &> /dev/null; then
        docker-compose logs --tail=50
    else
        docker compose logs --tail=50
    fi
    exit 1
fi

sleep 5

# Test conectividad
if ! curl -s http://localhost:8080/health &> /dev/null; then
    print_warning "Backend no responde en endpoint de salud"
fi

if ! curl -s http://localhost:3000 &> /dev/null; then
    print_warning "Frontend no responde"
fi

# Verificar protección alpine-stress
if [ -n "$ALPINE_STRESS_ID" ]; then
    CURRENT_ALPINE_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
    if [ "$ALPINE_STRESS_ID" != "$CURRENT_ALPINE_ID" ]; then
        print_warning "Imagen alpine-stress pudo haber sido afectada"
    fi
fi

print_success "Despliegue completado"
echo ""
echo "URLs de acceso:"
echo "  Frontend: http://localhost:3000"
echo "  API:      http://localhost:3001"
echo "  Backend:  http://localhost:8080"
echo "  DB:       localhost:5432"