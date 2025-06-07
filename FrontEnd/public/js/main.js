// Variables globales
let autoRefreshInterval;
let isAutoRefreshActive = true;

// Función para actualizar todas las métricas
async function actualizarTodo() {
    try {
        showLoading();
        
        const response = await fetch('/api/metrics');
        const data = await response.json();
        
        if (response.ok) {
            updateMetricsDisplay(data);
            updateStatusBar(data);
        } else {
            throw new Error(data.error || 'Error al obtener métricas');
        }
    } catch (error) {
        console.error('Error:', error);
        showError('Error al actualizar métricas: ' + error.message);
    }
}

// Función para actualizar solo CPU
async function actualizarCPU() {
    try {
        const cpuElement = document.getElementById('cpu-data');
        cpuElement.innerHTML = '<div class="loading-small">Actualizando CPU...</div>';
        
        const response = await fetch('/api/cpu');
        const data = await response.json();
        
        if (response.ok) {
            cpuElement.innerHTML = formatMetricData(data.cpu, 'CPU');
        } else {
            throw new Error(data.error || 'Error al obtener datos de CPU');
        }
    } catch (error) {
        console.error('Error CPU:', error);
        document.getElementById('cpu-data').innerHTML = `<div class="error-small">Error: ${error.message}</div>`;
    }
}

// Función para actualizar solo RAM
async function actualizarRAM() {
    try {
        const ramElement = document.getElementById('ram-data');
        ramElement.innerHTML = '<div class="loading-small">Actualizando RAM...</div>';
        
        const response = await fetch('/api/ram');
        const data = await response.json();
        
        if (response.ok) {
            ramElement.innerHTML = formatMetricData(data.ram, 'RAM');
        } else {
            throw new Error(data.error || 'Error al obtener datos de RAM');
        }
    } catch (error) {
        console.error('Error RAM:', error);
        document.getElementById('ram-data').innerHTML = `<div class="error-small">Error: ${error.message}</div>`;
    }
}

// Función para mostrar loading
function showLoading() {
    const cpuElement = document.getElementById('cpu-data');
    const ramElement = document.getElementById('ram-data');
    
    if (cpuElement) cpuElement.innerHTML = '<div class="loading-small">Actualizando...</div>';
    if (ramElement) ramElement.innerHTML = '<div class="loading-small">Actualizando...</div>';
}

// Función para mostrar error
function showError(message) {
    const cpuElement = document.getElementById('cpu-data');
    const ramElement = document.getElementById('ram-data');
    
    if (cpuElement) cpuElement.innerHTML = `<div class="error-small">${message}</div>`;
    if (ramElement) ramElement.innerHTML = `<div class="error-small">${message}</div>`;
}

// Función para actualizar la visualización de métricas
function updateMetricsDisplay(data) {
    const cpuElement = document.getElementById('cpu-data');
    const ramElement = document.getElementById('ram-data');
    
    if (cpuElement) {
        cpuElement.innerHTML = formatMetricData(data.cpu, 'CPU');
    }
    
    if (ramElement) {
        ramElement.innerHTML = formatMetricData(data.ram, 'RAM');
    }
}

// Función para formatear los datos de métricas
function formatMetricData(data, type) {
    try {
        // Si es un string, intentar parsearlo como JSON
        let parsedData = data;
        if (typeof data === 'string') {
            try {
                parsedData = JSON.parse(data);
            } catch (e) {
                // Si no se puede parsear, mostrar tal como está
                return `<pre>${data}</pre>`;
            }
        }
        
        // Si es un objeto, formatearlo bonito
        if (typeof parsedData === 'object' && parsedData !== null) {
            if (type === 'CPU') {
                return formatCPUData(parsedData);
            } else if (type === 'RAM') {
                return formatRAMData(parsedData);
            } else {
                return `<pre>${JSON.stringify(parsedData, null, 2)}</pre>`;
            }
        }
        
        return `<pre>${data}</pre>`;
    } catch (error) {
        return `<pre>${data}</pre>`;
    }
}

