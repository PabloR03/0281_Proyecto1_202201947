const express = require('express');
const axios = require('axios');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Función para formatear datos para la vista EJS
function formatMetricForView(data, type) {
    try {
        // Si es un string, intentar parsearlo
        let parsedData = data;
        if (typeof data === 'string') {
            try {
                parsedData = JSON.parse(data);
            } catch (e) {
                return `<pre>${data}</pre>`;
            }
        }
        
        // Si es un objeto, formatearlo según el tipo
        if (typeof parsedData === 'object' && parsedData !== null) {
            if (type === 'CPU' && parsedData.porcentajeUso !== undefined) {
                return `
                    <div class="metric-display">
                        <div class="metric-value">
                            <span class="metric-number">${parsedData.porcentajeUso}%</span>
                            <span class="metric-label">Uso de CPU</span>
                        </div>
                        <div class="progress-bar">
                            <div class="progress-fill cpu-progress" style="width: ${parsedData.porcentajeUso}%"></div>
                        </div>
                        <div class="metric-raw">
                            <details>
                                <summary>Ver datos completos</summary>
                                <pre>${JSON.stringify(parsedData, null, 2)}</pre>
                            </details>
                        </div>
                    </div>
                `;
            } else if (type === 'RAM' && parsedData.total !== undefined) {
                const usagePercent = parsedData.porcentajeUso || Math.round((parsedData.uso / parsedData.total) * 100);
                return `
                    <div class="metric-display">
                        <div class="metric-value">
                            <span class="metric-number">${usagePercent}%</span>
                            <span class="metric-label">Uso de RAM</span>
                        </div>
                        <div class="progress-bar">
                            <div class="progress-fill ram-progress" style="width: ${usagePercent}%"></div>
                        </div>
                        <div class="ram-details">
                            <div class="ram-stat">
                                <span class="stat-label">Total:</span>
                                <span class="stat-value">${parsedData.total} MB</span>
                            </div>
                            <div class="ram-stat">
                                <span class="stat-label">En uso:</span>
                                <span class="stat-value">${parsedData.uso} MB</span>
                            </div>
                            <div class="ram-stat">
                                <span class="stat-label">Libre:</span>
                                <span class="stat-value">${parsedData.libre} MB</span>
                            </div>
                        </div>
                        <div class="metric-raw">
                            <details>
                                <summary>Ver datos completos</summary>
                                <pre>${JSON.stringify(parsedData, null, 2)}</pre>
                            </details>
                        </div>
                    </div>
                `;
            }
        }
        
        return `<pre>${JSON.stringify(parsedData, null, 2)}</pre>`;
    } catch (error) {
        return `<pre>${data}</pre>`;
    }
}

// Configurar motor de plantillas
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Agregar función helper para EJS
app.locals.formatMetricOutput = formatMetricForView;

// Servir archivos estáticos
app.use(express.static('public'));

// Middleware para parsear JSON
app.use(express.json());

// URL de tu backend en Go
const BACKEND_URL = 'http://localhost:8080';

// Función para obtener datos del backend
async function getSystemMetrics() {
    try {
        const [cpuResponse, ramResponse, healthResponse] = await Promise.all([
            axios.get(`${BACKEND_URL}/cpu`).catch(err => ({ data: `Error: ${err.message}` })),
            axios.get(`${BACKEND_URL}/ram`).catch(err => ({ data: `Error: ${err.message}` })),
            axios.get(`${BACKEND_URL}/health`).catch(err => ({ data: `Error: ${err.message}` }))
        ]);

        return {
            cpu: cpuResponse.data,
            ram: ramResponse.data,
            health: healthResponse.data,
            timestamp: new Date().toLocaleString('es-ES')
        };
    } catch (error) {
        throw new Error(`Error al conectar con el backend: ${error.message}`);
    }
}

// Ruta principal
app.get('/', async (req, res) => {
    try {
        const metrics = await getSystemMetrics();
        res.render('index', { metrics: metrics, error: null });
    } catch (error) {
        console.error('Error al obtener métricas del sistema:', error.message);
        res.render('index', { 
            metrics: null, 
            error: 'No se pudieron cargar las métricas del sistema. Verifica que el backend esté ejecutándose.' 
        });
    }
});

// Ruta API para obtener métricas (para AJAX)
app.get('/api/metrics', async (req, res) => {
    try {
        const metrics = await getSystemMetrics();
        res.json(metrics);
    } catch (error) {
        console.error('Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// Ruta específica para CPU
app.get('/api/cpu', async (req, res) => {
    try {
        const response = await axios.get(`${BACKEND_URL}/cpu`);
        res.json({ cpu: response.data, timestamp: new Date().toLocaleString('es-ES') });
    } catch (error) {
        res.status(500).json({ error: `Error al obtener datos de CPU: ${error.message}` });
    }
});

// Ruta específica para RAM
app.get('/api/ram', async (req, res) => {
    try {
        const response = await axios.get(`${BACKEND_URL}/ram`);
        res.json({ ram: response.data, timestamp: new Date().toLocaleString('es-ES') });
    } catch (error) {
        res.status(500).json({ error: `Error al obtener datos de RAM: ${error.message}` });
    }
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`Servidor frontend corriendo en http://localhost:${PORT}`);
    console.log(`Conectándose al backend en ${BACKEND_URL}`);
    console.log('Endpoints disponibles:');
    console.log('  - http://localhost:' + PORT + ' (Vista principal)');
    console.log('  - http://localhost:' + PORT + '/api/metrics (Todas las métricas)');
    console.log('  - http://localhost:' + PORT + '/api/cpu (Solo CPU)');
    console.log('  - http://localhost:' + PORT + '/api/ram (Solo RAM)');
});

module.exports = app;