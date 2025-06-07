## COMANDOS PARA EJECUTAR

### BACKEND
Nota: Para cada carpeta tener una terminal.

Compilando el programa de Go
```
go build -o monitor-agent Recolector.go
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
docker exec -it system_metrics_db bash

# Una vez dentro del contenedor, conectarte a PostgreSQL
psql -U admin -d system_metrics

# Ejecutar consultas
\dt  # Listar tablas
SELECT * FROM cpu_metrics;
SELECT * FROM ram_metrics;
```