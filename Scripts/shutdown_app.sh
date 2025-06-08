#!/bin/bash
# =====================================================
# 🛑 SCRIPT DE APAGADO - MONITOR SYSTEM APP
# =====================================================
echo "============================================"
echo "🛑 Deteniendo Monitor System App"
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

# Verificar si el archivo docker-compose.yml existe
if [ ! -f "docker-compose.yml" ]; then
    print_error "No se encontró docker-compose.yml en el directorio: $PROJECT_DIR"
    exit 1
fi
print_success "Archivo docker-compose.yml encontrado"

# Mostrar contenedores actuales antes de detener
print_status "Estado actual de contenedores:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps 2>/dev/null || echo "No hay contenedores corriendo"
else
    docker compose ps 2>/dev/null || echo "No hay contenedores corriendo"
fi

# Proteger imagen alpine-stress antes de cualquier operación
print_status "Verificando imagen alpine-stress..."
ALPINE_STRESS_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
if [ -n "$ALPINE_STRESS_ID" ]; then
    print_success "Imagen alpine-stress encontrada y será protegida"
else
    print_warning "Imagen alpine-stress no encontrada"
fi

# Preguntar al usuario qué tipo de apagado quiere
echo ""
echo "Selecciona el tipo de apagado:"
echo "1) Apagado suave (detener contenedores solamente)"
echo "2) Apagado completo (detener contenedores y limpiar volúmenes)"
echo "3) Apagado con limpieza (detener, limpiar volúmenes e imágenes no utilizadas)"
echo "4) Cancelar"
echo ""
read -p "Ingresa tu opción (1-4): " choice

case $choice in
    1)
        print_status "Ejecutando apagado suave..."
        if command -v docker-compose &> /dev/null; then
            docker-compose stop
        else
            docker compose stop
        fi
        print_success "Contenedores detenidos"
        ;;
    2)
        print_status "Ejecutando apagado completo..."
        if command -v docker-compose &> /dev/null; then
            docker-compose down -v
        else
            docker compose down -v
        fi
        print_success "Contenedores detenidos y volúmenes eliminados"
        ;;
    3)
        print_status "Ejecutando apagado con limpieza completa..."
        if command -v docker-compose &> /dev/null; then
            docker-compose down -v
        else
            docker compose down -v
        fi
        
        print_status "Limpiando imágenes no utilizadas (protegiendo alpine-stress)..."
        # Limpiar imágenes pero proteger alpine-stress
        docker image prune -f --filter "label!=keep=alpine-stress" &> /dev/null
        
        print_status "Limpiando contenedores detenidos..."
        docker container prune -f &> /dev/null
        
        print_status "Limpiando redes no utilizadas..."
        docker network prune -f &> /dev/null
        
        print_success "Limpieza completa realizada"
        ;;
    4)
        print_warning "Operación cancelada"
        exit 0
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

# Verificar que no hay contenedores de la aplicación corriendo
print_status "Verificando que no hay contenedores corriendo..."
if command -v docker-compose &> /dev/null; then
    RUNNING_CONTAINERS=$(docker-compose ps -q 2>/dev/null)
else
    RUNNING_CONTAINERS=$(docker compose ps -q 2>/dev/null)
fi

if [ -z "$RUNNING_CONTAINERS" ]; then
    print_success "No hay contenedores de la aplicación corriendo"
else
    print_warning "Algunos contenedores aún están corriendo"
fi

# Verificar que alpine-stress sigue disponible
if [ -n "$ALPINE_STRESS_ID" ]; then
    CURRENT_ALPINE_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
    if [ "$ALPINE_STRESS_ID" = "$CURRENT_ALPINE_ID" ]; then
        print_success "✅ Imagen alpine-stress protegida correctamente"
    else
        print_warning "⚠️  La imagen alpine-stress pudo haber sido afectada"
    fi
fi

# Mostrar resumen final
echo ""
echo "============================================"
echo "✅ APAGADO COMPLETADO"
echo "============================================"
echo ""
print_success "Aplicación detenida correctamente"
echo ""
echo "📊 Estado final:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps 2>/dev/null || echo "No hay contenedores de la aplicación"
else
    docker compose ps 2>/dev/null || echo "No hay contenedores de la aplicación"
fi
echo ""
echo "🚀 Para volver a iniciar la aplicación:"
echo "   ./Scripts/deploy_app.sh"
echo ""
echo "📝 Para ver todos los contenedores Docker:"
echo "   docker ps -a"
echo ""
echo "============================================"
print_success "¡Apagado completado! 🛑"