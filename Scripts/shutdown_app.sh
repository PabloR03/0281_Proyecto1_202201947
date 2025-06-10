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
print_status "Estado actual de contenedores del proyecto:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps 2>/dev/null || echo "No hay contenedores del proyecto corriendo"
else
    docker compose ps 2>/dev/null || echo "No hay contenedores del proyecto corriendo"
fi

# PROTECCIÓN CRÍTICA: Verificar y proteger imagen alpine-stress
print_status "🛡️  VERIFICANDO Y PROTEGIENDO IMAGEN ALPINE-STRESS (CRÍTICA)..."
ALPINE_STRESS_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
if [ -n "$ALPINE_STRESS_ID" ]; then
    print_success "✅ Imagen alpine-stress encontrada (ID: ${ALPINE_STRESS_ID:0:12})"
    print_success "🛡️  Imagen alpine-stress PROTEGIDA - NO será eliminada"
    
    # Crear tag adicional de respaldo por seguridad
    docker tag containerstack/alpine-stress:latest alpine-stress-backup:safe 2>/dev/null || true
    print_success "🔒 Tag de respaldo creado: alpine-stress-backup:safe"
else
    print_error "❌ IMAGEN ALPINE-STRESS NO ENCONTRADA - ESTO ES CRÍTICO"
    print_error "La imagen alpine-stress es vital para tu proyecto"
    read -p "¿Deseas continuar sin la protección de alpine-stress? (y/N): " continue_without
    if [[ ! "$continue_without" =~ ^[Yy]$ ]]; then
        print_error "Operación cancelada por seguridad"
        exit 1
    fi
fi

# Preguntar al usuario qué tipo de apagado quiere
echo ""
echo "Selecciona el tipo de apagado:"
echo "1) 🔄 Apagado suave (detener contenedores solamente)"
echo "2) 🧹 Apagado completo (detener contenedores y limpiar volúmenes)"
echo "3) 🗑️  Apagado con limpieza (detener, limpiar volúmenes e imágenes no utilizadas)"
echo "4) 🚨 Limpieza agresiva (eliminar también imágenes del proyecto de DockerHub)"
echo "5) ❌ Cancelar"
echo ""
echo "⚠️  NOTA: alpine-stress SIEMPRE será protegida en todas las opciones"
echo ""
read -p "Ingresa tu opción (1-5): " choice

case $choice in
    1)
        print_status "Ejecutando apagado suave..."
        if command -v docker-compose &> /dev/null; then
            docker-compose stop
        else
            docker compose stop
        fi
        print_success "Contenedores detenidos (volúmenes preservados)"
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
        
        print_status "🧹 Limpiando imágenes no utilizadas (PROTEGIENDO alpine-stress)..."
        # Limpiar imágenes pero proteger alpine-stress y sus variantes
        docker image prune -f &> /dev/null
        
        print_status "🧹 Limpiando contenedores detenidos..."
        docker container prune -f &> /dev/null
        
        print_status "🧹 Limpiando redes no utilizadas..."
        docker network prune -f &> /dev/null
        
        print_success "Limpieza completa realizada (alpine-stress protegida)"
        ;;
    4)
        print_status "Ejecutando limpieza agresiva..."
        print_warning "⚠️  Esta opción eliminará las imágenes de DockerHub descargadas"
        read -p "¿Estás seguro? Tendrás que descargarlas nuevamente (y/N): " confirm_aggressive
        
        if [[ "$confirm_aggressive" =~ ^[Yy]$ ]]; then
            if command -v docker-compose &> /dev/null; then
                docker-compose down -v
            else
                docker compose down -v
            fi
            
            print_status "🗑️  Eliminando imágenes del proyecto de DockerHub..."
            # Eliminar específicamente las imágenes del proyecto
            docker rmi pablo03r/202201947-sopes1-fase1-backend:latest 2>/dev/null || true
            docker rmi pablo03r/202201947-sopes1-fase1-api:latest 2>/dev/null || true
            docker rmi pablo03r/202201947-sopes1-fase1-frontend:latest 2>/dev/null || true
            
            print_status "🧹 Limpieza completa del sistema..."
            docker image prune -f &> /dev/null
            docker container prune -f &> /dev/null
            docker network prune -f &> /dev/null
            
            print_success "Limpieza agresiva completada (alpine-stress protegida)"
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

