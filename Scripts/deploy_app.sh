#!/bin/bash
# =====================================================
# 🚀 SCRIPT DE DESPLIEGUE - MONITOR SYSTEM APP
# =====================================================
echo "============================================"
echo "🚀 Iniciando despliegue de Monitor System"
echo "============================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes con colores
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Guardar directorio actual y cambiar al directorio padre donde está docker-compose.yml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
print_status "Cambiando al directorio del proyecto: $PROJECT_DIR"
cd "$PROJECT_DIR"

# Verificar si Docker está instalado y corriendo
print_status "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_error "Docker no está instalado"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker no está corriendo"
    exit 1
fi
print_success "Docker está funcionando correctamente"

# Verificar si docker-compose está disponible
print_status "Verificando Docker Compose..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose no está instalado"
    exit 1
fi
print_success "Docker Compose está disponible"

# Verificar si el archivo docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml en el directorio: $PROJECT_DIR"
    exit 1
fi
print_success "Archivo docker-compose.yml encontrado"

# Proteger imagen alpine-stress antes de limpiar
print_status "Protegiendo imagen alpine-stress..."
ALPINE_STRESS_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
if [ -n "$ALPINE_STRESS_ID" ]; then
    print_success "Imagen alpine-stress encontrada y será protegida"
else
    print_warning "Imagen alpine-stress no encontrada"
fi

# Limpiar contenedores anteriores si existen
print_status "Limpiando despliegue anterior..."
if command -v docker-compose &> /dev/null; then
    docker-compose down -v 2>/dev/null || true
else
    docker compose down -v 2>/dev/null || true
fi

# Limpiar imágenes no utilizadas (pero proteger alpine-stress)
print_status "Limpiando imágenes no utilizadas (protegiendo alpine-stress)..."
# Usar filtro para excluir alpine-stress del prune
docker image prune -f --filter "label!=keep=alpine-stress" &> /dev/null

# Verificar conectividad a Docker Hub
print_status "Verificando conectividad a Docker Hub..."
if docker pull hello-world &> /dev/null; then
    print_success "Conectividad a Docker Hub OK"
    docker rmi hello-world &> /dev/null || true
    
    # Descargar las últimas imágenes
    print_status "Descargando últimas imágenes desde Docker Hub..."
    if command -v docker-compose &> /dev/null; then
        docker-compose pull
    else
        docker compose pull
    fi
else
    print_warning "Problemas de conectividad con Docker Hub, usando imágenes locales"
fi

# Crear y ejecutar contenedores
print_status "Creando y ejecutar contenedores..."
if command -v docker-compose &> /dev/null; then
    if docker-compose up -d; then
        print_success "Contenedores iniciados correctamente"
    else
        print_error "Error al iniciar contenedores"
        exit 1
    fi
else
    if docker compose up -d; then
        print_success "Contenedores iniciados correctamente"
    else
        print_error "Error al iniciar contenedores"
        exit 1
    fi
fi

# Esperar a que los servicios estén listos
print_status "Esperando a que los servicios estén listos..."
sleep 15

# Verificar estado de los contenedores
print_status "Verificando estado de los contenedores..."
if command -v docker-compose &> /dev/null; then
    CONTAINER_STATUS=$(docker-compose ps)
else
    CONTAINER_STATUS=$(docker compose ps)
fi

if echo "$CONTAINER_STATUS" | grep -q "running\|Up"; then
    print_success "Servicios están corriendo"
else
    print_error "Algunos servicios no están corriendo"
    echo "$CONTAINER_STATUS"
    exit 1
fi

# Mostrar información del despliegue
echo ""
echo "============================================"
echo "✅ DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo "============================================"
echo ""
print_success "Aplicación desplegada correctamente"
echo ""
echo "🌐 URLs de acceso:"
echo "   - Frontend (Web): http://localhost:3000"
echo "   - Backend (API):  http://localhost:8080"
echo "   - Base de Datos:  localhost:5432"
echo ""
echo "📊 Estado de contenedores:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps
else
    docker compose ps
fi
echo ""
echo "📝 Para ver logs en tiempo real:"
echo "   docker-compose logs -f  (o docker compose logs -f)"
echo ""
echo "🛑 Para detener la aplicación:"
echo "   ./Scripts/shutdown_app.sh"
echo ""
echo "============================================"

# Verificar que alpine-stress sigue disponible
if [ -n "$ALPINE_STRESS_ID" ]; then
    CURRENT_ALPINE_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
    if [ "$ALPINE_STRESS_ID" = "$CURRENT_ALPINE_ID" ]; then
        print_success "✅ Imagen alpine-stress protegida correctamente"
    else
        print_warning "⚠️  La imagen alpine-stress pudo haber sido afectada"
    fi
fi

print_success "¡Despliegue completado! 🚀"