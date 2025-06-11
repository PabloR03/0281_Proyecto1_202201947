// Variables globales
let cpuChart, ramChart, combinedChart;
let isPaused = false;
let maxRecords = 20;

// Elementos del DOM
const elements = {
    connectionStatus: document.getElementById('connectionStatus'),
    statusText: document.getElementById('statusText'),
    lastUpdate: document.getElementById('lastUpdate'),
    cpuPercentage: document.getElementById('cpuPercentage'),
    ramPercentage: document.getElementById('ramPercentage'),
    cpuProgressBar: document.getElementById('cpuProgressBar'),
    ramProgressBar: document.getElementById('ramProgressBar'),
    ramDetails: document.getElementById('ramDetails'),
    cpuCount: document.getElementById('cpuCount'),
    ramCount: document.getElementById('ramCount'),
    pauseBtn: document.getElementById('pauseBtn'),
    clearBtn: document.getElementById('clearBtn'),
    refreshBtn: document.getElementById('refreshBtn'),
    timeRange: document.getElementById('timeRange')
};

// Configuración de Chart.js
Chart.defaults.responsive = true;
Chart.defaults.maintainAspectRatio = false;

// Configuración común para gráficas
const commonChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    interaction: {
        intersect: false,
        mode: 'index'
    },
    plugins: {
        legend: {
            position: 'top',
        },
        tooltip: {
            backgroundColor: 'rgba(0, 0, 0, 0.8)',
            titleColor: 'white',
            bodyColor: 'white',
            borderColor: 'rgba(255, 255, 255, 0.1)',
            borderWidth: 1
        }
    },
    scales: {
        x: {
            display: true,
            title: {
                display: true,
                text: 'Tiempo'
            },
            ticks: {
                maxTicksLimit: 10
            }
        },
        y: {
            display: true,
            beginAtZero: true,
            max: 100,
            title: {
                display: true,
                text: 'Porcentaje (%)'
            }
        }
    }
};

// Inicializar gráficas
function initializeCharts() {
    // Gráfica combinada (CPU y RAM en tiempo real)
    const combinedCtx = document.getElementById('combinedChart').getContext('2d');
    combinedChart = new Chart(combinedCtx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                {
                    label: 'CPU %',
                    data: [],
                    borderColor: '#3498db',
                    backgroundColor: 'rgba(52, 152, 219, 0.1)',
                    borderWidth: 3,
                    fill: false,
                    tension: 0.4,
                    pointBackgroundColor: '#3498db',
                    pointBorderColor: '#2980b9',
                    pointRadius: 3,
                    pointHoverRadius: 5
                },
                {
                    label: 'RAM %',
                    data: [],
                    borderColor: '#e74c3c',
                    backgroundColor: 'rgba(231, 76, 60, 0.1)',
                    borderWidth: 3,
                    fill: false,
                    tension: 0.4,
                    pointBackgroundColor: '#e74c3c',
                    pointBorderColor: '#c0392b',
                    pointRadius: 3,
                    pointHoverRadius: 5
                }
            ]
        },
        options: {
            ...commonChartOptions,
            plugins: {
                ...commonChartOptions.plugins,
                title: {
                    display: true,
                    text: 'CPU y RAM - Comparativa',
                    font: {
                        size: 18,
                        weight: 'bold'
                    }
                }
            }
        }
    });
}

// Función para formatear timestamp
function formatTime(timestamp) {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('es-ES', { 
        hour: '2-digit', 
        minute: '2-digit', 
        second: '2-digit' 
    });
}

// Función para actualizar las tarjetas de métricas
function updateMetricCards(latest) {
    if (latest.cpu) {
        const cpuPercent = latest.cpu.porcentajeUso || 0;
        elements.cpuPercentage.textContent = `${cpuPercent}%`;
        elements.cpuProgressBar.style.width = `${cpuPercent}%`;
    }

    if (latest.ram) {
        const ramPercent = latest.ram.porcentajeUso || 0;
        const ramUsed = latest.ram.uso || 0;
        const ramTotal = latest.ram.total || 0;
        const ramFree = ramTotal - ramUsed;

        elements.ramPercentage.textContent = `${ramPercent}%`;
        elements.ramProgressBar.style.width = `${ramPercent}%`;
        elements.ramDetails.textContent = `${ramUsed} MB / ${ramTotal} MB (Libre: ${ramFree} MB)`;
    }
}

