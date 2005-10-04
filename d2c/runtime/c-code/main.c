#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>

#include "config.h"
#include "runtime.h"

#if defined(HAVE_GC_H)
#include <gc.h>
#elif defined(HAVE_GC_GC_H)
#include <gc/gc.h>
#endif

int application_argc;
char **application_argv;

void GD_NORETURN not_reached(void)
{
    fprintf(stderr, "entered a branch that supposedly never could be.\n");
    abort();
}

/* Microsoft Visual C++ refuses to allow main() to come from a
   library.  Thus, we need to put main() in inits.c and have it simply
   call this function.  
   */
void real_main(int argc, char *argv[])
{
    descriptor_t *sp;

    GC_INIT();

    sp = allocate_stack();

    /* Remember our arguments so we can support Harlequin-style
       application-name and application-arguments functions. Once we
       make these copies, we are no longer allowed to destructively
       modify argv. But this is Dylan--you should know better than
       to destructively modify things without express permission anyway. */
    application_argc = argc;
    application_argv = argv;

    /* Run all the top level initializations. */
    inits(sp, argc, argv);
}



#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_SYS_RESOURCE_H
#include <sys/resource.h>
#endif

#if HAVE_GETRLIMIT
void no_core_dumps(void)
{
  struct rlimit lim;
  getrlimit(RLIMIT_CORE, &lim);
  lim.rlim_cur = 0;
  setrlimit(RLIMIT_CORE, &lim);
  lim.rlim_cur = RLIM_INFINITY;
  lim.rlim_max = RLIM_INFINITY;
  setrlimit(RLIMIT_STACK, &lim);
}
#else
void no_core_dumps(void)
{
  /* other platforms don't core nicely, if at all */
}
#endif

#ifdef HAVE_GETRUSAGE
long *cpu_time(void)
{
  long *retval = (long *) allocate(2 * sizeof(long));
  struct rusage ru;
  if(getrusage(RUSAGE_SELF, &ru) == 0) {
    retval[0]
      = ru.ru_utime.tv_sec + ru.ru_stime.tv_sec
      + (ru.ru_utime.tv_usec + ru.ru_stime.tv_usec) / 1000000L;
    retval[1] = (ru.ru_utime.tv_usec + ru.ru_stime.tv_usec) % 1000000L;
  } else {
    retval[0] = retval[1] = 0;
  }
  return retval;
}
#else
long *cpu_time(void)
{
  long *retval = (long *) allocate(2 * sizeof(long));
  clock_t runtime = clock();
  if(runtime >= 0) {
    retval[0] = (runtime / CLOCKS_PER_SEC);
    retval[1] = (runtime % CLOCKS_PER_SEC) * 1000000L / CLOCKS_PER_SEC;
  } else {
    retval[0] = retval[1] = 0;
  }
  return retval;
}
#endif
