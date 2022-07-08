#!/bin/bash

#######################################
# helper functions                    #
#######################################

# show help information
help() {
  echo "Convert Pointwise meshes to Fluent msh files."
  echo
  info "Usage: pw2msh.sh [-o] FILENAME"
  echo
  echo "Options:"
  echo "  -o      Overwrite existing files"
  echo
}

# show info
info () {
  # set color variables
  red='\033[0;31m'
  clear='\033[0m'

  printf "${red}$1\n${clear}"
}

#######################################
# input                               #
#######################################
# default options
default_overwrite=false # -o

while getopts ":o" opt; do
  case $opt in
    o) overwrite=true ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1 ;;
  esac
done
shift $((OPTIND-1))

if [ -z $overwrite ]; then
  overwrite=$default_overwrite
fi

# load pointwise and ansys
if command -v module > /dev/null; then
  module load pointwise/18.4R4
  module load ansys
fi

# Pointwise filename
name=$1
# show help information when no filename is passed
[ "$name" == "" ] && help && exit
# remove extension in the filename
name="${name%.*}" 

# check if pointwise and/or ansys is available
if ! command -v pointwise > /dev/null; then
  info "pointwise not found!"
  exit 1
fi

if ! command -v icemcfd > /dev/null; then
  info "icemcfd not found!"
  exit 1
fi

# check if .pw file exists
if [ ! -f "${name}.pw" ]; then
  info "${name}.pw not found!" 
  exit 1
fi

#######################################
# .pw to .cas                         #
#######################################
# convert .pw to .cas (also generate separate .pw files when there are multiple parts)
info "Converting ${name}.pw to .cas file(s)..."
id=1
while true; do
  # check if .cas file already exists
  if [ -f "${name}_part${id}.cas" ]; then
    info "${name}_part${id}.cas already exists."
    if [ "$overwrite" = false ]; then
      ((id++))
      continue
    else
      info "${name}_part${id}.cas will be overwritten."
    fi
  elif [ -f "${name}.cas" ] && [ $id == 1 ]; then
    info "${name}.cas already exists."
    if [ "$overwrite" = false ]; then
      break
    else
      info "${name}.cas will be overwritten."
    fi
  fi

  # convert .pw to .cas
  pointwise -b pw2cas.glf ${name} "FLUID${id}" || exit 1

  # check if the last part has been processed
  if [ -f "${name}.cas" ]; then
    info "${name}.cas is generated."
    break
  elif [ -f "${name}_part${id}.cas" ]; then
    info "${name}_part${id}.cas is generated."
  else
    break
  fi

  # next part
  ((id++))
done

#######################################
# .cas to .msh                        #
#######################################
# loop through all .cas files
for filename in ${name}*.cas; do
  [ -f "${filename}" ] || continue
  filename="${filename%.*}" # remove extension
  export CASE_FILENAME=$filename # set environment variable

  # check if .msh file already exists
  if [ -f "${filename}.msh" ]; then
    info "${filename}.msh already exists."
    if [ "$overwrite" = false ]; then
      continue
    else
      info "${filename}.msh will be overwritten."
    fi
  fi

  # convert .cas to .msh
  info "Converting ${filename}.cas to ${filename}.msh..."
  icemcfd -batch -script cas2msh.tcl ${filename}

  if [ -f "${filename}.msh" ]; then
    info "${filename}.msh is generated."
  fi

done

# clean temporary files
rm -f *.fbc* *.atr *.prj *.uns *.tin *.blk