// Función para formatear datos de CPU
function formatCPUData(data) {
    if (data.porcentajeUso !== undefined) {
        return `
            <div class="metric-display">
                <div class="metric-value">
                    <span class="metric-number">${data.porcentajeUso}%</span>
                    <span class="metric-label">Uso de CPU</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill cpu-progress" style="width: ${data.porcentajeUso}%"></div>
                </div>
                <div class="metric-raw">
                    <details>
                        <summary>Ver datos completos</summary>
                        <pre>${JSON.stringify(data, null, 2)}</pre>
                    </details>
                </div>
            </div>
        `;
    }
    return `<pre>${JSON.stringify(data, null, 2)}</pre>`;
}

// Función para formatear datos de RAM
function formatRAMData(data) {
    if (data.total !== undefined && data.libre !== undefined && data.uso !== undefined) {
        const totalMB = data.total;
        const usedMB = data.uso;
        const freeMB = data.libre;
        const usagePercent = data.porcentajeUso || Math.round((usedMB / totalMB) * 100);
        
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
                        <span class="stat-value">${totalMB} MB</span>
                    </div>
                    <div class="ram-stat">
                        <span class="stat-label">En uso:</span>
                        <span class="stat-value">${usedMB} MB</span>
                    </div>
                    <div class="ram-stat">
                        <span class="stat-label">Libre:</span>
                        <span class="stat-value">${freeMB} MB</span>
                    </div>
                </div>
                <div class="metric-raw">
                    <details>
                        <summary>Ver datos completos</summary>
                        <pre>${JSON.stringify(data, null, 2)}</pre>
                    </details>
                </div>
            </div>
        `;
    }
    return `<pre>${JSON.stringify(data, null, 2)}</pre>`;
}

// Función para actualizar la barra de estado
function updateStatusBar(data) {
    const statusElements = document.querySelectorAll('.status-item');
    if (statusElements.length >= 2) {
        statusElements[1].innerHTML = `📅 Última actualización: ${data.timestamp}`;
        if (statusElements.length >= 3) {
            statusElements[2].innerHTML = `⚡ Estado: ${data.health}`;
        }
    }
}

// Función para toggle auto-refresh
function toggleAutoRefresh() {
    const button = document.getElementById('auto-refresh-btn');
    
    if (isAutoRefreshActive) {
        clearInterval(autoRefreshInterval);
        isAutoRefreshActive = false;
        button.innerHTML = '▶️ Reanudar Auto-actualización';
        button.classList.remove('secondary-btn');
        button.classList.add('primary-btn');
    } else {
        startAutoRefresh();
        isAutoRefreshActive = true;
        button.innerHTML = '⏸️ Pausar Auto-actualización';
        button.classList.remove('primary-btn');
        button.classList.add('secondary-btn');
    }
}

// Función para iniciar auto-refresh
function startAutoRefresh() {
    autoRefreshInterval = setInterval(actualizarTodo, 10000); // Cada 10 segundos
}

// Función para recargar la página
function recargarDatos() {
    window.location.reload();
}

// Función para formatear datos si es necesario
function formatearDatos(data) {
    // Si los datos vienen en formato JSON, parsearlos
    try {
        if (typeof data === 'string' && (data.startsWith('{') || data.startsWith('['))) {
            return JSON.stringify(JSON.parse(data), null, 2);
        }
    } catch (e) {
        // Si no se puede parsear, devolver tal como está
    }
    return data;
}

// Agregar estilos CSS dinámicamente para elementos de loading y error pequeños
function addDynamicStyles() {
    const style = document.createElement('style');
    style.textContent = `
        .loading-small {
            text-align: center;
            padding: 20px;
            color: #666;
            font-style: italic;
        }
        
        .error-small {
            background: #f8d7da;
            color: #721c24;
            padding: 15px;
            border-radius: 5px;
            border-left: 4px solid #dc3545;
            margin: 10px 0;
        }
        
        .metric-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .refresh-btn:active {
            transform: scale(0.95);
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .metric-data {
            animation: fadeIn 0.5s ease-in;
        }
        
        .metric-display {
            padding: 10px 0;
        }
        
        .metric-value {
            text-align: center;
            margin-bottom: 15px;
        }
        
        .metric-number {
            font-size: 2.5em;
            font-weight: bold;
            color: #495057;
            display: block;
        }
        
        .metric-label {
            font-size: 1em;
            color: #6c757d;
            display: block;
            margin-top: 5px;
        }
        
        .progress-bar {
            width: 100%;
            height: 20px;
            background-color: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            margin-bottom: 20px;
        }
        
        .progress-fill {
            height: 100%;
            border-radius: 10px;
            transition: width 0.5s ease;
        }
        
        .cpu-progress {
            background: linear-gradient(45deg, #ff6b6b, #ee5a52);
        }
        
        .ram-progress {
            background: linear-gradient(45deg, #4ecdc4, #44b3aa);
        }
        
        .ram-details {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 15px;
            margin-bottom: 15px;
        }
        
        .ram-stat {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #e9ecef;
        }
        
        .stat-label {
            font-size: 0.9em;
            color: #6c757d;
            display: block;
            margin-bottom: 5px;
        }
        
        .stat-value {
            font-weight: bold;
            color: #495057;
            font-size: 1.1em;
        }
        
        .metric-raw {
            margin-top: 15px;
        }
        
        .metric-raw details {
            cursor: pointer;
        }
        
        .metric-raw summary {
            color: #6c757d;
            font-size: 0.9em;
            padding: 5px 0;
        }
        
        .metric-raw summary:hover {
            color: #495057;
        }
        
        .metric-raw pre {
            margin-top: 10px;
            font-size: 0.8em;
        }
    `;
    document.head.appendChild(style);
}

// Evento cuando se carga la página
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Monitor del Sistema cargado correctamente');
    
    // Agregar estilos dinámicos
    addDynamicStyles();
    
    // Iniciar auto-refresh si hay métricas
    if (document.getElementById('cpu-data')) {
        startAutoRefresh();
        console.log('✅ Auto-actualización iniciada (cada 10 segundos)');
    }
    
    // Agregar efecto de hover a las tarjetas
    const metricCards = document.querySelectorAll('.metric-card');
    metricCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
    
    console.log('📊 Endpoints del backend:');
    console.log('  - http://localhost:8080/cpu');
    console.log('  - http://localhost:8080/ram');
    console.log('  - http://localhost:8080/health');
});

// // // Limpiar interval al cerrar la página
// // window.addEventListener('beforeunload', function() {
// //     if (autoRefreshInterval) {
// //         clearInterval(autoRefreshInterval);
// //     }
// // });
// //         html += '</div>';
// //         datosDiv.innerHTML = html;
// //     } else if (typeof data === 'object') {
// //         // Si es un objeto, mostrar sus propiedades
// //         let html = '<div class="data-grid">';
// //         for (const [key, value] of Object.entries(data)) {
// //             html += `
// //                 <div class="data-card">
// //                     <h3>${key}</h3>
// //                     <p>${typeof value === 'object' ? JSON.stringify(value, null, 2) : value}</p>
// //                 </div>
// //             `;
// //         }
// //         html += '</div>';
// //         datosDiv.innerHTML = html;
// //     } else {
// //         // Para otros tipos de datos
// //         datosDiv.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`;
// //     }
// // }

// Función para recargar la página
function recargarDatos() {
    window.location.reload();
}

// Actualizar datos automáticamente cada 30 segundos (opcional)
setInterval(actualizarDatos, 30000);

// Evento cuando se carga la página
document.addEventListener('DOMContentLoaded', function() {
    console.log('Frontend cargado correctamente');
    
    // Si hay datos iniciales, formatearlos mejor
    const datosDiv = document.getElementById('datos');
    if (datosDiv && datosDiv.querySelector('pre')) {
        try {
            const preElement = datosDiv.querySelector('pre');
            const data = JSON.parse(preElement.textContent);
            mostrarDatos(data);
        } catch (e) {
            // Si no se puede parsear, dejar como está
            console.log('Datos iniciales no son JSON válido');
        }
    }
});