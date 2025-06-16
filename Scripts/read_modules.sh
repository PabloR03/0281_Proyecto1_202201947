#!/bin/bash

# Nombres de los módulos
CPU_MODULE="cpu_202201947"
RAM_MODULE="ram_202201947"

echo "=== Leyendo información de los módulos ==="

# Leer métricas de CPU
echo "Métricas de CPU:"
cat "/proc/$CPU_MODULE"

echo "Métricas de RAM:"
cat "/proc/$RAM_MODULE"

echo "=== Lectura completada ==="