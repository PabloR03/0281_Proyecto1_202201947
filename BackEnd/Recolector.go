package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"time"
)

const (
	cpuProcFile = "/proc/cpu_202201947"
	ramProcFile = "/proc/ram_202201947"
	interval    = 5 * time.Second
)

func readProcFile(path string) (string, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return "", fmt.Errorf("error al leer %s: %v", path, err)
	}
	return string(data), nil
}

func monitorCPU() {
	for {
		data, err := readProcFile(cpuProcFile)
		if err != nil {
			log.Printf("Error CPU: %v", err)
		} else {
			fmt.Printf("[CPU] %s\n", data)
		}
		time.Sleep(interval)
	}
}

func monitorRAM() {
	for {
		data, err := readProcFile(ramProcFile)
		if err != nil {
			log.Printf("Error RAM: %v", err)
		} else {
			fmt.Printf("[RAM] %s\n", data)
		}
		time.Sleep(interval)
	}
}

func main() {
	// Verificar que los módulos están cargados
	if _, err := os.Stat(cpuProcFile); os.IsNotExist(err) {
		log.Fatalf("El módulo de CPU no está cargado. Verifica %s", cpuProcFile)
	}

	if _, err := os.Stat(ramProcFile); os.IsNotExist(err) {
		log.Fatalf("El módulo de RAM no está cargado. Verifica %s", ramProcFile)
	}

	fmt.Println("Iniciando agente de monitoreo...")
	fmt.Printf("Mostrando métricas cada %v\n", interval)

	// Iniciar monitores en goroutines
	go monitorCPU()
	go monitorRAM()

	// Mantener el programa corriendo
	select {}
}
