#ifndef __CFMAKERAW__
#define __CFMAKERAW__

#include <termios.h>

#include "config.h"

#if !HAVE_DECL_CFMAKERAW
extern int cfmakeraw (struct termios *);
#endif

#endif // __CFMAKERAW__
