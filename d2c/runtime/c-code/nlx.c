#include <stdlib.h>
#include "config.h"
#include "runtime.h"
#include <setjmp.h>

/*
 * We implement catch / throw here via setjmp / longjmp.
 * Unfortunately, setjmp and longjmp exchange data via
 * a 32 bit integer on most 64 bit platforms, so we
 * can not just send back a pointer to the stack when
 * we throw. We work around this by sending back the
 * difference between the 2 stack pointers instead.
 *
 * As a further complication, passing 0 to longjmp results
 * in a 1 being returned from setjmp, so we bias the result
 * by +1 to work around that (we never need to send -1
 * through the longjmp).
 */

#if defined(HAVE_SIGSETJMP) && defined(HAVE_SIGLONGJMP)
#define JMP_BUF sigjmp_buf
#define SETJMP(env) sigsetjmp(env, 0)
#define LONGJMP(env, val) siglongjmp(env, val)
#else
#define JMP_BUF jmp_buf
#define SETJMP(env) setjmp(env)
#define LONGJMP(env, val) longjmp(env, val)
#endif

descriptor_t *catch(descriptor_t *(*fn)(descriptor_t *sp, void *state,
                                        heapptr_t body_func),
                    descriptor_t *sp, heapptr_t body_func)
{
    JMP_BUF state;
    int rc;

    if ((rc = SETJMP(state))) { /* This _is_ an assignment */
      /* longjmp was called, return stack_top */
      /* See comment above for explanation of the -1 bias. */
      return (descriptor_t *)(sp + rc - 1);
    } else {
      /* first pass */
      return fn(sp, state, body_func);
    }
}

void throw(void *state, descriptor_t *sp, descriptor_t *stack_top)
{
    /* See comment above for explanation of the +1 bias. */
    LONGJMP(state, (int)(stack_top - sp + 1));
}