# Verificar que no hay contenedores de la aplicación corriendo
print_status "Verificando que no hay contenedores del proyecto corriendo..."
if command -v docker-compose &> /dev/null; then
    RUNNING_CONTAINERS=$(docker-compose ps -q 2>/dev/null)
else
    RUNNING_CONTAINERS=$(docker compose ps -q 2>/dev/null)
fi

if [ -z "$RUNNING_CONTAINERS" ]; then
    print_success "✅ No hay contenedores del proyecto corriendo"
else
    print_warning "⚠️  Algunos contenedores del proyecto aún están corriendo"
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi
fi

# VERIFICACIÓN CRÍTICA: Confirmar que alpine-stress sigue disponible
print_status "🔍 VERIFICACIÓN CRÍTICA: Confirmando protección de alpine-stress..."
CURRENT_ALPINE_ID=$(docker images -q containerstack/alpine-stress:latest 2>/dev/null)
BACKUP_ALPINE_ID=$(docker images -q alpine-stress-backup:safe 2>/dev/null)

if [ -n "$CURRENT_ALPINE_ID" ] && [ "$ALPINE_STRESS_ID" = "$CURRENT_ALPINE_ID" ]; then
    print_success "✅ IMAGEN ALPINE-STRESS PROTEGIDA EXITOSAMENTE"
    print_success "🛡️  ID original: ${ALPINE_STRESS_ID:0:12}"
    print_success "🛡️  ID actual:   ${CURRENT_ALPINE_ID:0:12}"
elif [ -n "$BACKUP_ALPINE_ID" ]; then
    print_warning "⚠️  Imagen principal afectada, pero respaldo disponible"
    print_status "🔄 Restaurando desde respaldo..."
    docker tag alpine-stress-backup:safe containerstack/alpine-stress:latest
    print_success "✅ Imagen alpine-stress restaurada desde respaldo"
else
    print_error "❌ CRÍTICO: IMAGEN ALPINE-STRESS PERDIDA"
    print_error "Necesitarás volver a descargar: docker pull containerstack/alpine-stress:latest"
fi

# Limpiar tag de respaldo si todo está bien
if [ -n "$CURRENT_ALPINE_ID" ] && [ "$ALPINE_STRESS_ID" = "$CURRENT_ALPINE_ID" ]; then
    docker rmi alpine-stress-backup:safe 2>/dev/null || true
fi

# Mostrar resumen final
echo ""
echo "============================================"
echo "✅ APAGADO COMPLETADO EXITOSAMENTE"
echo "============================================"
echo ""
print_success "Monitor System App detenida correctamente"
echo ""
echo "📊 Estado final del proyecto:"
if command -v docker-compose &> /dev/null; then
    docker-compose ps 2>/dev/null || echo "   No hay contenedores del proyecto activos"
else
    docker compose ps 2>/dev/null || echo "   No hay contenedores del proyecto activos"
fi
echo ""
echo "🛡️  Estado de imagen crítica:"
if docker inspect containerstack/alpine-stress:latest &> /dev/null; then
    echo "   ✅ alpine-stress: PROTEGIDA y disponible"
else
    echo "   ❌ alpine-stress: NO disponible (requiere re-descarga)"
fi
echo ""
echo "🚀 Para volver a iniciar la aplicación:"
echo "   ./Scripts/deploy_app.sh"
echo ""
echo "📝 Comandos útiles:"
echo "   Ver contenedores:     docker ps -a"
echo "   Ver imágenes:         docker images"
echo "   Verificar alpine:     docker images containerstack/alpine-stress"
echo ""
echo "============================================"
print_success "¡Apagado completado con protección alpine-stress! 🛑🛡️"