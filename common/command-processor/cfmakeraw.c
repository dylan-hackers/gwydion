#include "config.h"

#if !HAVE_DECL_CFMAKERAW

#include "cfmakeraw.h"
#include <errno.h>

int cfmakeraw (struct termios *termios_p)
{
    if (!termios_p) {
        errno = EINVAL;
        return -1;
    }

    termios_p->c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP
                            |INLCR|IGNCR|ICRNL|IXON);
    termios_p->c_oflag &= ~OPOST;
    termios_p->c_lflag &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);
    termios_p->c_cflag &= ~(CSIZE|PARENB);
    termios_p->c_cflag |= CS8;

    return 0;
}

#endif
