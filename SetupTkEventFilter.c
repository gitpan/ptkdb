#include <stdio.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "tk.h"
#include "tkGlue.h"
#include "Xlib.h"


static Tk_RestrictProc *prev_proc ;
static SV *dbON ; /* value of db on (Are we in the debugger or not? */
static CV *db_check_win ;
static ClientData prevArg ;

static Tk_RestrictAction ptkdb_filter(ClientData clientData, XEvent *eventPtr)
{
  SV *theWidget ;
  int result_cnt, result = 1 ;
  Tk_Window tkwin ;
  dSP ;

  /*
   * Process any exposure event so windows update properly
   */
  if( eventPtr->type == Expose )
    return TK_PROCESS_EVENT ;

  tkwin = Tk_EventWindow(eventPtr) ;

  /*
   * Call our procedure to see if this is our window(or one of them)
   */

  /* get the main window widget */

  tkwin = TkToMainWindow(tkwin) ;
  theWidget = TkToWidget(tkwin, 0L) ;

  /* now call back to DB::CheckDBWindows */

  ENTER ;
  SAVETMPS ;
  PUSHMARK(sp) ;

  XPUSHs(theWidget) ; /* push the widget on the stack */

  PUTBACK ;

  result_cnt = perl_call_sv((SV *)db_check_win, G_SCALAR) ;
  
  SPAGAIN ;

  result = POPi ;

  PUTBACK ;
  FREETMPS ;
  LEAVE ;
  
  if( !SvTRUE(dbON) && result  ) {
    /* printf("click in DB window when DB was not on\n") ; */
    fflush(stdout) ;
    return TK_DISCARD_EVENT ;
  }

  if( SvTRUE(dbON) && !result ) {
    /* printf("click in NON-DB window when DB was on\n") ; */
    fflush(stdout) ;
    return TK_DISCARD_EVENT ;
  }

  if( prev_proc )
    return (*prev_proc)(prevArg, eventPtr) ;

  return TK_PROCESS_EVENT ;
}

void _SetupTkEventFilter()
{
  Tk_RestrictProc *filter ;

  /*
   * Get the perl procedure DB::CheckDBWindows() ;
   */

  db_check_win = perl_get_cv("DB::CheckDBWindows", FALSE) ;
  if( !db_check_win ) {
    fprintf(stderr, "no DB::CheckDBWindows, TK window restrictions are not set\n") ;
    return ;
  }

  /*
   * Get the perl scalar value DB::on
   */
  dbON = perl_get_sv("DB::on", FALSE) ;
  if( !dbON ) {
    fprintf(stderr, "no DB::on, TK window restrictions are not set\n") ;
    return ;
  }

  prev_proc = Tk_RestrictEvents(ptkdb_filter, 0L, &prevArg) ; 

} /* end of _SetupTkEventFilter */

void _RaiseWM(SV *widg)
{
  Tk_Window tkwin ;
  Display *disp ;
  Window win ;
  int result_cnt ;
  long result ; 
  dSP ;

  tkwin = SVtoWindow(widg) ;
  
  tkwin = TkToMainWindow(tkwin) ; /* get the main window */

  disp = Tk_Display(tkwin) ;
  
  /* get the window id of the widget */

  ENTER ;
  SAVETMPS ;
  PUSHMARK(sp) ;

  XPUSHs(widg) ; /* push the widget on the stack */

  PUTBACK ;

  result_cnt = perl_call_method("frame", G_SCALAR) ;
  
  SPAGAIN ;

  result = POPl ; /* get the WindowId Result */

  PUTBACK ;
  FREETMPS ;
  LEAVE ;
  if( !result )
    return ;
  printf("frame result = %ld\n", result) ;

  /*
   * What do do for win32?
   */
  XRaiseWindow(disp, result) ;
}

AV *_getlocals(char *routine_name)
{
  CV * routineCv = 0L ;
  AV * padList ;
  AV * val ;

  if( !routine_name || !routine_name[0] ) { /* if no name is specified assume 'main' routine of the script */
#if defined( USE_THREADS )
    routineCv = PL_main_cv ;
#else 
    routineCv = main_cv ;
#endif
  }	
  else 
    routineCv = perl_get_cv(routine_name, FALSE) ;
	
  if( !routineCv ) {
    fprintf(stderr, "The subroutine \'%s\' does not exist\n", routine_name) ;
    return 0L ;
  }
	
  padList = CvPADLIST(routineCv) ;
  val = (AV *)*av_fetch(padList, 0, 0) ;
	
  return val ;
} /* end of get_locals */
