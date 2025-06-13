
### ./Modulos/cpu_202201947.c
El programa es un módulo de kernel para Linux diseñado para realizar monitoreo del uso de CPU. Este módulo se integra con el sistema de archivos /proc creando un archivo especial que permite consultar el porcentaje de uso actual de la CPU en formato JSON.

#### Cálculo del uso de CPU (get_cpu_usage):
- Extrae estadísticas de uso de CPU desde la estructura kcpustat_cpu(0) que proporciona datos como tiempo de usuario, sistema, idle (inactivo), etc.
- Calcula la diferencia entre el total de ciclos activos e inactivos desde la última vez que se leyó esta información, para determinar el porcentaje real de uso de la CPU.
- Devuelve este valor en porcentaje (0-100).

### ./Modulos/ram_202201947.c
El programa es un módulo de kernel para Linux diseñado para obtener información detallada del estado de la memoria RAM del sistema. Este módulo crea un archivo virtual en el sistema de archivos /proc, que permite consultar la memoria total, libre, usada y su porcentaje de uso en formato JSON.

#### Cálculo del uso de RAM (raminfo_show):
- Obtiene las estadísticas de memoria usando la función si_meminfo(&si), que devuelve datos como memoria total, libre, usada, buffers y caché.
- Convierte estos valores de bytes a megabytes (MB) para una mejor legibilidad.
- Calcula la memoria utilizada como:
- RAM usada = total - libre - buffers - caché.
- Calcula el porcentaje de uso de RAM basándose en el total disponible.

### ./BackEnd/main.go
Este archivo implementa un servidor HTTP en Go que actúa como un agente de monitoreo para exponer los datos obtenidos desde los módulos de kernel de CPU y RAM (ubicados en /proc/cpu_202201947 y /proc/ram_202201947 respectivamente). Permite consultar esta información de manera remota a través de una API REST sencilla.

#### Lectura de archivos de /proc (readProcFile):
- Lee el contenido de los archivos de los módulos de kernel (/proc/cpu_202201947 y /proc/ram_202201947).
- Devuelve el contenido como una cadena de texto o un mensaje de error si ocurre algún problema.

#### Monitoreo de CPU y RAM (monitorCPU, monitorRAM):
- Son goroutines que cada 5 segundos leen los respectivos archivos de /proc para mantener actualizada la información de CPU y RAM.
- Utilizan un mutex (sync.Mutex) para evitar condiciones de carrera al acceder a las variables cpuData y ramData.
- Los datos leídos se almacenan en variables globales que luego son servidas por las rutas HTTP.

#### Servidor HTTP principal (main):
- Verifica que los archivos /proc/cpu_202201947 y /proc/ram_202201947 existen; si no están presentes, finaliza el programa con un mensaje de error.
- Lanza las goroutines monitorCPU() y monitorRAM() para actualización periódica de datos.
- Define tres endpoints:
    /cpu: Devuelve el último estado de uso de CPU en formato JSON.
    /ram: Devuelve el último estado de uso de RAM en formato JSON.
    /health: Endpoint de prueba que siempre responde con "OK" para verificar que el servidor esté funcionando.
- Inicia un servidor HTTP en el puerto 8080.

### ./BackEnd/Dockerfile

El archivo Dockerfile define cómo construir una imagen Docker para contener y ejecutar el servidor HTTP (monitor-agent) desarrollado en Go, que sirve los datos del uso de CPU y RAM obtenidos desde los módulos del kernel.

#### Fases de construcción:

##### Fase 1: Builder

   * Imagen base: golang:1.21-alpine (ligera y optimizada para compilación en Go).
   * Directorio de trabajo: /app.
   * Copia el archivo fuente main.go al contenedor.
   * Ejecuta:

     * go mod init monitor-agent: Inicializa un nuevo módulo Go.
     * go mod tidy: Descarga dependencias necesarias.
     * Compila la aplicación para Linux (sin dependencias C, con CGO_ENABLED=0) y genera el ejecutable monitor-agent.

##### Fase 2: Runtime

   * Imagen base: alpine:latest (liviana, ideal para producción).
   * Instala certificados (ca-certificates) para permitir conexiones HTTPS (por si son necesarias).
   * Crea el directorio /proc (necesario porque este contenedor leerá los archivos /proc/cpu_202201947 y /proc/ram_202201947 montados desde el host).
   * Copia el ejecutable monitor-agent desde la fase de construcción.
   * Expone el puerto 8080 para acceso HTTP.
   * Define el comando de inicio: CMD ["/monitor-agent"].

### ./frontend/node-data-fetcher/index.js