// Función para actualizar gráficas
function updateCharts(data) {
    const cpuData = data.cpu || [];
    const ramData = data.ram || [];
    
    // Limitar registros según configuración
    const limitedCpuData = cpuData.slice(-maxRecords);
    const limitedRamData = ramData.slice(-maxRecords);
    
    // Preparar labels (timestamps)
    const cpuLabels = limitedCpuData.map(item => formatTime(item.timestamp));
    const ramLabels = limitedRamData.map(item => formatTime(item.timestamp));
    
    // Actualizar gráfica combinada (usar el dataset más largo como referencia)
    const maxLength = Math.max(limitedCpuData.length, limitedRamData.length);
    let combinedLabels = [];
    
    if (limitedCpuData.length >= limitedRamData.length) {
        combinedLabels = cpuLabels;
    } else {
        combinedLabels = ramLabels;
    }
    
    // Sincronizar datos para la gráfica combinada
    const syncedCpuData = [];
    const syncedRamData = [];
    
    for (let i = 0; i < maxLength; i++) {
        if (i < limitedCpuData.length) {
            syncedCpuData.push(limitedCpuData[i].porcentajeUso || 0);
        } else {
            syncedCpuData.push(null);
        }
        
        if (i < limitedRamData.length) {
            syncedRamData.push(limitedRamData[i].porcentajeUso || 0);
        } else {
            syncedRamData.push(null);
        }
    }
    
    combinedChart.data.labels = combinedLabels;
    combinedChart.data.datasets[0].data = syncedCpuData;
    combinedChart.data.datasets[1].data = syncedRamData;
    combinedChart.update('none');
    
    // Actualizar contadores
    elements.cpuCount.textContent = cpuData.length;
    elements.ramCount.textContent = ramData.length;
}

// Función para obtener datos del API
async function fetchData() {
    try {
        const response = await fetch('/api/data/metrics');
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        
        // Actualizar estado de conexión
        elements.connectionStatus.className = 'status-dot online';
        elements.statusText.textContent = 'Conectado';
        elements.lastUpdate.textContent = `Actualizado: ${formatTime(data.lastUpdate || new Date())}`;
        
        return data;
    } catch (error) {
        console.error('Error fetching data:', error);
        
        // Actualizar estado de conexión
        elements.connectionStatus.className = 'status-dot offline';
        elements.statusText.textContent = 'Error de conexión';
        elements.lastUpdate.textContent = `Error: ${error.message}`;
        
        return null;
    }
}

// Función para obtener métricas más recientes
async function fetchLatestMetrics() {
    try {
        const response = await fetch('/api/data/metrics/latest');
        if (!response.ok) throw new Error('Error al obtener métricas recientes');
        return await response.json();
    } catch (error) {
        console.error('Error fetching latest metrics:', error);
        return null;
    }
}

// Función principal de actualización
async function updateDashboard() {
    if (isPaused) return;
    
    const data = await fetchData();
    if (data) {
        updateCharts(data);
        
        // Obtener métricas más recientes para las tarjetas
        const latest = await fetchLatestMetrics();
        if (latest) {
            updateMetricCards(latest);
        }
    }
}

// Función para limpiar gráficas
function clearCharts() {
    if (confirm('¿Estás seguro de que quieres limpiar todas las gráficas?')) {
        combinedChart.data.labels = [];
        combinedChart.data.datasets[0].data = [];
        combinedChart.data.datasets[1].data = [];
        combinedChart.update();
        
        console.log('Gráficas limpiadas');
    }
}

// Event listeners
elements.pauseBtn.addEventListener('click', () => {
    isPaused = !isPaused;
    elements.pauseBtn.textContent = isPaused ? 'Reanudar' : 'Pausar';
    elements.pauseBtn.style.background = isPaused ? 
        'linear-gradient(135deg, #27ae60, #2ecc71)' : 
        'linear-gradient(135deg, #3498db, #2980b9)';
    
    console.log(isPaused ? 'Dashboard pausado' : 'Dashboard reanudado');
});

elements.clearBtn.addEventListener('click', clearCharts);

elements.refreshBtn.addEventListener('click', () => {
    console.log('Actualizando manualmente...');
    updateDashboard();
});

elements.timeRange.addEventListener('change', (e) => {
    maxRecords = parseInt(e.target.value);
    console.log(`Cambiado a mostrar últimos ${maxRecords} registros`);
    updateDashboard(); // Actualizar inmediatamente con el nuevo rango
});

// Inicialización
document.addEventListener('DOMContentLoaded', () => {
    console.log('Iniciando Dashboard de Monitoreo...');
    
    // Inicializar gráficas
    initializeCharts();
    
    // Primera actualización
    updateDashboard();
    
    // Configurar actualización automática cada 5 segundos
    setInterval(updateDashboard, 5000);
    
    console.log('Dashboard inicializado correctamente');
});

// Manejo de errores globales
window.addEventListener('error', (e) => {
    console.error('Error global:', e.error);
});

window.addEventListener('unhandledrejection', (e) => {
    console.error('Promesa rechazada:', e.reason);
});

// Funciones auxiliares para debugging
window.debugDashboard = {
    fetchData,
    updateDashboard,
    clearCharts,
    togglePause: () => elements.pauseBtn.click(),
    setTimeRange: (value) => {
        elements.timeRange.value = value;
        elements.timeRange.dispatchEvent(new Event('change'));
    }
};