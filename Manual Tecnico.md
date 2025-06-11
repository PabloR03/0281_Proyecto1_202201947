

---

## COMANDOS PARA EJECUTAR

### 1. **Preparación del Entorno**

#### Crear Módulos

```bash
./install_modules.sh
```

#### Leer Módulos

```bash
./read_modules.sh
```

#### Eliminar Módulos

```bash
./remove_modules.sh
```

---

### 2. **Construcción y Ejecución de la Aplicación**

#### Levantar o Crear Contenedores con Docker Compose

```bash
./deploy_app.sh
```

#### Detener o Eliminar Contenedores de la App

```bash
./shutdown_app.sh
```

#### Detener Servicios Manualmente

```bash
docker-compose down
```

#### Detener y Eliminar Volúmenes

```bash
docker-compose down -v
```

---

### 3. **Simulación de Carga (Stress Testing)**

#### Crear Contenedores para Estresar RAM y CPU (dura 1 min)

```bash
./stress_containers.sh
```

#### Detener/Eliminar Contenedores de Prueba

```bash
./remove_containers.sh
```

---

### 4. **Acceso a la Base de Datos (PostgreSQL)**

#### Conectarte al Contenedor PostgreSQL

```bash
docker exec -it metrics-postgres psql -U metrics_202201947 -d metrics_db
```

#### Ejecutar Consultas:

* Listar Tablas:

```sql
\dt
```

* Ver últimos datos de CPU:

```sql
SELECT * FROM cpu_metrics ORDER BY created_at DESC LIMIT 100;
```

* Ver últimos datos de RAM:

```sql
SELECT * FROM ram_metrics ORDER BY created_at DESC LIMIT 10;
```