Este archivo implementa un servicio intermediario NodeJS cuya función principal es:

1. Consultar el backend escrito en Go (expuesto en /cpu, /ram, /health).
2. Procesar los datos de CPU y RAM obtenidos.
3. Guardar estos datos en memoria y también en una base de datos PostgreSQL.
4. Proveer una API REST para que el frontend (o cualquier cliente) pueda consumir las métricas procesadas.
5. Manejar errores de forma robusta (tanto de red como de base de datos).
6. Actualizar las métricas de manera periódica según el intervalo configurado.

#### Principales componentes:

* Dependencias:

  * express: Servidor HTTP.
  * axios: Realizar peticiones HTTP al backend Go.
  * cors: Soporte CORS.
  * ./config: Configuración centralizada.
  * ./database: Módulo de acceso a base de datos PostgreSQL.

* Estructura de Datos:
  metricsData mantiene las últimas 100 mediciones de CPU y RAM.

* Funciones principales:

  * fetchBackendData(endpoint): Llama al backend Go para obtener datos.
  * updateCPUData(): Obtiene, procesa y almacena datos de CPU.
  * updateRAMData(): Igual para RAM.
  * updateMetrics(): Ejecuta ambas actualizaciones.
  * startService(): Arranca el servicio NodeJS con verificación previa de BD y Backend Go.
centralizado
* Endpoints expuestos:

  * /api/metrics: Devuelve todas las métricas CPU y RAM en memoria.
  * /api/metrics/cpu: Solo métricas CPU.
  * /api/metrics/ram: Solo métricas RAM.
  * /api/metrics/latest: Última muestra de CPU y RAM.
  * /api/database/stats: Información de estado de la base de datos.
  * /api/health: Estado de salud del servicio NodeJS.

* Manejo de Errores:

  * Captura de excepciones no manejadas.
  * Control de promesas rechazadas.
  * Cierre limpio de conexiones PostgreSQL al recibir señales SIGINT y SIGTERM.

### init.sql

Script SQL de inicialización de la base de datos PostgreSQL.

#### Crea dos tablas principales:

1. cpu\metrics:

   * id: PK autoincremental.
   * timestamp: Marca de tiempo de la medición.
   * porcentaje_uso: Uso de CPU (%) capturado.
   * created_at: Fecha de inserción en BD.

2. ram\metrics:

   * id: PK autoincremental.
   * timestamp: Marca de tiempo de la medición.
   * total_mb, libre_mb, uso_mb: Datos de memoria en MB.
   * porcentaje_uso: Uso de RAM (%).
   * created_at: Fecha de inserción en BD.

#### Indices:

* Sobre timestamp y created_at para mejorar consultas cronológicas o por fecha.

### ./config.js

Módulo centralizado de configuración que obtiene variables desde .env o define valores por defecto.

#### Parámetros:

