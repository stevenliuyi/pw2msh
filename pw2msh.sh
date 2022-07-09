#!/bin/bash
#######################################
# pw2msh - Yi Liu 2022
# 
# This script can convert Pointwise
# meshes to Fluent msh files and also
# generate msh2cdp.in
#######################################

#######################################
# helper functions                    #
#######################################

# show help information
help() {
  echo
  echo "Convert Pointwise meshes to Fluent msh files."
  echo
  info "Usage: pw2msh.sh [-o|p|i|c] FILENAME"
  echo
  echo "Options:"
  echo "  -o      Overwrite existing files"
  echo "  -p      Only convert .pw to .cas (using Pointwise)"
  echo "  -i      Only convert .cas to .msh (using ICEM)"
  echo "  -c      Also generate msh2cdp.in"
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
default_pw_only=false # -p
default_icem_only=false # -i
default_cdp=false # -c

while getopts ":opic" opt; do
  case $opt in
    o) overwrite=true ;;
    p) pw_only=true ;;
    i) icem_only=true ;;
    c) cdp=true ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1 ;;
  esac
done
shift $((OPTIND-1))

[ -z $overwrite ] && overwrite=$default_overwrite
[ -z $pw_only ] && pw_only=$default_pw_only
[ -z $icem_only ] && icem_only=$default_icem_only
[ -z $cdp ] && cdp=$default_cdp

if [ "$pw_only" = true ] && [ "$icem_only" = true ]; then
  # set both pw_only and icem_only to be false when both -p and -i are present
  pw_only=false
  icem_only=false
fi

# load pointwise and ansys
if command -v module > /dev/null; then
  [ "$icem_only" = false ] && module load pointwise/18.4R4
  [ "$pw_only" = false ] && module load ansys
fi

# filename
name=$1
# show help information when no filename is passed
[ "$name" == "" ] && help && exit
# remove extension in the filename
name="${name%.*}" 

# check if pointwise and/or ansys is available
if ! command -v pointwise > /dev/null; then
  ([ "$icem_only" = false ] || [ "$cdp" = true ]) && info "pointwise not found!" && exit 1
fi

if ! command -v icemcfd > /dev/null; then
  [ "$pw_only" = false ] && info "icemcfd not found!" && exit 1
fi

# check if .pw file exists
if [ ! -f "${name}.pw" ] && [ "$icem_only" = false ]; then
  info "${name}.pw not found!" 
  exit 1
fi

#######################################
# .pw to .cas                         #
#######################################
# convert .pw to .cas (also generate separate .pw files when there are multiple parts)
if [ "$icem_only" = false ]; then
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
	rm -f ${name}_part${id}.cas
        info "${name}_part${id}.cas will be overwritten."
      fi
    elif [ -f "${name}.cas" ] && [ $id == 1 ]; then
      info "${name}.cas already exists."
      if [ "$overwrite" = false ]; then
        break
      else
	rm -f ${name}.cas
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
fi

#######################################
# .cas to .msh                        #
#######################################
if [ "$pw_only" = false ]; then
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
	rm -f ${filename}.msh
        info "${filename}.msh will be overwritten."
      fi
    fi
  
    # convert .cas to .msh
    info "Converting ${filename}.cas to ${filename}.msh..."
    icemcfd -batch -script cas2msh.tcl ${filename}
  
    if [ -f "${filename}.msh" ]; then
      info "${filename}.msh is generated."
    else
      info "Error occurred when generating ${filename}.msh."
    fi
  
  done

  # clean temporary files
  rm -f *.fbc* *.atr *.prj *.uns *.tin *.blk
fi

#######################################
# msh2cdp.in                          #
#######################################
if [ "$cdp" = true ]; then
  rm -f msh2cdp.in
  info "Generating msh2cdp.in..."

  pointwise -b msh2cdp_in.glf ${name} || exit 1

  [ -f "msh2cdp.in" ] && info "msh2cdp.in is generated."
fi
