#include <stdio.h>
#include <stdlib.h>
#include <dos/dos.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <pragmas/dos_pragmas.h>

#include <exec/types.h>
#include <exec/memory.h>

extern ULONG ReadLureSectors(char *,ULONG,ULONG,ULONG);


main(unsigned int argc,char **argv)

{
char *buffer,*offset_buffer;
FILE *f;
int unit=0,start_sector,end_sector,nb_sectors,disk_size;

if (argc==0) exit(0);

printf("Lure disk reader\nCoded by JF Fabre © 1997\n");
if (argc<5) {printf("** Usage: ripluredisk <unit(0-3)> <filename> <start_sector> <end_sector>\n");exit(0);}

unit=atoi(argv[1]);
start_sector=atoi(argv[3]);
end_sector=atoi(argv[4]);

nb_sectors=end_sector-start_sector+1;

if ((nb_sectors<1)||(start_sector<0)||(end_sector>0x780)) {printf("** Invalid sector range\n");exit(1);}

if ((unit>3)||(unit<0)) {printf("** Please choose a disk unit between 0-3!\n");exit(1);}

disk_size=(end_sector+1)*0x200;

buffer=(char *)AllocMem(disk_size,MEMF_CLEAR);

if (!buffer) {printf("** Unable to allocate memory\n");exit(1);}

offset_buffer=buffer+(start_sector*0x200);

printf("Reading %d sectors from disk from sector %d to %d\nPlease wait...\n",nb_sectors,start_sector,end_sector);

if (ReadLureSectors(offset_buffer,unit,start_sector,nb_sectors)!=0)  {FreeMem((APTR)buffer,disk_size);printf("** Disk read error !!\n");exit(1);}

printf("Disk read\n");

if (!(f=fopen(argv[2],"wb"))) {FreeMem((APTR)buffer,disk_size);printf("** Unable to open destination file\n");exit(1);}

printf("Writing disk image...");fflush(stdout);
fwrite(buffer,disk_size,1,f);
printf("Done.\n");

fclose(f);

FreeMem((APTR)buffer,disk_size);

}
