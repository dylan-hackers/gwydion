/**********************************************************************\
*
*  Copyright (c) 1994  Carnegie Mellon University
*  Copyright (c) 1998, 1999, 2000  Gwydion Dylan Maintainers
*  All rights reserved.
*  
*  Use and copying of this software and preparation of derivative
*  works based on this software are permitted, including commercial
*  use, provided that the following conditions are observed:
*  
*  1. This copyright notice must be retained in full on any copies
*     and on appropriate parts of any derivative works.
*  2. Documentation (paper or online) accompanying any system that
*     incorporates this software, or any part of it, must acknowledge
*     the contribution of the Gwydion Project at Carnegie Mellon
*     University, and the Gwydion Dylan Maintainers.
*  
*  This software is made available "as is".  Neither the authors nor
*  Carnegie Mellon University make any warranty about the software,
*  its performance, or its conformity to any specification.
*  
*  Bug reports should be sent to <gd-bugs@gwydiondylan.org>; questions,
*  comments and suggestions are welcome at <gd-hackers@gwydiondylan.org>.
*  Also, see http://www.gwydiondylan.org/ for updates and documentation. 
*
* This file implements getc.
*
\**********************************************************************/

#include "../compat/std-c.h"
#include "../compat/std-os.h"

#include "mindy.h"
#include "char.h"
#include "list.h"
#include "bool.h"
#include "thread.h"
#include "func.h"
#include "driver.h"
#include "error.h"
#include "def.h"
#include "fd.h"

#ifdef MACOS
#	include<console.h>
#endif

#ifdef HAVE_READLINE_H
#include <readline.h>
#include <history.h>
#endif
#ifdef HAVE_READLINE_READLINE_H
#include <readline/readline.h>
#include <readline/history.h>
#endif

static int mindy_getchar ()
{
    char c;
#ifdef MACOS		/* SIOUX can't read just one char??? */
	int num_read = 1;
	/*	Should loop calling SIOUXHandleOneEvent while no keydown. 
		Then get code direct from event, and repost to SIOUX.	
	*/
	c = getch();
	WriteCharsToConsole( &c, 1 );
	if( c == '\r' )
		c = '\n';
#else
    int num_read = mindy_read(0, &c, 1);
#endif
    if (num_read < 1)
	return EOF;
    else
	return c;
}

/* The buffer will always come back with a newline and null
   termination at the end, even if that means truncating some of the
   input
   */
int mindy_readline(char *prompt, char *buffer, int max_chars)
{
#ifdef HAVE_LIBREADLINE
    char *line = readline(prompt);

    if (line == NULL) {
	return 0;
    }
    
    if (*line != 0) 
	add_history(line);
    
    strncpy(buffer, line, max_chars - 2);
    buffer[max_chars-1] = 0;  /* Make sure its null terminated, on the
				 off chance the input string is max_chars-2
				 bytes long */
    strcat(buffer, "\n");
    return strlen(buffer);
#else
    int chars_read = 0;
    int c;
    
    printf(prompt);
    fflush(stdout);

    while ((c=mindy_getchar()) != EOF 
	   && c != '\n' 
	   && chars_read < max_chars-1) {
	buffer[chars_read] = c;
	chars_read++;
    }
    if (c == '\n') {
	buffer[chars_read] = c;
	chars_read++;
#ifdef WIN32
	/* On win32, we handle CRLFs by turning the CR byte into an LF,
	   and making the string one byte shorter.  (Which works because
	   the LF will be at the end of the string) */
	if (chars_read > 1 && buffer[chars_read - 2] == '\r') {
	    buffer[chars_read - 2] = buffer[chars_read - 1];
	    buffer[chars_read - 1] = 0;
	    chars_read--;
	}
#endif
    }
    buffer[chars_read] = 0;
    return chars_read;
#endif
}

static void getc_or_wait(struct thread *thread)
{
    if (FBUFEMPTYP(stdin) && !feof(stdin)) {
	int fd = fileno(stdin);
	int nfound = input_available(fd);

	if (nfound < 0) {
	    switch (errno) {
	      case EBADF:
		error("Tried to getc with stdin broken.");
	      case EINTR:
		wait_for_input(thread, fd, getc_or_wait);
	      case EINVAL:
		lose("select failed with EINVAL?");
	    }
	}
	else if (nfound == 0)
	    wait_for_input(thread, fd, getc_or_wait);
    }

    {
	obj_t *old_sp;
	int c = mindy_getchar();

	old_sp = pop_linkage(thread);

	if (c != EOF)
	    *old_sp = int_char(c);
	else
	    *old_sp = obj_False;

	thread->sp = old_sp + 1;

	do_return(thread, old_sp, old_sp);
    }
}

static obj_t dylan_getc(void)
{
    getc_or_wait(thread_current());
    go_on();
    /* go_on never returns. */
    lose("go_on actually returned?");
    return NULL;
}

void init_input_functions(void)
{
    define_function("getc", obj_Nil, FALSE, obj_False, FALSE,
		    obj_CharacterClass, dylan_getc);
}
