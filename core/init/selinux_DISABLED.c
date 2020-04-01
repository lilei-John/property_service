#include <unistd.h>
#include "selinux/selinux_internal.h"
#include <stdlib.h>
#include <errno.h>

void freecon(security_context_t con)
{
	//
}


int is_selinux_enabled(void)
{
	return 0;
}

#define setselfattr_def(fn, attr) \
	int set##fn(const security_context_t c) \
	{ \
		return 0; \
	}

setselfattr_def(con, current)
setselfattr_def(execcon, exec)
setselfattr_def(fscreatecon, fscreate)
setselfattr_def(sockcreatecon, sockcreate)
setselfattr_def(keycreatecon, keycreate)

