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

# Limpiar imágenes del proyecto anterior (pero proteger alpine-stress)
print_status "Limpiando imágenes locales del proyecto anterior..."
# Eliminar imágenes locales del proyecto que ya no necesitamos
docker rmi proyecto1_fase1-backend proyecto1_fase1-nodejs-api proyecto1_fase1-frontend 2>/dev/null || true

# Limpiar imágenes no utilizadas (pero proteger alpine-stress)
print_status "Limpiando imágenes no utilizadas (protegiendo alpine-stress)..."
docker image prune -f &> /dev/null

# Verificar conectividad a Docker Hub
print_status "Verificando conectividad a Docker Hub..."
if docker pull hello-world &> /dev/null; then
    print_success "Conectividad a Docker Hub OK"
    docker rmi hello-world &> /dev/null || true
    
    # Descargar/actualizar las imágenes desde Docker Hub
    print_status "Descargando últimas imágenes desde Docker Hub..."
    print_status "  📦 Descargando pablo03r/202201947-sopes1-fase1-backend:latest..."
    docker pull pablo03r/202201947-sopes1-fase1-backend:latest
    
    print_status "  📦 Descargando pablo03r/202201947-sopes1-fase1-api:latest..."
    docker pull pablo03r/202201947-sopes1-fase1-api:latest
    
    print_status "  📦 Descargando pablo03r/202201947-sopes1-fase1-frontend:latest..."
    docker pull pablo03r/202201947-sopes1-fase1-frontend:latest
    
    print_status "  📦 Descargando postgres:15-alpine..."
    docker pull postgres:15-alpine
    
    print_success "Todas las imágenes descargadas correctamente"
else
    print_warning "Problemas de conectividad con Docker Hub"
    print_warning "Verificando si las imágenes están disponibles localmente..."
    
    # Verificar si las imágenes están disponibles localmente
    MISSING_IMAGES=()
    
    if ! docker inspect pablo03r/202201947-sopes1-fase1-backend:latest &> /dev/null; then
        MISSING_IMAGES+=("pablo03r/202201947-sopes1-fase1-backend:latest")
    fi
    
    if ! docker inspect pablo03r/202201947-sopes1-fase1-api:latest &> /dev/null; then
        MISSING_IMAGES+=("pablo03r/202201947-sopes1-fase1-api:latest")
    fi
    
    if ! docker inspect pablo03r/202201947-sopes1-fase1-frontend:latest &> /dev/null; then
        MISSING_IMAGES+=("pablo03r/202201947-sopes1-fase1-frontend:latest")
    fi
    
    if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
        print_error "Las siguientes imágenes no están disponibles localmente:"
        for img in "${MISSING_IMAGES[@]}"; do
            echo "  ❌ $img"
        done
        print_error "Por favor, verifica tu conexión a internet e intenta nuevamente"
        exit 1
    else
        print_success "Todas las imágenes están disponibles localmente"
    fi
fi

# Crear y ejecutar contenedores
print_status "Creando y ejecutando contenedores..."
if command -v docker-compose &> /dev/null; then
    if docker-compose up -d; then
        print_success "Contenedores iniciados correctamente"
    else
        print_error "Error al iniciar contenedores"
        # Mostrar logs para diagnóstico
        print_status "Mostrando logs para diagnóstico..."
        docker-compose logs
        exit 1
    fi
else
    if docker compose up -d; then
        print_success "Contenedores iniciados correctamente"
    else
        print_error "Error al iniciar contenedores"
        # Mostrar logs para diagnóstico
        print_status "Mostrando logs para diagnóstico..."
        docker compose logs
        exit 1
    fi
fi

# Esperar a que los servicios estén listos
print_status "Esperando a que los servicios estén listos..."
sleep 20

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
    print_error "Algunos servicios no están corriendo correctamente"
    echo "$CONTAINER_STATUS"
    print_status "Mostrando logs para diagnóstico..."
    if command -v docker-compose &> /dev/null; then
        docker-compose logs --tail=50
    else
        docker compose logs --tail=50
    fi
    exit 1
fi

# Verificar conectividad de servicios
print_status "Verificando conectividad de servicios..."
sleep 5

# Test de conectividad al backend
if curl -s http://localhost:8080/health &> /dev/null; then
    print_success "✅ Backend responde correctamente"
else
    print_warning "⚠️  Backend no responde en el endpoint de salud"
fi

# Test de conectividad al frontend
if curl -s http://localhost:3000 &> /dev/null; then
    print_success "✅ Frontend responde correctamente"
else
    print_warning "⚠️  Frontend no responde"
fi

# Mostrar información del despliegue
echo ""
echo "============================================"
echo "✅ DESPLIEGUE COMPLETADO EXITOSAMENTE"
echo "============================================"
echo ""
print_success "Aplicación desplegada correctamente usando imágenes de DockerHub"
echo ""
echo "🌐 URLs de acceso:"
echo "   - Frontend (Web): http://localhost:3000"
echo "   - API Node.js:    http://localhost:3001"
echo "   - Backend (Go):   http://localhost:8080"
echo "   - Base de Datos:  localhost:5432"
echo ""
echo "🐳 Imágenes utilizadas:"
echo "   - Backend:  pablo03r/202201947-sopes1-fase1-backend:latest"
echo "   - API:      pablo03r/202201947-sopes1-fase1-api:latest"
echo "   - Frontend: pablo03r/202201947-sopes1-fase1-frontend:latest"
echo "   - DB:       postgres:15-alpine"
echo ""
echo "📊 Estado de contenedores:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps
else
    docker compose ps
fi
echo ""
echo "📝 Comandos útiles:"
echo "   Ver logs:           docker-compose logs -f"
echo "   Reiniciar:          docker-compose restart"
echo "   Detener:            docker-compose down"
echo "   Detener y limpiar:  docker-compose down -v"
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

print_success "¡Despliegue completado usando DockerHub! 🚀"