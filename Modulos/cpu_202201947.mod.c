#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0xe8213e80, "_printk" },
	{ 0xd272d446, "__x86_return_thunk" },
	{ 0x20c53997, "single_open" },
	{ 0xac3f5c25, "seq_printf" },
	{ 0x700e1b89, "remove_proc_entry" },
	{ 0xcb4b678c, "seq_read" },
	{ 0x8f4454bf, "seq_lseek" },
	{ 0xfeb2ab30, "single_release" },
	{ 0xd272d446, "__fentry__" },
	{ 0x992ecee6, "kernel_cpustat" },
	{ 0x5ae9ee26, "__per_cpu_offset" },
	{ 0xa9cd46c3, "proc_create" },
	{ 0xc773217c, "module_layout" },
};

static const u32 ____version_ext_crcs[]
__used __section("__version_ext_crcs") = {
	0xe8213e80,
	0xd272d446,
	0x20c53997,
	0xac3f5c25,
	0x700e1b89,
	0xcb4b678c,
	0x8f4454bf,
	0xfeb2ab30,
	0xd272d446,
	0x992ecee6,
	0x5ae9ee26,
	0xa9cd46c3,
	0xc773217c,
};
static const char ____version_ext_names[]
__used __section("__version_ext_names") =
	"_printk\0"
	"__x86_return_thunk\0"
	"single_open\0"
	"seq_printf\0"
	"remove_proc_entry\0"
	"seq_read\0"
	"seq_lseek\0"
	"single_release\0"
	"__fentry__\0"
	"kernel_cpustat\0"
	"__per_cpu_offset\0"
	"proc_create\0"
	"module_layout\0"
;

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "31A9062EBAABFCFDE6B9FFB");
