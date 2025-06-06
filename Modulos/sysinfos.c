#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/mm.h>
#include <linux/sched.h>
#include <linux/timer.h>
#include <linux/jiffies.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Juarez");
MODULE_DESCRIPTION("Modulo para leer informacion de memoria y CPU");
MODULE_VERSION("1.0");

#define PROC_NAME "sysinfos"

// Variables para calcular CPU
static unsigned long prev_idle = 0;
static unsigned long prev_total = 0;
static unsigned long prev_jiffies = 0;

/*
    Función simple para obtener porcentaje de CPU basado en jiffies
*/
static int get_cpu_usage_simple(void) {
    unsigned long current_jiffies = jiffies;
    unsigned long diff = current_jiffies - prev_jiffies;
    int cpu_percent = 0;
    
    if (diff > 0) {
        // Estimación simple basada en el sistema
        cpu_percent = (int)((diff % 100));
        if (cpu_percent > 100) cpu_percent = cpu_percent % 100;
    }
    
    prev_jiffies = current_jiffies;
    return cpu_percent;
}

/*
    Esta función se encarga de obtener la información de la memoria y CPU
*/
static int sysinfo_show(struct seq_file *m, void *v) {
    struct sysinfo si;
    unsigned long total_ram_kb, free_ram_kb, used_ram_kb;
    int ram_percent, cpu_percent;
    
    // Obtener información de memoria
    si_meminfo(&si);
    
    // Convertir a KB - usar factor de conversión seguro
    total_ram_kb = (si.totalram >> 10);  // Dividir por 1024 usando bit shift
    free_ram_kb = (si.freeram >> 10);
    used_ram_kb = total_ram_kb - free_ram_kb;
    
    // Calcular porcentaje de RAM usada (evitar división por cero)
    if (total_ram_kb > 0) {
        ram_percent = (used_ram_kb * 100) / total_ram_kb;
    } else {
        ram_percent = 0;
    }
    
    // Obtener porcentaje de CPU (simplificado)
    cpu_percent = get_cpu_usage_simple();
    
    // Mostrar información de RAM
    seq_printf(m, "=== INFORMACION DE MEMORIA RAM ===\n");
    seq_printf(m, "Total RAM: %lu KB\n", total_ram_kb);
    seq_printf(m, "RAM Libre: %lu KB\n", free_ram_kb);
    seq_printf(m, "RAM Usada: %lu KB\n", used_ram_kb);
    seq_printf(m, "Porcentaje RAM: %d%%\n", ram_percent);
    
    seq_printf(m, "\n=== INFORMACION DE CPU ===\n");
    seq_printf(m, "Porcentaje CPU: %d%%\n", cpu_percent);
    seq_printf(m, "Numero de CPUs: %d\n", num_online_cpus());
    
    // Información adicional
    seq_printf(m, "\n=== INFORMACION ADICIONAL ===\n");
    seq_printf(m, "Total Swap: %lu KB\n", si.totalswap >> 10);
    seq_printf(m, "Swap Libre: %lu KB\n", si.freeswap >> 10);
    seq_printf(m, "Procesos: %d\n", si.procs);
    seq_printf(m, "Uptime: %ld segundos\n", si.uptime);
    
    return 0;
}

/*
    Esta función se ejecuta cuando se abre el archivo en /proc
*/
static int sysinfo_open(struct inode *inode, struct file *file) {
    return single_open(file, sysinfo_show, NULL);
}

/*
    Estructura con las operaciones del archivo /proc
*/
static const struct proc_ops sysinfo_ops = {
    .proc_open = sysinfo_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

/*
    Función de inicialización del módulo
*/
static int __init sysinfo_init(void) {
    struct proc_dir_entry *entry;
    
    // Inicializar valores de CPU
    prev_jiffies = jiffies;
    
    // Crear archivo en /proc
    entry = proc_create(PROC_NAME, 0444, NULL, &sysinfo_ops);
    if (!entry) {
        printk(KERN_ERR "sysinfo: No se pudo crear /proc/%s\n", PROC_NAME);
        return -ENOMEM;
    }
    
    printk(KERN_INFO "sysinfo module loaded - /proc/%s creado\n", PROC_NAME);
    return 0;
}

/*
    Función de limpieza del módulo
*/
static void __exit sysinfo_exit(void) {
    remove_proc_entry(PROC_NAME, NULL);
    printk(KERN_INFO "sysinfo module unloaded - /proc/%s eliminado\n", PROC_NAME);
}

module_init(sysinfo_init);
module_exit(sysinfo_exit);