## COMANDOS PARA EJECUTAR

### BACKEND
Nota: Para cada carpeta tener una terminal.

Compilando el programa de Go
```
go build -o monitor-agent main.go
```

Ejecutando el Programa de Go
```
sudo ./monitor-agent
```

--

dockerfile construir  local
```
docker build -t monitor-agent .
```

dockerfile ejecutar  local
```
docker run -d --name monitor -p 8080:8080 -v /proc:/host/proc:ro monitor-agent
```

Para que otros puedan descargarla
```
docker pull pablo03r/monitor-agent:1.0
```
Ejecutar la imagen descargada
```
docker run -d --name monitor -p 8080:8080 pablo03r/monitor-agent:1.0
```


### Script - Modulos
Crear Modulos
```
./install_modules.sh
```

Eliminar Modulos
```
./remove_modules.sh
```

Leer Modulos
```
./read_modules.sh
```

### Script - Contenedores
Crea contenedores para estresar la memoria RAM y la CPU (Dura 1 min luego se inactiva)
```
./stress_containers.sh
```

Eliminar/Detiene contenedores 
```
./remove_containers.sh
```


### DOCKER

Docker-compose Ejecutar el YML

```
docker-compose up -d
```

Eliminar todo el Docker compose 
```
docker-compose down --rmi all -v
```

Examinar la Base de datos
```
# Conectarte al contenedor
docker exec -it metrics-postgres psql -U metrics_202201947 -d metrics_db

# Ejecutar consultas
\dt  # Listar tablas
# Ver datos de CPU
SELECT * FROM cpu_metrics ORDER BY created_at DESC LIMIT 10;

# Ver datos de RAM
SELECT * FROM ram_metrics ORDER BY created_at DESC LIMIT 10;
# Detener servicios
docker-compose down

# Detener y eliminar volúmenes (¡CUIDADO! Borra todos los datos)
docker-compose down -v
```

DOCKER-COMPOSE 
```
Comando	Descripción
docker-compose up	Inicia los servicios usando las imágenes existentes.
docker-compose up --build	Reconstruye las imágenes antes de iniciar.
docker-compose down	Detiene y elimina los contenedores (pero no las imágenes).
docker-compose down -v	Detiene los contenedores y elimina los volúmenes.
```


Pasos Finales de Ejecucion 

Ejecutar los Scripts
docker start monitor
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
sudo docker-compose up

