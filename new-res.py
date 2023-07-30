#!/usr/bin/python3

import sys
import subprocess

#### UTILS

WIDTH = lambda x: x[0]
HEIGHT = lambda x: x[1]

#### NR

nr_mediainfo = "mediainfo"

def nr_help():
  print("Usage:       new-res.py FILE RATIO")
  print("Description: Output the new resolution that FILE should have given an\
 aspect RATIO ")
  print("Note:        This script depends on `mediainfo' being available on the\
 system")

def nr_out_to_list(proc_list):
  """
  Fixes out the output of `mediainfo', while also creating a list of form
  `[WIDTH, HEIGHT]' for following functions
  """
  width    = WIDTH(proc_list)
  height   = HEIGHT(proc_list)
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

def nr_scale(base_res, target_ratio):
  """
  Scales `base_res' given `target_ratio'
  """
  bwidth  = WIDTH(base_res)
  bheight = HEIGHT(base_res)

  rwidth  = WIDTH(target_ratio)
  rheight = HEIGHT(target_ratio)

  fwidth  = bwidth // rwidth
  fheight = bheight // rheight

  res     = map(lambda e: e*(fwidth if fheight > fwidth else fheight),\
                [rwidth, rheight])

  return [i for i in res]

#### MAIN

def nr_main(nr_file, nr_target_ratio):
  proc_stdout = subprocess.run([nr_mediainfo, nr_file], capture_output=True)\
                          .stdout.decode("utf-8").split("\n")
  proc_filter = filter(lambda line:\
                       line.startswith("Width") or line.startswith("Height"),
                       proc_stdout)

  proc_stdout_wh = [f_line.split(":")[1].split(" ")[1:-1] \
                    for f_line in proc_filter]

  nr_base_res = nr_out_to_list(proc_stdout_wh)

  horizontal  = WIDTH(nr_target_ratio) > HEIGHT(nr_target_ratio)

  if horizontal:
    if HEIGHT(nr_base_res) > WIDTH(nr_base_res):
      print("[ !! ] Image is not fit horizontal monitor")
      return 1
  else:
    if WIDTH(nr_base_res) > HEIGHT(nr_base_res):
      print("[ !! ] Image is not fit horizontal monitor")
      return 1

  print(nr_scale(nr_base_res, nr_target_ratio))

def main():
  nr_file  = None
  nr_ratio = None
  argv     = sys.argv[1:]

  for arg in argv:
    if arg == "--help" or arg == "-h":
      nr_help()
      return 0
    if nr_file is None:
      nr_file  = arg
    elif nr_ratio is None:
      nr_ratio = arg

  if nr_file is None:
    print("[ !! ] Missing FILE")
    return 1

  if nr_ratio is None:
    print("[ !! ] Missing RATIO")
    return 1

  nr_ratio_list = nr_ratio.split("x")

  if nr_ratio_list == nr_ratio: # didn't split
    print("[ !! ] Wrong format for RATIO. Use <WIDTH>x<HEIGHT>")
    return 1

  nr_target_ratio = [int(e) for e in nr_ratio_list]
  nr_main(nr_file, nr_target_ratio)

if __name__ == "__main__":
  main()
