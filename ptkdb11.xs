#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static CV *
get_main_cv()
{
#ifdef USE_THREADS
        return PL_main_cv ;
#else
        return main_cv ;
#endif
}


MODULE = Devel::ptkdb11		PACKAGE = Devel::ptkdb11		


double
constant(name,arg)
	char *		name
	int		arg


AV *
getlocals(routine_name)
         char *routine_name
PREINIT:
	CV * routineCv ;
        AV * padList ;
	AV * val ;
CODE:

	if( !routine_name || !routine_name[0] ) { /* if no name is specified assume 'main' routine of the script */
	 	routineCv = get_main_cv() ;
         }	
        else 
	   routineCv = perl_get_cv(routine_name, FALSE) ;
	
	if( !routineCv ) {
	  fprintf(stderr, "The subroutine \'%s\' does not exist\n", routine_name) ;
	  XSRETURN_UNDEF;
        }

	padList = CvPADLIST(routineCv) ;
	val = (AV *)*av_fetch(padList, 0, 0) ;
	RETVAL = val ;
OUTPUT:
	RETVAL

void 
SetupTkEventFilter()

    PPCODE:
	_SetupTkEventFilter() ;

void 
RaiseWM(widg)
SV *widg ;
    PPCODE:
	_RaiseWM(widg) ;
