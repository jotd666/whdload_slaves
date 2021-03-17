#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <pragmas/dos_pragmas.h>

#include <exec/types.h>
#include <exec/memory.h>

#define SAVE_SIZE 0x8B*0x200


#define Erreur(ch) \
{if (ch) printf("** %s\n",ch);\
 if (buffer) FreeMem((APTR)buffer,disk_size);\
 if (!argc) {printf("\n** Press RETURN\n");fflush(stdin);getchar();}\
 if (ch) exit(1); else exit(0);}


extern ULONG ReadLureSectors(char *,ULONG,ULONG,ULONG);


char *buffer=NULL;
int disk_size=0;

main(unsigned int argc,char **argv)

{
char *offset_buffer,savename[20];
FILE *f;
int i;
int unit=0,start_sector=0,end_sector=(0x8C*9)+1,nb_sectors;

printf("Lure of the Temptress game save ripper\nCoded by JF Fabre © 1997\n");

if (argc>1)
	unit=atoi(argv[1]);

nb_sectors=end_sector-start_sector+1;


if ((nb_sectors<1)||(start_sector<0)||(end_sector>0x780)) Erreur("Invalid sector range");

if ((unit>3)||(unit<0)) Erreur("Please choose a disk unit between 0-3!");

disk_size=(end_sector+1)*0x200;

buffer=(char *)AllocMem(disk_size,MEMF_CLEAR);

if (!buffer) Erreur("Unable to allocate memory");

offset_buffer=buffer+(start_sector*0x200);

printf("Insert save game disk and press RETURN\n");
fflush(stdin);
getchar();

printf("Reading %d sectors from disk from sector %d to %d\nPlease wait...\n",nb_sectors,start_sector,end_sector);

if (ReadLureSectors(offset_buffer,unit,start_sector,nb_sectors)!=0)  Erreur("Disk read error !!");

printf("Floppy has been read\n\n");

if (!(f=fopen("luresave.dir","wb"))) Erreur("Unable to create file\n");

printf("Writing directory information\n");
fwrite(buffer,0x200,1,f);
fclose(f);

offset_buffer+=0x200;

for (i=0;i<9;i++)
 {
   if (strncmp("PDOS",offset_buffer,4))
     {
	printf("Writing savegame #%d\n",i+1);
	sprintf(savename,"luresave.%d",i+1);
	if (!(f=fopen(savename,"wb"))) Erreur("Unable to create save file");
	fwrite(offset_buffer,SAVE_SIZE,1,f);
	fclose(f);
     }

offset_buffer+=SAVE_SIZE;
 }

printf("Done\n");
Erreur(NULL);
}
