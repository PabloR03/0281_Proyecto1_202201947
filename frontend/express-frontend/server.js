const express = require('express');
const path = require('path');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
// Detectar si estamos en contenedor Docker y usar la URL apropiada
const NODEJS_API_URL = process.env.NODEJS_API_URL || 
    (process.env.NODE_ENV === 'production' ? 'http://host.docker.internal:3001' : 'http://localhost:3001');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Proxy endpoints para obtener datos desde el servicio NodeJS
app.get('/api/data/metrics', async (req, res) => {
    try {
        const response = await axios.get(`${NODEJS_API_URL}/api/metrics`);
        res.json(response.data);
    } catch (error) {
        console.error('Error fetching metrics:', error.message);
        res.status(500).json({ 
        error: 'Error al obtener métricas',
        details: error.message 
        });
    }
});

app.get('/api/data/metrics/latest', async (req, res) => {
    try {
        const response = await axios.get(`${NODEJS_API_URL}/api/metrics/latest`);
        res.json(response.data);
    } catch (error) {
        console.error('Error fetching latest metrics:', error.message);
        res.status(500).json({ 
        error: 'Error al obtener métricas más recientes',
        details: error.message 
        });
    }
});

app.get('/api/data/metrics/cpu', async (req, res) => {
    try {
        const response = await axios.get(`${NODEJS_API_URL}/api/metrics/cpu`);
        res.json(response.data);
    } catch (error) {
        console.error('Error fetching CPU metrics:', error.message);
        res.status(500).json({ 
        error: 'Error al obtener métricas de CPU',
        details: error.message 
        });
    }
});

app.get('/api/data/metrics/ram', async (req, res) => {
    try {
        const response = await axios.get(`${NODEJS_API_URL}/api/metrics/ram`);
        res.json(response.data);
    } catch (error) {
        console.error('Error fetching RAM metrics:', error.message);
        res.status(500).json({ 
        error: 'Error al obtener métricas de RAM',
        details: error.message 
        });
    }
});

// Ruta principal
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        service: 'express-frontend',
        uptime: process.uptime(),
        timestamp: new Date().toISOString(),
        api_url: NODEJS_API_URL
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`Frontend Express ejecutándose en puerto ${PORT}`);
    console.log(`Dashboard disponible en http://localhost:${PORT}`);
    console.log(`Conectando con NodeJS API en ${NODEJS_API_URL}`);
});

// Manejo de errores
process.on('uncaughtException', (error) => {
    console.error('Error no capturado en Express:', error);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Promesa rechazada no manejada en Express:', reason);
});