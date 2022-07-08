## pw2msh

`pw2msh.sh` is a script to convert Pointwise meshes to Fluent mesh files. It first uses Pointwise to convert .pw file to Fluent .cas file, and then uses ICEM to convert .cas file to .msh file.    

If the mesh needs to be splitted into several parts, each part should have volume condition set in Pointwise with names "FLUID1", "FLUID2", etc. Then the script can automatically generate mesh files for each part, and set boundary conditions of the interfaces between the parts with names "RECONN1", "RECONN2", etc. If no mesh splitting is needed, just name the volume conditon as "FLUID".
