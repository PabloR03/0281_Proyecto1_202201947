#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/sched.h>
#include <linux/kernel_stat.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("202201947");
MODULE_DESCRIPTION("Modulo para monitoreo de CPU");
MODULE_VERSION("1.0");

#define PROC_NAME "cpu_202201947"

static unsigned long long prev_idle = 0;
static unsigned long long prev_total = 0;

/*
 * Calcula el porcentaje de uso de CPU basado en estadísticas de /proc/stat
 */
static int get_cpu_usage(void) {
    unsigned long long user, nice, system, idle, iowait, irq, softirq;
    unsigned long long total, work_diff, total_diff;
    int usage = 0;

    // Obtener estadísticas de CPU para cpu0
    struct kernel_cpustat *kstat = &kcpustat_cpu(0);
    user = kstat->cpustat[CPUTIME_USER];
    nice = kstat->cpustat[CPUTIME_NICE];
    system = kstat->cpustat[CPUTIME_SYSTEM];
    idle = kstat->cpustat[CPUTIME_IDLE];
    iowait = kstat->cpustat[CPUTIME_IOWAIT];
    irq = kstat->cpustat[CPUTIME_IRQ];
    softirq = kstat->cpustat[CPUTIME_SOFTIRQ];

    total = user + nice + system + idle + iowait + irq + softirq;

    if (prev_total != 0) {
        work_diff = (total - idle) - (prev_total - prev_idle);
        total_diff = total - prev_total;

        if (total_diff > 0) {
            usage = (work_diff * 100) / total_diff;
        }
    }

    prev_idle = idle;
    prev_total = total;

    return usage;
}

/*
 * Muestra la información de CPU en formato JSON
 */
static int cpuinfo_show(struct seq_file *m, void *v) {
    int cpu_usage = get_cpu_usage();

    // Mostrar solo el porcentaje en formato JSON simple
    seq_printf(m, "{\n\t\"porcentajeUso\": %d\n}\n", cpu_usage);

    return 0;
}

/*
 * Función para abrir el archivo en /proc
 */
static int cpuinfo_open(struct inode *inode, struct file *file) {
    return single_open(file, cpuinfo_show, NULL);
}

/*
 * Operaciones del archivo en /proc
 */
static const struct proc_ops cpuinfo_ops = {
    .proc_open = cpuinfo_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = single_release,
};

/*
 * Inicialización del módulo
 */
static int __init cpuinfo_init(void) {
    struct proc_dir_entry *entry;

    // Inicializar valores
    struct kernel_cpustat *kstat = &kcpustat_cpu(0);
    prev_total = kstat->cpustat[CPUTIME_USER] + kstat->cpustat[CPUTIME_NICE] +
                kstat->cpustat[CPUTIME_SYSTEM] + kstat->cpustat[CPUTIME_IDLE] +
                kstat->cpustat[CPUTIME_IOWAIT] + kstat->cpustat[CPUTIME_IRQ] +
                kstat->cpustat[CPUTIME_SOFTIRQ];
    prev_idle = kstat->cpustat[CPUTIME_IDLE];

    // Crear archivo en /proc
    entry = proc_create(PROC_NAME, 0444, NULL, &cpuinfo_ops);
    if (!entry) {
        printk(KERN_ERR "cpuinfo: No se pudo crear /proc/%s\n", PROC_NAME);
        return -ENOMEM;
    }

    printk(KERN_INFO "cpuinfo module loaded - /proc/%s creado\n", PROC_NAME);
    return 0;
}

/*
 * Limpieza del módulo
 */
static void __exit cpuinfo_exit(void) {
    remove_proc_entry(PROC_NAME, NULL);
    printk(KERN_INFO "cpuinfo module unloaded - /proc/%s eliminado\n", PROC_NAME);
}

module_init(cpuinfo_init);
module_exit(cpuinfo_exit);