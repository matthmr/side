// fast statusbar for tmux
// call within tmux
// #(mpc | tmux-statusbar #{client_width} #{client_user}@#h %Y%m%d %a %I%M)

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define PAGE 4096

static char input[PAGE];
static char* line;

static size_t get_uptime(char** ret) {
  FILE* uptime = fopen("/proc/uptime", "r");

  size_t uptime_read = fread(input, sizeof(input), sizeof(*input), uptime);

  size_t i = 0, p = 0;

  for (; input[i] != ' '; ++i) {
    if (input[i] == '.') {
      p = i;
    }
  }

  input[p? p: i] = '\0';

  fclose(uptime);

  ////

  int uptime_sec = atoi(input);

  int uptime_hrs = uptime_sec / 3600;
  int uptime_min = (uptime_sec / 60) % 60;

  return asprintf(ret, "%02d%02d", uptime_hrs, uptime_min);
}

static size_t get_mpd(char** ret, size_t avail) {
  char* read = fgets(input, (avail + 2), stdin);

  // /^volume:/: don't have any song
  if (strncmp("volume:", read, sizeof("volume")) == 0) {
    return 0;
  }

  size_t read_len = strlen(read);

  if (read[read_len-1] == '\n') {
    read[read_len-1] = '\0';
    --read_len;
  }

  // cannot fit whole: truncate
  if (read_len > avail) {
    read[avail] = '\0';
    read[avail-1] = '.';
    read[avail-2] = '.';
    read[avail-3] = '.';
  }

  return asprintf(ret, "%s", read);
}

////////////////////////////////////////////////////////////////////////////////

int main(int argc, char** argv) {
  char* uptime = NULL, * user_host = NULL, * date = NULL, * mpd = NULL;
  size_t uptime_len = 0, user_host_len = 0, date_len = 0, mpd_len = 0;

  size_t output_width = 0;

  uptime_len = get_uptime(&uptime);

  for (size_t i = 1; i < argc; ++i) {
    switch (i) {
    case 1: // width
      output_width = (atoi(argv[i]) + 1)*3/4;
      break;
    case 2: // user@host
      user_host = argv[i];
      user_host_len = strlen(user_host);
      break;
    case 3: // date
      date = argv[i];
      date_len = strlen(date);
      break;
    }
  }

  // ` A | B | C ' (+8)
  size_t default_status_len = user_host_len + uptime_len + date_len + 8;

  // ` a... |S': minimum possible case
  if (default_status_len + 7 >= output_width) {
    goto without_mpd;
  }

  // paddings
  default_status_len += 3;

  mpd_len = get_mpd(&mpd, (output_width - default_status_len));

  if (!mpd_len) {
without_mpd:
    printf(" %s | %s | %s ", user_host, uptime, date);
  }
  else {
    printf(" %s | %s | %s | %s ", mpd, user_host, uptime, date);
  }

  return 0;
}
