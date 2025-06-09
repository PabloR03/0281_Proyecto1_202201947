require('dotenv').config();

const config = {
    // URL del backend Go
    backendUrl: process.env.BACKEND_URL || 'http://localhost:8080',
    
    // Puerto para el servicio NodeJS
    port: process.env.NODEJS_PORT || 3001,
    
    // Intervalo de actualización en milisegundos
    updateInterval: process.env.UPDATE_INTERVAL || 5000,
    
    // Endpoints del backend
    endpoints: {
        cpu: '/cpu',
        ram: '/ram',
        health: '/health'
    },
    
    // Puerto del frontend Express
    frontendPort: process.env.FRONTEND_PORT || 3000
};

module.exports = config;