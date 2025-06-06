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
