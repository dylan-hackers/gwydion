#include <unistd.h>
#include <string.h>
#include <errno.h>

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif

int io_errno(void);
int io_fd_info(int fd, int *seekable_p);
