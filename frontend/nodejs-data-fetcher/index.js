const express = require('express');
const axios = require('axios');
const cors = require('cors');
const config = require('./config');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Almacenamiento de datos en memoria
let metricsData = {
    cpu: [],
    ram: [],
    lastUpdate: null
};

// Función para obtener datos del backend Go
async function fetchBackendData(endpoint) {
    try {
        const response = await axios.get(`${config.backendUrl}${endpoint}`, {
        timeout: 5000
        });
        return {
        success: true,
        data: response.data,
        timestamp: new Date().toISOString()
        };
    } catch (error) {
        console.error(`Error fetching ${endpoint}:`, error.message);
        return {
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
        };
    }
}

// Función para procesar y almacenar datos de CPU
async function updateCPUData() {
    const result = await fetchBackendData(config.endpoints.cpu);
    
    if (result.success) {
        try {
        const cpuData = typeof result.data === 'string' ? JSON.parse(result.data) : result.data;
        
        const processedData = {
            timestamp: result.timestamp,
            porcentajeUso: cpuData.porcentajeUso || 0,
            raw: cpuData
        };
        
        metricsData.cpu.push(processedData);
        
        // Mantener solo los últimos 100 registros
        if (metricsData.cpu.length > 100) {
            metricsData.cpu.shift();
        }
        
        console.log(`CPU actualizada: ${processedData.porcentajeUso}%`);
        } catch (parseError) {
        console.error('Error parsing CPU data:', parseError);
        }
    }
}

// Función para procesar y almacenar datos de RAM
async function updateRAMData() {
    const result = await fetchBackendData(config.endpoints.ram);
    
    if (result.success) {
        try {
        const ramData = typeof result.data === 'string' ? JSON.parse(result.data) : result.data;
        
        const processedData = {
            timestamp: result.timestamp,
            total: ramData.total || 0,
            libre: ramData.libre || 0,
            uso: ramData.uso || 0,
            porcentajeUso: ramData.porcentajeUso || 0,
            raw: ramData
        };
        
        metricsData.ram.push(processedData);
        
        // Mantener solo los últimos 100 registros
        if (metricsData.ram.length > 100) {
            metricsData.ram.shift();
        }
        
        console.log(`RAM actualizada: ${processedData.porcentajeUso}% (${processedData.uso}/${processedData.total} MB)`);
        } catch (parseError) {
        console.error('Error parsing RAM data:', parseError);
        }
    }
}

// Función principal de actualización
async function updateMetrics() {
    console.log('Actualizando métricas...');
    await Promise.all([
        updateCPUData(),
        updateRAMData()
    ]);
    metricsData.lastUpdate = new Date().toISOString();
}

// Endpoints API
app.get('/api/metrics', (req, res) => {
    res.json({
        cpu: metricsData.cpu,
        ram: metricsData.ram,
        lastUpdate: metricsData.lastUpdate,
        totalRecords: {
        cpu: metricsData.cpu.length,
        ram: metricsData.ram.length
        }
    });
});

app.get('/api/metrics/cpu', (req, res) => {
    res.json({
        data: metricsData.cpu,
        lastUpdate: metricsData.lastUpdate,
        count: metricsData.cpu.length
    });
});

app.get('/api/metrics/ram', (req, res) => {
    res.json({
        data: metricsData.ram,
        lastUpdate: metricsData.lastUpdate,
        count: metricsData.ram.length
    });
});

app.get('/api/metrics/latest', (req, res) => {
    const latest = {
        cpu: metricsData.cpu.length > 0 ? metricsData.cpu[metricsData.cpu.length - 1] : null,
        ram: metricsData.ram.length > 0 ? metricsData.ram[metricsData.ram.length - 1] : null,
        lastUpdate: metricsData.lastUpdate
    };
    res.json(latest);
});

app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        service: 'nodejs-data-fetcher',
        uptime: process.uptime(),
        memoryUsage: process.memoryUsage(),
        lastUpdate: metricsData.lastUpdate
    });
});

// Inicializar el servicio
async function startService() {
    console.log('Iniciando servicio NodeJS Data Fetcher...');
    
    // Verificar conectividad con el backend
    try {
        const healthCheck = await fetchBackendData(config.endpoints.health);
        if (healthCheck.success) {
        console.log('✅ Conectividad con backend Go verificada');
        } else {
        console.log('⚠️  Advertencia: No se pudo conectar con el backend Go');
        }
    } catch (error) {
        console.log('⚠️  Advertencia: Error al verificar backend Go:', error.message);
    }
    
    // Obtener datos iniciales
    await updateMetrics();
    
    // Configurar intervalo de actualización
    setInterval(updateMetrics, config.updateInterval);
    
    // Iniciar servidor
    app.listen(config.port, () => {
        console.log(`🚀 Servicio NodeJS ejecutándose en puerto ${config.port}`);
        console.log(`📊 Datos disponibles en http://localhost:${config.port}/api/metrics`);
        console.log(`🔄 Actualizando métricas cada ${config.updateInterval}ms`);
    });
}

// Manejo de errores
process.on('uncaughtException', (error) => {
    console.error('Error no capturado:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Promesa rechazada no manejada:', reason);
});

// Iniciar servicio
startService();