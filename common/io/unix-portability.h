#include <unistd.h>
#include <string.h>
#include <errno.h>

int io_errno(void);
int io_fd_info(int fd, int *seekable_p);
