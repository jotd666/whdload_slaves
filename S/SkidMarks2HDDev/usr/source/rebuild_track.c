
#include <stdio.h>
#include <stdlib.h>
#include <stat.h>
#include <strings.h>

#define MAX_CRM_FILE 20

/* source is big endian dependent */

void process_data(const char *data,int size, const char *output)
{
  int crm_offset[MAX_CRM_FILE];
  int crm_offset_shift[MAX_CRM_FILE];
  int nb_crm_files = 0;
  int crmheader;
  FILE *f;
  int i;
  int longword;

  memcpy(&crmheader,"CrM!",4);

  /* first pass: search for Crm! headers */
#ifdef DEBUG
  printf("size %d\n",size);
#endif
  for (i = 0; i < size-4; i+=2)
  {
    /* big endian */
    memcpy(&longword,data+i,4);

    if (longword == crmheader)
    {
      if (nb_crm_files < MAX_CRM_FILE)
      {
        crm_offset[nb_crm_files] = i;
        nb_crm_files++;
#ifdef DEBUG
        printf("crm file found at %x\n",i);
#endif
      }
    }
  }

  if (nb_crm_files > 0)
  {
    int global_offset_shift = 0;
   
  for (i = 0; i < nb_crm_files; i++)
  {  
     crm_offset_shift[i] = crm_offset[i] + nb_crm_files*4;
     if (i > 0)
     {
        int len;
       /* file size */
        memcpy(&len,data+crm_offset[i-1]+10,4);
        len += 14;
        global_offset_shift += (crm_offset[i] - crm_offset[i-1]) - len;
        crm_offset_shift[i] -= global_offset_shift;
     }
  }

  /* second pass: create the output file */

  f=fopen(output,"wb");
  if (f == NULL)
  {
        printf("Cannot create %s\n",output);
  }
  else
  {
    /* header: offset of files */
    fwrite(crm_offset_shift,nb_crm_files*4,1,f);
    /* non crm stuff */
    fwrite(data,crm_offset[0],1,f);
    /* crm files */
    for (i = 0; i < nb_crm_files; i++)
    {
      int len;
      /* file size */
      memcpy(&len,data+crm_offset[i]+10,4);
      len += 14;
#ifdef DEBUG
      printf("crm file from $%x to $%x, len %d\n",crm_offset_shift[i],len+crm_offset_shift[i],len);
#endif
      if (len < size) /* safety: file could be corrupt */
      {
        fwrite(data+crm_offset[i],len,1,f);
      }
    }
    fclose(f);
  }
  }
}

int main(unsigned int argc,const char **argv)
{
struct stat buf1;
const char *file1;
int retcode=0;
int file_size=-1;
char *data = NULL;

  if (argc<3)
  {
    printf("Usage: %s <image> <outputfile>\n",argv[0]);
    retcode=10;
  }
  else
  {
    file1=argv[1];

    if (stat(file1,&buf1)!=0)
    {
      printf("cannot stat %s\n",file1);
      retcode=5;
    }

    if (retcode==0)
    {
      file_size=buf1.st_size;
    }

  }


  if (retcode == 0)
  {
    data = (char*)malloc(file_size);
    if (data != NULL)
    {
       FILE *f = fopen(file1,"rb");
       if (f != NULL)
       {
		fread(data,file_size,1,f);
        fclose(f);
        process_data(data,file_size,argv[2]);
       }
       else
       {
        printf("Cannot open %s\n",file1);
       }
    }
    else
    {
       printf("Cannot allocate %d bytes\n",file_size);
       retcode = 10;
    }

  }

  if (data != NULL)
  {
    free(data);
  }

  return retcode;
}