* backendUrl: URL base del backend Go (por defecto: http://localhost:8080).
* port: Puerto donde corre este microservicio NodeJS (3001 por defecto).
* updateInterval: Intervalo de actualización de datos en milisegundos (5000 por defecto).
* endpoints: Rutas para /cpu, /ram, /health del backend.
* frontendPort: Puerto del Frontend React/Express (3000 por defecto).



### Dockerfile (NodeJS Data Fetcher)

Este Dockerfile construye una imagen optimizada para producción del servicio Node.js que obtiene y procesa datos desde el backend Go.


#### Explicación paso a paso:

1. Imagen base:

   ```Dockerfile
   FROM node:18-alpine
   ```

   Se usa una imagen oficial ligera de Node.js (versión 18 con Alpine Linux).

2. Instalación de dependencias adicionales:

   ```Dockerfile
   RUN apk add --no-cache curl
   ```

   `curl` se instala para habilitar el `HEALTHCHECK`.

3. Directorio de trabajo:

   ```Dockerfile
   WORKDIR /app
   ```

4. Copiar archivos de dependencias:

   ```Dockerfile
   COPY package*.json ./
   ```

5. Instalación de dependencias de producción:

   ```Dockerfile
   RUN npm ci --only=production && npm cache clean --force
   ```

   * `npm ci`: Instalación limpia.
   * Solo módulos de producción.
   * Limpieza de caché.

6. Copiar el resto del código:

   ```Dockerfile
   COPY . .
   ```

7. Creación de usuario sin privilegios:

   ```Dockerfile
   RUN addgroup -g 1001 -S nodejs && \
       adduser -S nodeapi -u 1001 -G nodejs
   ```

   Buenas prácticas de seguridad: no se ejecuta como `root`.

8. Asignación de permisos:

   ```Dockerfile
   RUN chown -R nodeapi:nodejs /app
   USER nodeapi
   ```

9. Exposición de puerto:

   ```Dockerfile
   EXPOSE 3001
   ```

10. Variables de entorno:

    ```Dockerfile
    ENV NODE_ENV=production
    ENV NODEJS_PORT=3001
    ENV BACKEND_URL=http://host.docker.internal:8080
    ```

11. Healthcheck incorporado:

    ```Dockerfile
    HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
        CMD curl -f http://localhost:3001/health || exit 1
    ```

    Verifica salud interna cada 30 segundos.

12. Comando de inicio:

    ```Dockerfile
    CMD ["node", "index.js"]
    ```


### ./frontend/express-frontend/server.js

####  Propósito general:

Este archivo define un servidor Express que actúa como frontend (dashboard) para visualizar las métricas de CPU y RAM recolectadas por el microservicio NodeJS (node-data-fetcher). Además, sirve los archivos estáticos del dashboard (HTML, JS, CSS) desde la carpeta public.


####  Funcionalidades principales:

1. Configuración de puertos y URLs:

   * El servidor escucha en el puerto 3000 (o el definido en la variable de entorno PORT).
   * Detecta si está corriendo en producción o local para decidir a qué URL del backend NodeJS (data-fetcher) debe hacer solicitudes:

     * Local: http://localhost:3001
     * Producción (Docker): http://host.docker.internal:3001
   * También permite configurar explícitamente esta URL usando la variable NODEJS_API_URL.

2. Middleware incluido:

   * Permite solicitudes Cross-Origin (CORS).
   * Acepta JSON en el cuerpo de las peticiones.
   * Sirve archivos estáticos desde la carpeta /public (donde está el frontend visual, como index.html).

3. Endpoints creados:

   * /api/data/metrics: Obtiene todas las métricas de CPU y RAM desde el microservicio NodeJS.
   * /api/data/metrics/latest: Obtiene la métrica más reciente de CPU y RAM.
   * /api/data/metrics/cpu: Obtiene todas las métricas históricas de CPU.
   * /api/data/metrics/ram: Obtiene todas las métricas históricas de RAM.
   * /: Devuelve el archivo index.html para visualizar el dashboard.
   * /health: Proporciona información de estado del servidor Express (usado para healthchecks de Docker).

4. Manejo de errores:

   * Cada solicitud a la API NodeJS está protegida con manejo de errores: si el microservicio NodeJS no responde, el usuario ve un mensaje de error claro.
   * También se manejan excepciones globales con los eventos de proceso (uncaughtException, unhandledRejection) para evitar caídas inesperadas.

5. Inicio del servidor:

   * Al arrancar, el servidor imprime en consola:

     * El puerto en el que está corriendo.
     * La URL del dashboard accesible.
     * La URL del backend NodeJS con la que intentará comunicarse.

### Dockerfile (Express Frontend)
Construir y ejecutar una imagen Docker ligera para el servidor Express que sirve el dashboard frontend de métricas.

Detalles de la construcción:
- Imagen base:

    node:18-alpine: Imagen oficial de Node.js, minimalista y optimizada.

- Directorio de trabajo:

    /app: Todo el contenido de la app vivirá aquí.

- Dependencias:

    Copia sólo los archivos package*.json.
    Ejecuta npm ci --only=production para instalar dependencias de producción de manera limpia.
    Limpia la caché de npm para reducir el tamaño final.

- Código fuente:

    Copia los archivos de servidor (server.js) y la carpeta de archivos estáticos (public/).
    Creación de usuario seguro:
    Se crea un grupo y un usuario llamado express con UID y GID 1001 para evitar correr la app como root.
    Se asigna propiedad de los archivos a este usuario.

- Configuración de entorno:

    Expone el puerto 3000.

- Define variables de entorno clave:

    NODE_ENV=production
    PORT=3000
    NODEJS_API_URL=http://host.docker.internal:3001 (para comunicar con el microservicio NodeJS en Docker).

- Healthcheck integrado:

    Verifica la salud del contenedor ejecutando el script healthcheck.js (este archivo debe existir y devolver código 0 si todo está bien).

- Comando de inicio:

    Inicia el servidor con: node server.js.


### Descripción del archivo docker-compose.yml

Versión de docker-compose utilizada: 3.8

#### Servicios definidos:

- postgres
    Servicio para base de datos PostgreSQL versión 15-alpine.
    Contenedor llamado metrics-postgres.
    Variables de entorno definidas para la configuración de la base de datos:
    POSTGRES\_DB: metrics\_db
    POSTGRES\_USER: metrics\_202201947
    POSTGRES\_PASSWORD: metrics\_202201947
    POSTGRES\_INITDB\_ARGS para definir codificación y configuración regional.
    El puerto 5432 del contenedor expuesto al mismo puerto en la máquina host.
    Montaje de volumen persistente postgres\_data para datos de la base.
    Montaje del script init.sql desde el frontend para la inicialización de la base.
    Política de reinicio unless-stopped para reinicio automático.
    Healthcheck configurado con pg\_isready para validar disponibilidad de PostgreSQL.
    Conectado a la red app-network.

- backend
    Servicio para el backend desarrollado en Go.
    Imagen: pablo03r/202201947-sopes1-fase1-backend\:latest.
    Contenedor llamado monitor-agent-backend.
    Puerto 8080 expuesto al host.
    Reinicia automáticamente unless-stopped.
    Depende del servicio postgres y espera a que este esté saludable.
    Healthcheck que realiza una petición HTTP GET al endpoint /health.
    Conectado a la red app-network.

- nodejs-api
    Servicio API Node.js para recolección de datos.
    Imagen: pablo03r/202201947-sopes1-fase1-api\:v1.1.
    Contenedor llamado nodejs-data-fetcher.
    Puerto 3001 expuesto al host.
    Variables de entorno para configuración de entorno y conexión a la base de datos:
    NODE\_ENV: production
    NODEJS\_PORT: 3001
    BACKEND\_URL: [http://backend:8080](http://backend:8080)
    DB\_HOST: postgres
    DB\_PORT: 5432
    DB\_NAME: metrics\_db
    DB\_USER: metrics\_202201947
    DB\_PASSWORD: metrics\_202201947
    Reinicio automático unless-stopped.
    Depende de los servicios backend y postgres.
    Conectado a la red app-network.

- frontend
    Servicio para el frontend Express.
    Imagen: pablo03r/202201947-sopes1-fase1-frontend\:v1.1.
    Contenedor llamado express-frontend.
    Puerto 3000 expuesto al host.
    Variables de entorno definidas:
    NODE\_ENV: production
    PORT: 3000
    NODEJS\_API\_URL: [http://nodejs-api:3001](http://nodejs-api:3001)
    Reinicio automático unless-stopped.
    Depende del servicio nodejs-api.
    Conectado a la red app-network.

- Volúmenes
    postgres\_data: volumen persistente para datos de PostgreSQL.

- Redes
    app-network: red bridge definida para la comunicación entre servicios.




---

## COMANDOS PARA EJECUTAR

### 1. Preparación del Entorno

#### Crear Módulos
Compila, carga y verifica dos módulos del kernel (cpu_202201947 y ram_202201947).

Funciones principales:

Definir rutas y nombres de módulos:
Usa variables para ubicar los módulos (MODULES_DIR) y sus nombres (CPU_MODULE, RAM_MODULE).

Colores para mensajes:
Define códigos ANSI para mensajes de error y éxito.

Función check_error:
Verifica si el comando anterior falló; si es así, muestra un error y termina el script.

Cambiar al directorio de módulos:
Se mueve a MODULES_DIR o termina si falla.

Compilar módulos:
Ejecuta make clean && make; si falla, finaliza con error.

Cargar módulos al kernel:
Usa insmod para insertar ambos .ko; verifica errores.

Verificar carga de módulos:
Usa lsmod | grep para confirmar que los módulos están activos.

Verificar archivos en /proc:
Comprueba existencia y muestra contenido de /proc/cpu_202201947 y /proc/ram_202201947.

```bash
./install_modules.sh
```

#### Leer Módulos
Lee y muestra la información de los módulos de kernel cpu_202201947 y ram_202201947 cargados en /proc.

Funciones principales:

Definir nombres de módulos:
Usa variables para identificar los módulos cpu_202201947 y ram_202201947.

Colores para mensajes:
Define colores para mensajes de estado (éxito y error).

Verificar carga de módulos:
Utiliza lsmod | grep para comprobar si los módulos están activos. Si no lo están, muestra error y termina.

Leer archivos /proc:
Verifica existencia de /proc/cpu_202201947 y /proc/ram_202201947. Si existen, imprime su contenido; si no, muestra error.
```bash
./read_modules.sh
```

#### Eliminar Módulos
Elimina los módulos de kernel cpu_202201947 y ram_202201947, limpia archivos de compilación y verifica su correcta eliminación de /proc.

Funciones principales:

Define nombres de módulos y ruta de trabajo (MODULES_DIR).

Establece colores para mensajes de éxito y error.

Implementa la función check_error para validar la ejecución correcta de comandos.

Cambia al directorio de módulos especificado.

Verifica si los módulos están cargados con lsmod y los elimina con rmmod.

Muestra mensajes de confirmación de descarga exitosa o indica si el módulo no estaba cargado.

Ejecuta make clean para eliminar archivos generados por compilación.

Verifica que los archivos /proc/cpu_202201947 y /proc/ram_202201947 hayan sido eliminados.
```bash
./remove_modules.sh
```

---

### 2. Construcción y Ejecución de la Aplicación

#### Levantar o Crear Contenedores con Docker Compose
Prepara y despliega un entorno Docker para el proyecto, verificando herramientas, imágenes, conectividad y estado de los contenedores.

Funciones principales:

Define colores para mensajes de salida (print_success, print_warning, print_error).

Verifica la existencia y funcionamiento de Docker y Docker Compose.

Cambia al directorio raíz del proyecto.

Comprueba si existe docker-compose.yml.

Limpia contenedores, volúmenes e imágenes de despliegues previos.

Descarga las imágenes necesarias desde DockerHub o verifica su presencia local.

Arranca los contenedores definidos en docker-compose.yml.

Espera y valida que todos los contenedores estén ejecutándose correctamente.

Realiza pruebas de conectividad a los servicios expuestos (backend y frontend).

Protege y verifica la integridad de la imagen alpine-stress.

Muestra las URLs de acceso a los servicios desplegados.
```bash
./deploy_app.sh
```

#### Detener o Eliminar Contenedores de la App
Realiza el apagado y limpieza de un entorno Docker para el proyecto, ofreciendo un menú interactivo con diferentes niveles de limpieza, asegurando la protección de imágenes críticas.

Funciones principales:
Define colores para mensajes de salida (print_success, print_warning, print_error).

Cambia al directorio raíz del proyecto.

Verifica la existencia y funcionamiento de Docker.

Comprueba si existe docker-compose.yml.

Protege la imagen containerstack/alpine-stress:latest mediante un backup temporal.

Ofrece un menú con las siguientes opciones:

Apagado suave (detiene contenedores).

Apagado completo (detiene y elimina volúmenes).

Limpieza profunda (elimina volúmenes, imágenes y redes no usadas).

Limpieza agresiva (elimina imágenes específicas del proyecto).

Cancelar operación.

Realiza la acción seleccionada según la opción elegida por el usuario.

Valida y restaura (si es necesario) la imagen protegida alpine-stress.

Elimina el backup temporal si la protección de alpine-stress fue exitosa.

Muestra mensajes claros sobre el estado final de la operación.


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

### 3. Simulación de Carga (Stress Testing)

#### Crear Contenedores para Estresar RAM y CPU (dura 1 min)
Despliega 10 contenedores Docker basados en la imagen containerstack/alpine-stress, ejecutando diferentes tipos de estrés para probar los recursos del sistema.

Funciones principales:
Define colores para mensajes de salida (errores y éxitos).

Verifica que Docker esté instalado y disponible.

Comprueba que la imagen containerstack/alpine-stress esté presente localmente.

Define un conjunto de opciones para estrés: CPU, I/O, RAM (memoria), y disco.

Despliega 10 contenedores con nombres únicos que ejecutan aleatoriamente uno de los tipos de estrés definidos, cada uno con un tiempo de ejecución limitado a 60 segundos.

Muestra mensajes de éxito o error para la creación de cada contenedor.

Indica al final que el despliegue se completó satisfactoriamente.
```bash
./stress_containers.sh
```

#### Detener/Eliminar Contenedores de Prueba
Elimina todos los contenedores Docker cuyo nombre contiene el prefijo stress_, usados para pruebas de estrés.

Funciones principales:
Define colores para mensajes de salida (errores y éxitos).

Verifica que Docker esté instalado y disponible.

Busca contenedores en ejecución o detenidos que tengan nombres que comienzan con stress_.

Elimina forzosamente esos contenedores si existen.

Informa al usuario si no se encontraron contenedores para eliminar.

Maneja errores y finaliza el script si falla la eliminación.

Muestra mensajes de estado durante todo el proceso.
```bash
./remove_containers.sh
```

---

### 4. Acceso a la Base de Datos (PostgreSQL)

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
 SELECT * FROM cpu_metrics ORDER BY created_at DESC LIMIT 10;
```

* Ver últimos datos de RAM:

```sql
 SELECT * FROM ram_metrics ORDER BY created_at DESC LIMIT 10;
```

