#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/mm.h>
#include <linux/sched.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("202201947");
MODULE_DESCRIPTION("Modulo para leer informacion de memoria RAM");
MODULE_VERSION("1.0");

#define PROC_NAME "ram_202201947"

/*
    Esta función se encarga de obtener la información de la memoria RAM
*/
static int raminfo_show(struct seq_file *m, void *v) {
    struct sysinfo si;
    unsigned long total_ram, free_ram, used_ram, buffer_ram, cached_ram;
    int ram_percent;
    
    // Obtener información de memoria
    si_meminfo(&si);
    
    // Convertir a MB para mejor legibilidad
    total_ram = si.totalram * si.mem_unit / (1024 * 1024);
    free_ram = si.freeram * si.mem_unit / (1024 * 1024);
    buffer_ram = si.bufferram * si.mem_unit / (1024 * 1024);
    cached_ram = (global_node_page_state(NR_FILE_PAGES) - si.bufferram) * 
                 si.mem_unit / (1024 * 1024);
    
    // Calcular RAM usada (total - libre - buffers - cache)
    used_ram = total_ram - free_ram - buffer_ram - cached_ram;
    
    // Calcular porcentaje de RAM usada
    if (total_ram > 0) {
        ram_percent = (int)((used_ram * 100) / total_ram);
    } else {
        ram_percent = 0;
    }
    
    // Imprimir en formato JSON
    seq_printf(m, "{\"total\": %lu, \"libre\": %lu, \"uso\": %lu, \"porcentaje\": %d}\n",
                total_ram, free_ram, used_ram, ram_percent);
    
    return 0;
}

/*
    Esta función se ejecuta cuando se abre el archivo en /proc
*/
static int raminfo_open(struct inode *inode, struct file *file) {
    return single_open(file, raminfo_show, NULL);
}

/*
    Estructura con las operaciones del archivo /proc
*/
static const struct proc_ops raminfo_ops = {
    .proc_open = raminfo_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

/*
    Función de inicialización del módulo
*/
static int __init raminfo_init(void) {
    struct proc_dir_entry *entry;
    
    // Crear archivo en /proc
    entry = proc_create(PROC_NAME, 0444, NULL, &raminfo_ops);
    if (!entry) {
        printk(KERN_ERR "raminfo: No se pudo crear /proc/%s\n", PROC_NAME);
        return -ENOMEM;
    }
    
    printk(KERN_INFO "raminfo module loaded - /proc/%s creado\n", PROC_NAME);
    return 0;
}

/*
    Función de limpieza del módulo
*/
static void __exit raminfo_exit(void) {
    remove_proc_entry(PROC_NAME, NULL);
    printk(KERN_INFO "raminfo module unloaded - /proc/%s eliminado\n", PROC_NAME);
}

module_init(raminfo_init);
module_exit(raminfo_exit);