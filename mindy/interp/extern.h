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
* This file exports definitions for support of raw C pointers.
*
\**********************************************************************/


struct c_pointer {
    obj_t class;
    void *pointer;
};

#define C_PTR(o) obj_ptr(struct c_pointer *, o)

struct symtab {
    char *name;
    void *ptr;
};

struct foreign_file {
    obj_t class;
    obj_t file_name;		/* relocatable object file */
    int sym_count;
    int extra_size;
    struct symtab syms[1];
};

#define FOREIGN_FILE(o) obj_ptr(struct foreign_file *, o)

extern obj_t obj_CPointerClass;
extern obj_t /* <foreign-file> */ mindy_explicit_syms;
extern obj_t obj_ForeignFileClass;
extern obj_t obj_ArchivedFileClass;

extern obj_t make_c_pointer(obj_t /* <static-pointer-class> */ cls, void *ptr);
extern void *get_c_object(obj_t obj);
extern obj_t convert_c_object(obj_t class, void *obj, boolean miss_ok);
extern int scav_c_pointer(struct object *obj);
extern obj_t trans_c_pointer(obj_t cptr);
