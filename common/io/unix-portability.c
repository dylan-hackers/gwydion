#include "config.h"
#include "unix-portability.h"

#include <sys/types.h>
#include <sys/stat.h>

int io_errno(void)
{
  return errno;
}

int io_fd_info(int fd, int *seekable_p) {
  struct stat st;
  if(fstat(fd, &st) < 0)
    return -1;

  *seekable_p = ((st.st_mode & S_IFMT) == S_IFREG);
    
#ifdef HAVE_STRUCT_STAT_ST_BLKSIZE
  return st.st_blksize;
#else
  return 8192;			/* must be a power of 2 */
#endif
}

