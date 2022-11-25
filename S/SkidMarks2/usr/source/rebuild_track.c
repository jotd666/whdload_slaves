
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <strings.h>
#ifdef __GNUC__
#include <stdint.h>
#else
typedef  unsigned long uint32_t;
typedef  unsigned char uint8_t;
#endif

#define MAX_CRM_FILE 20
//#define DEBUG

uint32_t from_be(const uint8_t b[])
{
      return (uint32_t)(b[0]<<24) + (uint32_t)(b[1]<<16) + (uint32_t)(b[2]<<8) + (b[3]);
}

void to_be(uint32_t len,uint8_t len_be[])
{
          len_be[0] = (len>>24);
        len_be[1] = (len>>16) & 0xff;
        len_be[2] = (len>>8) & 0xff;
        len_be[3] = (len) & 0xff;
}
    
void process_data(const char *data,int size, const char *output)
{
  int crm_offset[MAX_CRM_FILE];
  int crm_offset_shift[MAX_CRM_FILE];
  int nb_crm_files = 0;
  const char *crmheader = "CrM!";
  const char *crmheader2 = "CrM2";
  FILE *f;
  int i;
  char len_be[4];
  uint32_t len;
  
  /* first pass: search for Crm! headers */
#ifdef DEBUG
  printf("input size %d\n",size);
#endif
  for (i = 0; i < size-4; i+=2)
  {

    if ((memcmp(crmheader,data+i,4)==0) ||
    (memcmp(crmheader2,data+i,4)==0))
    {
      if (nb_crm_files < MAX_CRM_FILE)
      {
        crm_offset[nb_crm_files] = i;
        nb_crm_files++;
#ifdef DEBUG
        printf("crm file found at $%x\n",i);
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
        uint32_t len;
       /* file size */

      memcpy(len_be,data+crm_offset[i-1]+10,4);
      len = from_be(len_be) + 14;

        global_offset_shift += (crm_offset[i] - crm_offset[i-1]) - len;
        crm_offset_shift[i] -= global_offset_shift;
        
     }
  }
  memcpy(len_be,data+crm_offset[nb_crm_files-1]+10,4);
  len = from_be(len_be) + 14;
  crm_offset_shift[nb_crm_files] = crm_offset_shift[nb_crm_files-1]  + len;   // last offset is full file size

  /* second pass: create the output file */

  f=fopen(output,"wb");
  if (f == NULL)
  {
        printf("Cannot create %s\n",output);
  }
  else
  {
    /* header: offset of files */
    for (i = 0; i < nb_crm_files + 1; i++)
    {
       to_be(crm_offset_shift[i] + 2,len_be);
       fwrite(len_be,4,1,f);
    }
    /* non crm stuff - header */

    fwrite(data,crm_offset[0]-2,1,f);
    /* crm files */
    for (i = 0; i < nb_crm_files; i++)
    {
      uint32_t len = from_be(data+crm_offset[i]+10);

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
    data = malloc(file_size);
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
