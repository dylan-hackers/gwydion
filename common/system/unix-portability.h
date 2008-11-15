#include <sys/utsname.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <fcntl.h>
#include <time.h>
#include <pwd.h>
#include <grp.h>
#include <dirent.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#ifndef _PC_SYMLINK_MAX
#define _PC_SYMLINK_MAX _PC_PATH_MAX
#endif

#ifndef O_SYNC
#define O_SYNC 0
#endif

int system_errno(void);
void system_errno_setter(int);

int system_localtime(time_t clock, struct tm *result, long *gmtoff,
		     const char **zone);

int system_open(const char *path, int oflag, mode_t mode);

void system_st_birthtime(struct stat *st, struct timeval *tp);
void system_st_atime(struct stat *st, struct timeval *tp);
void system_st_mtime(struct stat *st, struct timeval *tp);

int system_spawn(char *program, char **argv, char **envp, char *dir,
		 int inherit_console,
		 int stdin_fd, int stdout_fd, int stderr_fd);

extern char **environ;
