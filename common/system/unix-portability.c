#include "config.h"
#include "unix-portability.h"

int system_errno(void)
{
  return errno;
}

void system_errno_setter(int new_errno)
{
  errno = new_errno;
}

int
system_localtime(time_t clock, struct tm *result, long *gmtoff,
	     const char **zone) {
  struct tm *p_tm;
#ifdef HAVE_LOCALTIME_R
  p_tm = localtime_r(&clock, result);
#else
  p_tm = localtime(&clock);
  *result = *p_tm;
#endif

#if defined(HAVE_TM_GMTOFF)
  *gmtoff = result->tm_gmtoff;
#elif defined(HAVE_DAYLIGHT)
  *gmtoff = -timezone;
#elif defined(HAVE_CYGNUS_DAYLIGHT)
  *gmtoff = -_timezone;
#else
#error "No implementation provided for obtaining timezone offset"
#endif

#if defined(HAVE_STRUCT_TM_TM_ZONE)
  *zone = result->tm_zone;
#elif defined(HAVE_DAYLIGHT)
  *zone = tzname[daylight];
#elif defined(HAVE_CYGNUS_DAYLIGHT)
  *zone = tzname[_daylight];
#else
#error "No implementation provided for obtaining timzeone name"
#endif

  return 0;
}

int system_open(const char *path, int oflag, mode_t mode)
{
#ifdef O_BINARY
  oflag |= O_BINARY;
#endif
  return (oflag & O_CREAT) ? open(path, oflag, mode) : open(path, oflag);
}

void system_st_birthtime(struct stat *st, struct timeval *tp)
{
#if defined(HAVE_STRUCT_STAT_ST_BIRTHTIMESPEC)
  tp->tv_sec = st->st_birthtimespec.tv_sec;
  tp->tv_usec = st->st_birthtimespec.tv_nsec / 1000;
#elif defined(HAVE_STRUCT_STAT_ST_CTIMESPEC)
  tp->tv_sec = st->st_ctimespec.tv_sec;
  tp->tv_usec = st->st_ctimespec.tv_nsec / 1000;
#elif defined(HAVE_STRUCT_STAT_ST_CTIM)
  tp->tv_sec = st->st_ctim.tv_sec;
  tp->tv_usec = st->st_ctim.tv_nsec / 1000;
#else
  tp->tv_sec = st->st_ctime;
  tp->tv_usec = 0;
#endif
}

void system_st_atime(struct stat *st, struct timeval *tp)
{
#if defined(HAVE_STRUCT_STAT_ST_ATIMESPEC)
  tp->tv_sec = st->st_atimespec.tv_sec;
  tp->tv_usec = st->st_atimespec.tv_nsec / 1000;
#elif defined(HAVE_STRUCT_STAT_ST_ATIM)
  tp->tv_sec = st->st_atim.tv_sec;
  tp->tv_usec = st->st_atim.tv_nsec / 1000;
#else
  tp->tv_sec = st->st_atime;
  tp->tv_usec = 0;
#endif
}

void system_st_mtime(struct stat *st, struct timeval *tp)
{
#if defined(HAVE_STRUCT_STAT_ST_MTIMESPEC)
  tp->tv_sec = st->st_mtimespec.tv_sec;
  tp->tv_usec = st->st_mtimespec.tv_nsec / 1000;
#elif defined(HAVE_STRUCT_STAT_ST_MTIM)
  tp->tv_sec = st->st_mtim.tv_sec;
  tp->tv_usec = st->st_mtim.tv_nsec / 1000;
#else
  tp->tv_sec = st->st_mtime;
  tp->tv_usec = 0;
#endif
}

