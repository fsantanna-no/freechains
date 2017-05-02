#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <libmilter/mfapi.h>

sfsistat mlfi_envrcpt (SMFICTX* ctx, char** argv) {
    printf("RCPT: %s\n", argv[0]);
    return SMFIS_ACCEPT;
}

struct smfiDesc smfilter = {
	"greylist",     /* filter name */
	SMFI_VERSION,   /* version code */
	SMFIF_ADDHDRS,  /* flags */
	NULL,           /* connection info filter */
	NULL,           /* SMTP HELO command filter */
	NULL,           /* envelope sender filter */
	mlfi_envrcpt,   /* envelope recipient filter */
	NULL,           /* header filter */
	NULL,           /* end of header */
	NULL,           /* body block filter */
    NULL,
	//mlfi_eom,       /* end of message */
	NULL,           /* message aborted */ 
	NULL,           /* connection cleanup */
}; 

int main (void) {
    smfi_setconn("unix:/var/spool/postfix/freechains.milter");
    assert(smfi_register(smfilter) != MI_FAILURE);
    return smfi_main();
}
