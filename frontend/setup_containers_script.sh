#!/bin/bash

# Crear red personalizada para los contenedores
echo "🌐 Creando red Docker personalizada..."
docker network create app-network

# Construir imagen nodejs-data-fetcher
echo "🔨 Construyendo nodejs-data-fetcher..."
cd nodejs-data-fetcher
docker build -t nodejs-data-fetcher .
cd ..

# Construir imagen express-frontend
echo "🔨 Construyendo express-frontend..."
cd express-frontend
docker build -t express-frontend .
cd ..

# Ejecutar nodejs-data-fetcher
echo "🚀 Ejecutando nodejs-data-fetcher..."
docker run -d \
  --name nodejs-data-fetcher-container \
  --network app-network \
  -p 3001:3001 \
  nodejs-data-fetcher

# Esperar un poco para que el servicio inicie
echo "⏳ Esperando que nodejs-data-fetcher inicie..."
sleep 5

# Ejecutar express-frontend
echo "🚀 Ejecutando express-frontend..."
docker run -d \
  --name express-frontend-container \
  --network app-network \
  -p 3000:3000 \
  -e NODEJS_API_URL=http://nodejs-data-fetcher-container:3001 \
  express-frontend

echo "✅ Contenedores ejecutándose:"
echo "📊 Frontend: http://localhost:3000"
echo "🔧 Backend NodeJS: http://localhost:3001"
echo ""
echo "Para ver logs:"
echo "docker logs nodejs-data-fetcher-container"
echo "docker logs express-frontend-container"
echo ""
echo "Para detener todo:"
echo "docker stop nodejs-data-fetcher-container express-frontend-container"
echo "docker rm nodejs-data-fetcher-container express-frontend-container"
echo "docker network rm app-network"