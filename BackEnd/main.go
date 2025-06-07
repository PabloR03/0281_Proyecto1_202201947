package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sync"
	"time"
)

const (
	cpuProcFile = "/proc/cpu_202201947"
	ramProcFile = "/proc/ram_202201947"
	port        = ":8080"
)

var (
	cpuData string
	ramData string
	mu      sync.Mutex // To safely update metrics
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
			mu.Lock()
			cpuData = fmt.Sprintf("Error: %v", err)
			mu.Unlock()
		} else {
			mu.Lock()
			cpuData = data
			mu.Unlock()
			log.Printf("[CPU] %s", data)
		}
		time.Sleep(5 * time.Second)
	}
}

func monitorRAM() {
	for {
		data, err := readProcFile(ramProcFile)
		if err != nil {
			log.Printf("Error RAM: %v", err)
			mu.Lock()
			ramData = fmt.Sprintf("Error: %v", err)
			mu.Unlock()
		} else {
			mu.Lock()
			ramData = data
			mu.Unlock()
			log.Printf("[RAM] %s", data)
		}
		time.Sleep(5 * time.Second)
	}
}

func main() {
	// Verify that the proc files exist
	if _, err := os.Stat(cpuProcFile); os.IsNotExist(err) {
		log.Fatalf("El módulo de CPU no está cargado. Verifica %s", cpuProcFile)
	}

	if _, err := os.Stat(ramProcFile); os.IsNotExist(err) {
		log.Fatalf("El módulo de RAM no está cargado. Verifica %s", ramProcFile)
	}

	// Start monitoring goroutines
	go monitorCPU()
	go monitorRAM()

	// Set up HTTP handlers
	http.HandleFunc("/cpu", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		io.WriteString(w, cpuData)
	})

	http.HandleFunc("/ram", func(w http.ResponseWriter, r *http.Request) {
		mu.Lock()
		defer mu.Unlock()
		io.WriteString(w, ramData)
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "OK")
	})

	// Start HTTP server
	log.Printf("Iniciando agente de monitoreo en puerto %s...", port)
	fmt.Printf("Métricas disponibles en http://localhost%s/cpu y http://localhost%s/ram\n", port, port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Error al iniciar el servidor HTTP: %v", err)
	}
}
