/*
  THIS CODE IS NOT MINE.

  I DUMBED DOWN THIS VERSION:

              https://github.com/nonpop/xkblayout-state

  TO USE WITH THIS SCRIPT:

              https://github.com/matthmr/side/blob/master/statusbar
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <X11/Xlib.h>
#include <X11/XKBlib.h>

// boilerplate stuff {{
#ifndef false
#  define false '\0'
#endif

#ifndef true
#  define true '\1'
#endif

#ifndef NULL
#  define NULL ((void*)0x0)
#endif

#ifndef ALPHA
#  define ALPHA(x) (((x) >= 'a' && (x) <= 'z') || ((x) >= 'A' && (x) <= 'Z'))
#endif

#ifndef NUM
#  define NUM(x) ((x) >= '0' && (x) <= '9'))
#endif

#ifndef BIT
#  define BIT(x) (1 << (x))
#endif
// }}

#ifndef BYTES
#  define BYTES 16
#endif

typedef char bool;
typedef unsigned int uint;

// X11 stuff {{
static Display* dpy;
static int devid, groupcnt;
static int major = XkbMajorVersion, minor = XkbMinorVersion;
// }}

// kbdlayout stuff {{
static char * symname = NULL,
            * symnamestr = NULL, 
            * varname = NULL;
// }}

static bool init_kbd(void) {
  bool ret = true;

  XkbDescRec* kbddesc = XkbAllocKeyboard();

  if (!kbddesc) {
    XFree(kbddesc);    
    return false;
  }

  kbddesc->dpy = dpy;

  if (devid != XkbUseCoreKbd) {
    kbddesc->device_spec = devid;
  }

  XkbGetControls(dpy, XkbAllControlsMask, kbddesc);
  XkbGetNames(dpy, XkbSymbolsNameMask, kbddesc);
  XkbGetNames(dpy, XkbGroupNamesMask, kbddesc);

  if (!kbddesc->names) {
    ret = false;
    goto empty;
  }

  // count groups {{
  const Atom* groupsrc = kbddesc->names->groups;
  if (!kbddesc->ctrls) {
    groupcnt = kbddesc->ctrls->num_groups;
  }
  else {
    groupcnt = 0;
    while (groupcnt < XkbNumKbdGroups && groupsrc[groupcnt] != None) {
      groupcnt++;
    }
  }
  groupcnt = !groupcnt? 1: groupcnt;
  // }}

  // get symbol string {{
  Atom symatom = kbddesc->names->symbols;
  if (symatom != None) {
    char* _symnamestr = XGetAtomName(dpy, symatom);
    symnamestr = strdup(_symnamestr);
    XFree(_symnamestr);
    if (!symnamestr && (!symnamestr[0] || symnamestr[0] == '\n')) {
      ret = false;
      goto empty;
    }
  }
  else {
    ret = false;
    goto empty;
  }
  // }}

empty:
  XFree(kbddesc);
  XkbFreeControls(kbddesc, XkbAllControlsMask, true);
  XkbFreeNames(kbddesc, XkbSymbolsNameMask, true);
  XkbFreeNames(kbddesc, XkbGroupNamesMask, true);
  return ret;
}

static int init(void) {
  int _ = 0, reascode = 0;

  devid = XkbUseCoreKbd;

  dpy = XkbOpenDisplay("", &_, &_, &major, &minor, &reascode);

  if (reascode != XkbOD_Success || !init_kbd()) {
    return -1;
  }

  return 0;
}

static int getcgroup(void) {
  XkbStateRec stat;
  XkbGetState(dpy, devid, &stat);
  return stat.group;
}

typedef enum {
  LOCK_COL_GROUP = BIT(0),
} preamble_lock;

static uint preamblepos = 0;

static void preamble_tok(int cgroup, char* symnamestr) {
  char c;
  uint i = -1u;
  
  preamble_lock lock = 0;

  uint groupn = 0;
  uint ll = 0;

  // ignore the first entry
  while (++i, (c = symnamestr[i])) {
    if (c == '+') {
      ll = (i+1);
      break;
    }
  }

  while (++i, (c = symnamestr[i])) {
    // secondary+ fields
    if (lock & LOCK_COL_GROUP) {
      ll++;
      if (c == '+') {
        groupn++;
        if (groupn == cgroup) {
          goto done;
        }
      }
    }

    // primary fields
    else if (c == '+') {
      if (groupn == cgroup) {
        goto done;
      }
      groupn++;
      ll = (i+1);
    }
    else if (c == ':') {
      lock |= LOCK_COL_GROUP;
      if (groupn == cgroup) {
        goto done;
      }
      ll = (i+1);
    }
  }

done:
  preamblepos = ll;
  return;
}

typedef enum {
  SYM = BIT(0),
  VAR = BIT(1),
} tok_mask;

static char* tok(int cgroup, char* symnamestr, tok_mask mask, char* buf) {
  char c;
  uint i = preamblepos;

  uint ll = i, lu = i;
  uint am;

  if (mask & VAR) {
    // look for the opening paren
    while (++i, (c = symnamestr[i])) {
      if (c == '(') {
        ll = (i+1);
        break;
      }
      // abort it
      else if (c == ':' || c == '+') {
        return NULL;
      }
    }
    
    // then the closing one
    while (++i, (c = symnamestr[i])) {
      if (c == ')') {
        lu = i;
        break;
      }
    }
  }

  else if (mask & SYM) {
    while (++i, (c = symnamestr[i])) {
      if (c == '(' || c == ':' || c == '+') {
        lu = i;
        break;
      }
    }
  }

  am = lu - ll;

  buf = malloc((am+1)*sizeof (char));
  buf = strndup(&symnamestr[ll], am);

  return buf;
}

static inline char* getsymname(int cgroup, char* symnamestr, char* buf) {
  buf = tok(cgroup, symnamestr, SYM, buf);

  return buf;
}

static inline char* getvarname(int cgroup, char* symnamestr, char* buf) {
  buf = tok(cgroup, symnamestr, VAR, buf);

  return buf;
}

static int getlayout(void) {
  int cgroup = getcgroup();
  preamble_tok(cgroup, symnamestr);

  symname = getsymname(cgroup, symnamestr, symname);
  varname = getvarname(cgroup, symnamestr, varname);

  if (varname) {
    printf("%s-%s\n", symname, varname);
  }
  else {
    printf("%s\n", symname);
  }

  return 0;
}

int main(void) {
  int ret = init();

  if (ret >= 0) {
    (void) getlayout();
  }

  XCloseDisplay(dpy);

  if (symname) {
    free(symname);
  }
  if (varname) {
    free(varname);
  }
  if (symnamestr) {
    free(symnamestr);
  }

  return ret; 
}
