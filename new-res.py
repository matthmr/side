#!/usr/bin/python3

import sys
import subprocess
from fractions import Fraction

#### NR

nr_mediainfo = "mediainfo"

def nr_help():
  print("Usage:       new-res.py FILE FACTOR")
  print("Description: Output the new resolution that FILE should have given a\
factor")
  print("Note:        This script depends on `mediainfo' being available on the\
system")

def nr_out_to_list(proc_list):
  width    = proc_list[0]
  height   = proc_list[1]
  width_r  = 0
  height_r = 0

  width.reverse()
  height.reverse()

  fac = 1
  for n in width:
    width_r = width_r + fac*int(n)
    fac     = fac * 1000

  fac = 1
  for n in height:
    height_r = height_r + fac*int(n)
    fac      = fac * 1000

  return [width_r, height_r]

def nr_norm(fac):
  if fac[1] > fac[0]:
    fac.reverse()

  return fac

def nr_scale(base_res, target_factor):
  target_factor_n = nr_norm(target_factor)

  t_width  = target_factor_n[0]
  t_height = target_factor_n[1]
  b_width  = base_res[0]
  b_height = base_res[1]

  frac     = Fraction(t_width, t_height)
  r_width  = frac.numerator
  r_height = frac.denominator

  _width   = b_width - (b_width % r_width)
  _fac     = _width // r_width
  _height  = r_height*_fac

  if _height > t_height:
    _height = b_height - (b_height % r_height)
    _fac    = _height // r_height
    _width  = r_width*_fac

  return [_width, _height]

#### MAIN

def nr_main(nr_file, nr_target_factor):
  proc_stdout = subprocess.run([nr_mediainfo, nr_file], capture_output=True)\
                          .stdout.decode("utf-8").split("\n")
  proc_filter = filter(lambda line:\
                       line.startswith("Width") or line.startswith("Height"),
                       proc_stdout)

  proc_stdout_wh = [f_line.split(":")[1].split(" ")[1:-1] \
                    for f_line in proc_filter]

  nr_base_res = nr_out_to_list(proc_stdout_wh)

  if nr_base_res[1] > nr_base_res[0] or \
     nr_target_factor[1] > nr_target_factor[0]:
    print("[ !! ] Image is not fit horizontal monitor")
    return 1

  print(nr_scale(nr_base_res, nr_target_factor))

def main():
  nr_file   = None
  nr_factor = None
  argv      = sys.argv[1:]

  for arg in argv:
    if arg == "--help" or arg == "-h":
      nr_help()
      return 0
    if nr_file is None:
      nr_file = arg
    elif nr_factor is None:
      nr_factor = arg

  if nr_file is None:
    print("[ !! ] Missing FILE")
    return 1

  if nr_factor is None:
    print("[ !! ] Missing FACTOR")
    return 1

  nr_factor_list = nr_factor.split("x")

  if nr_factor_list == nr_factor: # didn't split
    print("[ !! ] Wrong format for FACTOR. Use <WIDTH>x<HEIGHT>")
    return 1

  nr_target_factor = [int(e) for e in nr_factor_list]
  nr_main(nr_file, nr_target_factor)

if __name__ == "__main__":
  main()
