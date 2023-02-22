#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define NEXT_LINE "\033[1A\033[0G"

// YYYYMMDDhhmmss
static struct tm* lt;
static time_t t, *tp = &t;

static void ljac_fmt(const char* fmt, struct tm t) {
  t.tm_year += 1900;
  ++t.tm_mon;

  printf(fmt, t.tm_year, t.tm_mon, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec);
}

static void ljac(void) {
  for (;;) {
    t  = time(NULL);
    lt = localtime(tp);
    ljac_fmt("%d%02d%02d%02d%02d%02d\n" NEXT_LINE, *lt);
    sleep(1);
  }
}

int main(int argc, char** argv) {
  if (argc > 1) {
    const char* arg = argv[1];

    if (arg[0] == '-') {
      ++arg;
      if (strcmp(arg, "p") == 0) {
        t  = time(NULL);
        lt = localtime(tp);
        ljac_fmt("%d%02d%02d%02d%02d%02d\n", *lt);
        sleep(1);
      }
      else if (strcmp(arg, "h") == 0 ||
               strcmp(arg, "-help") == 0) {
        puts("Usage:       ljac [options]\n"
             "Description: Literally just a clock\n"
             "Options:\n"
             "  -p: print the current date before starting the loop");
        exit(1);
      }
    }
  }

  ljac();
  return 0;
}
