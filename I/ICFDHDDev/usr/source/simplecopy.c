/***************************************************************************/
/**                                                                       **/
/**                    Simple Copy Program                                **/
/**                                                                       **/
/**                Written by JF FABRE (fabre@supaero.fr)                 **/
/**                                                                       **/
/**                This program may be freely distibuted                  **/
/**                                                                       **/
/**             as long as this header is included unmodified             **/
/**                                                                       **/
/***************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include <dos/dos.h>
#include <exec/memory.h>
#include <exec/tasks.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <pragmas/dos_pragmas.h>
#include <string.h>
#include <stat.h>

int verbose=0;

#define BUFFER_SIZE 2000000		/* 2 megs max */

/* buffered file copy */

/*int copy_file(char *src,char *dest,long buffer_size)
{
   return copy_file_part(src,dest,buffer_size,-1);
}*/

int copy_file_part(char *src,char *dest,long buffer_size,long copy_size)
{
  FILE *fr,*fw;
  struct stat buf;
  char *buffer=NULL;
  long copylen,buflen;

  if (verbose)
  { printf("Copying %s into %s\n",src,dest); }

  stat(src,&buf);

  fr=fopen(src,"r");
  if (fr==0) {return -1;}
  fw=fopen(dest,"w");
  if (fw==0) {fclose(fr);return -1;}

  /* total length to copy */

  copylen=copy_size < 0 ? buf.st_size : copy_size;

  if (copylen>0)
  {
	/* file is not empty */

   if (copylen>buffer_size)
   {

	/* allocate 2 megs */

    buffer=(char *)malloc(buffer_size);
	buflen=BUFFER_SIZE;
   }
   else
   {
	/* allocate only copylen bytes */

    buffer=(char *)malloc(copylen);
	buflen=copylen;
   }

	/* allocation failed */

   if (buffer==0) {fclose(fr);fclose(fw);return -1;}

   while (copylen>0)
   {
     long bytesread;

	/* try to read buflen bytes */

     bytesread=fread(buffer,1,buflen,fr);

	if (bytesread>0)
	{
	/* write the data in the output file */

     fwrite(buffer,1,bytesread,fw);

	/* decrease copylen until we reach 0 */

	 copylen-=bytesread;
	}
	else
	{
	 /* end of copy */

	 copylen=0;
	}
   }
  }

  fclose(fr);
  fclose(fw);
  if (buffer!=NULL) {free(buffer);}

  return 0;
}

main(argc,argv)

unsigned int argc;
char **argv;

{
  int rc=20;
  long copy_size = -1;

  if (argc<3)
  {
    fprintf(stderr,"SimpleCopy, a lame but handy prog by JOTD\n"
                   "Usage: %s [-v] [-size sz] <source> <dest>\n",argv[0]);
  }
  else
  {
   int argstart=1;

   if (!strncmp(argv[argstart],"-v",2))
   {
	 verbose=1; /* verbose mode */
     argstart++;
   }
   if ((!strcmp(argv[argstart],"-size")) && (argc>argstart+1))
   {
     copy_size = atoi(argv[argstart+1]);
     argstart+=2;
   }

   if (copy_file_part(argv[argstart],argv[argstart+1],BUFFER_SIZE,copy_size)!=0)
   {
    fprintf(stderr,"Impossible to copy %s to %s\n",argv[argstart],argv[argstart+1]);
   }
   else {rc=0;}
  }

  return rc;
}
