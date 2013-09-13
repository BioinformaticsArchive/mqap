/******************************************************************************/
/*Program: pdb2radiusMycenter                                                         */
/*Author: Ting Wang                                                           */
/*Email: twang@ucdavis.edu                                                    */
/*Institution: University of California at Davis                              */
/*Date: Dec 17, 2007                                                          */
/*Purpose: calculate radius of a protein in a pdb file                        */
/*PDB format: ATOM=column 1-4;  N(C,O,..)=column14;  XYZ=column 31-54         */
/* only lines starting with ATOM are considered                               */
/*COMPILATION: cc -o pdb2radiusMycenter pdb2radiusMycenter.c  -lm             */
/*USAGE: >pdb2radiusMycenter centerX centerY centerZ protein.pdb              */
/*        output: radius X Y Z = diameter= X Y Z        */
/******************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MAX_NATOM 20000 /*Maximum number of atoms */

int main (
	int argc,         /* Number of args */
	char ** argv)     /* Arg list       */
{
	FILE  *fpdb;
	float X,Y,Z,COM_X,COM_Y,COM_Z,R_X,R_Y,R_Z;
	int TOTAL_ATOM=0;
        char line[100];
	
        if((fpdb = fopen(argv[1] , "r"))==NULL)
	  {printf("PDB file can not be opened .\n");exit(0);}

	COM_X=atof(argv[2]); COM_Y=atof(argv[3]); COM_Z=atof(argv[4]);
	
	R_X=R_Y=R_Z=0.0;
	while(fgets(line,100,fpdb))
	{
	   if(strncmp(line,"ATOM",4)==0||strncmp(line,"HETATM",6)==0){
	      
	      if(sscanf(line+30,"%f%f%f",&X,&Y,&Z)!=3)
	      {  printf("XYZ is not complete"); exit(0);}	
       	     /* printf("X Y Z = %f %f %f\n",X,Y,Z);*/
	     if (R_X < fabs(X-COM_X)) R_X=fabs(X-COM_X);
	     if (R_Y < fabs(Y-COM_Y)) R_Y=fabs(Y-COM_Y);
	     if (R_Z < fabs(Z-COM_Z)) R_Z=fabs(Z-COM_Z);	            
	   }
   	}/* end of while fgets() */
	
 	printf("Radius X Y Z = %10.3f %10.3f %10.3f\n",R_X,R_Y,R_Z);
	printf("Diameter X Y Z = %10.3f %10.3f %10.3f\n",R_X*2,R_Y*2,R_Z*2);
        fclose(fpdb);

 return(1);
}

