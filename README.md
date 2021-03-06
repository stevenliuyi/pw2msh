## pw2msh

`pw2msh.sh` is a script to convert Pointwise meshes to Fluent mesh files. It first uses Pointwise to convert .pw file to Fluent .cas file, and then uses ICEM to convert .cas file to .msh file.

If the mesh needs to be splitted into several parts, each part should have volume condition set in Pointwise with names `FLUID1`, `FLUID2`, etc. Then the script can automatically generate mesh files for each part, and set boundary conditions of the interfaces between the parts with names `RECONN1`, `RECONN2`, etc. The mesh files are named as `FILENAME_part1.pw`, `FILENAME_part2.pw`, etc. If no mesh splitting is needed, just name the volume conditon as `FLUID`.

The script can also generate `msh2cdp.in` for CDP solver's msh2cdp preprocessor when the flag `-c` is turned on. It automatically handles the splitted meshes, and can also handle periodic conditions when periodic BC pairs are named as `Z0`, `Z1`, etc.

Run `./pw2msh.sh` to see the syntax and all available options.
