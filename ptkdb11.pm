package Devel::ptkdb11;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '1.09';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Devel::ptkdb11 macro $constname";
	}
    }
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Devel::ptkdb11 $VERSION;

# Preloaded methods go here.
#
# If you've loaded this file via a browser
# select "Save As..." from your file menu
#
#			   ptkdb Perl Tk perl Debugger
#
#		       Copyright 1998, Andrew E. Page
#			    All rights reserved.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of either:
#
#	a) the GNU General Public License as published by the Free
#	Software Foundation; either version 1, or (at your option) any
#	later version, or
#
#	b) the "Artistic License" which comes with this Kit.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
#    the GNU General Public License or the Artistic License for more details.
#
use strict ;

package Devel::ptkdb11 ;

require 5.004 ;
use Tk 400.202 ;
require Tk ;
require Tk::Dialog;
require Tk::TextUndo ;
use Tk::NoteBook ;

use Config ;
#
# Check to see if the package actually
# exists. If it does import the routines
# and return a true value ;
#
# NOTE:  this needs to be above the 'BEGIN' subroutine,
# otherwise it will not have been compiled by the time
# that it is called by sub BEGIN.
#
sub check_avail {
    my ($mod, @list) = @_ ;

    eval {
	require $mod ; import $mod @list ;
    } ;

    return 0 if $@ ;
    return 1 ;

} # end of check_avail

sub BEGIN {

   #
   # the bindings and font specs for these operations have been placed here
   # to make them accessible to people who might want to customize the 
   # operations.  REF The 'bind.html' file, included in the perlTk FAQ has
   # a fairly good explanation of the binding syntax.  
   # 

   #
   # These lists of key bindings will be applied
   # to the "Step In", "Step Out", "Return" Commands
   #
  @Devel::ptkdb11::step_in_keys   = ( '<Alt-s>', '<Button-3>' ) ; # step into a subroutine
  @Devel::ptkdb11::step_over_keys = ( '<Alt-n>', '<Shift-Button-3>' ) ; # step over a subroutine
  @Devel::ptkdb11::return_keys    = ( '<Alt-u>', '<Control-Button-3>' ) ; # return from a subroutine
  @Devel::ptkdb11::toggle_breakpt_keys = ( '<Alt-b>' ) ; # set or unset a breakpoint

  # Fonts used in the displays
  
  #
  # NOTE:  The environmental variable syntax here works like this:
  # $ENV{'NAME'} accesses the environmental variable "NAME"
  #
  # $ENV{'NAME'} || 'string'  results in  $ENV{'NAME'} or 'string' if  $ENV{'NAME'} is not defined.  
  #
  #
  
  $Devel::ptkdb11::button_font = $ENV{'PTKDB_BUTTON_FONT'} || '-*-courier-medium-r-*-*-*-120-*-*-*-*-*-*' ; # font for buttons
  $Devel::ptkdb11::code_text_font = $ENV{'PTKDB_CODE_FONT'} || '-*-courier-medium-r-*-*-*-100-*-*-*-*-*-*' ; # basic window text
  $Devel::ptkdb11::expression_text_font = $ENV{'PTKDB_EXPRESSION_FONT'} || $Devel::ptkdb11::code_text_font ;
  $Devel::ptkdb11::italic_text_font = $ENV{'PTKDB_CODE_FONT_EXPRESSION'} || '-*-courier-medium-i-*-*-*-100-*-*-*-*-*-*' ; # used to annotate lines with expressions
  $Devel::ptkdb11::text_stop_line_font  = $ENV{'PTKDB_CODE_FONT_STOPPED'} || '-*-courier-bold-r-*-*-*-100-*-*-*-*-*-*' ; # font we use at stopped lines
  $Devel::ptkdb11::eval_text_font = $ENV{'PTKDB_EVAL_FONT'} || '-*-courier-medium-r-*-*-*-100-*-*-*-*-*-*' ; # text for the expression eval window

  $Devel::ptkdb11::stop_tag_color = $ENV{'PTKDB_STOP_TAG_COLOR'} || 'blue' ;
  $Devel::ptkdb11::brkpt_text_color = $ENV{'PTKDB_BREAKPOINT_TEXT_COLOR'} || 'green' ;

  @Devel::ptkdb11::stop_tag_cfg  = ( -font => $Devel::ptkdb11::text_stop_line_font, 'background' => $Devel::ptkdb11::stop_tag_color ) ; # text configuration for where we're stopped
  @Devel::ptkdb11::brkExprTagCfg = ( -font => $Devel::ptkdb11::italic_text_font, 'background' =>  $Devel::ptkdb11::brkpt_text_color ) ; # text config for expressions on conditionnal breakpoints

  $Devel::ptkdb11::eval_dump_indent = $ENV{'PTKDB_EVAL_DUMP_INDENT'} || 1 ;
# -scrollbars => 'se',

    #
    # Windows users are more used to having scroll bars on the right
    # if they've set PTKDB_SCROLLBARS_ONRIGHT to a non-zero value
    # this will configure our scrolled windows with scrollbars on the right
    #

    if( exists $ENV{'PTKDB_SCROLLBARS_ONRIGHT'} && $ENV{'PTKDB_SCROLLBARS_ONRIGHT'} ) {
      @Devel::ptkdb11::scrollbar_cfg = ('-scrollbars' => 'se') ;
    }
    else {
      @Devel::ptkdb11::scrollbar_cfg = ( ) ;
    }

    #
    # Controls how far an expression result will be 'decomposed'.  Setting it
    # to 0 will take it down only one level, setting it to -1 will make it 
    # decompose it all the way down.  However, if you have a situation where
    # an element is a ref  back to the array or a root of the array
    # you could hang the debugger by making it recursively evaluate an expression
    #
  $Devel::ptkdb11::expr_depth = -1 ;
  $Devel::ptkdb11::add_expr_depth = 1 ; # how much further to expand an expression when clicked

  $Devel::ptkdb11::linenumber_format = $ENV{'PTKDB_LINENUMBER_FORMAT'} || "%05d " ;
  $Devel::ptkdb11::linenumber_offset = length sprintf($Devel::ptkdb11::linenumber_format, 0) ;
  $Devel::ptkdb11::linenumber_offset -= 1 ;

  $Devel::ptkdb11::cmd_table = {
      'open' => sub { print "open\n" },
      'goto_line' => sub { print "goto line\n" },
      'find_text' => sub { print "find text\n" },

      'quit' => sub { $DB::on = 0, $DB::single = 0 ; exit },
      
      #
      # Control items
      #

      'run' => sub { print "run\n" }, 
      'run_to_here' => sub { print "run to here\n" }, 
      'step_over' => sub { print "step over\n" },
      'step_in' => sub { print "step in\n" },
      'return' => sub {  print "return\n" },

      'set_breakpoint' => sub { print "set breakpoint\n" },
      'clear_breakpoint' => sub { print "clear breakpoint\n" },
      'clear_all_breakpoints' => sub { print "clear all breakpoints\n" },

      #
      # Data
      #
      'enter_expr' => sub { print "enter expr\n" },
      'delete_expr' => sub { print "delete expr\n" },
      'delete_all_exprs' => sub { print "delete exprs\n" },

      #
      # Edit Controls
      #
      'cut' => sub { print "cut\n" },
      'copy' => sub { print "copy\n" },
      'paste' => sub { print "paste\n" },
      'clear' => sub { print "clear\n" }
  } ;

    #
    # Check to see if "Data Dumper" is available
    # if it is we can save breakpoints and other 
    # various "functions".  This call will also
    # load the subroutines needed.
    #
  $Devel::ptkdb11::DataDumperAvailable = check_avail("Data/Dumper.pm", "Dumper") ;
  $Devel::ptkdb11::useDataDumperForEval = $Devel::ptkdb11::DataDumperAvailable ;

    #
    # DB Options (things not directly involving the window)
    #

  # Flag to disable us from intercepting $SIG{'INT'}

  $DB::sigint_disable = defined $ENV{'PTKDB_SIGINT_DISABLE'} && $ENV{'PTKDB_SIGINT_DISABLE'} ;
#
# Possibly for debugging perl CGI Web scripts on
# remote machines.  
#
    $ENV{'DISPLAY'} = $ENV{'PTKDB_DISPLAY'} if exists $ENV{'PTKDB_DISPLAY'} ;

} # end of BEGIN

#
# Constructor for our Devel::ptkdb11
#
sub new {
    my($type) = @_ ;
    my($self, $mb) ; # $mw is the main_window, mb is the menu_bar
    
    $self = {} ;
    bless $self, $type ;

    #
    # Initial data
    #
    $self->{breakpoints} = [] ; # used when we set/unset breakpoints and switch files

    # Current position of the executing program

    $self->{current_file} = "" ; 
    $self->{current_line} = -1 ; # initial value indicating we haven't set our line/tag
    $self->{window_pos_offset} = 10 ; # when we enter how far from the top of the text are we positioned down
    $self->{search_start} = "" ;

    $self->{'expr_list'} = () ; # list of expressions to eval in our window fields:  {'expr'} The expr itself {'depth'} expansion depth

    # Main Window

    $self->{main_window} = MainWindow->new() ;

    $self->{main_window}->bind('<Control-c>', \&DB::dbint_handler) ;

    #
    # Bind our 'quit' routine to a close command from the window
    # manager (Alt-F4)
    #

    $self->{main_window}->protocol('WM_DELETE_WINDOW', sub { &{$Devel::ptkdb11::cmd_table->{'quit'}} } ) ;

    # Menu bar

    $self->setup_menu_bar() ;

    # setup Frames
    #
    # Setup our Code, Data, and breakpoints

    $self->setup_frames() ;

    return $self ;

} # end of new

sub setup_menu_bar {
    my ($self) = @_ ;
    my $mw = $self->{main_window} ;
    my $mb ;
    
    
    #
    # We have menu items/features that are not available if the Data::DataDumper module
    # isn't presently.  For any feature that requires it we add this option list.
    #
    my @dataDumperEnableOpt = ( state => 'disabled' ) unless $Devel::ptkdb11::DataDumperAvailable ;


    $self->{menu_bar} = $mw->Frame(-relief => 'raised', -borderwidth => '1')->pack(side => 'top', -fill => 'x') ;

    $mb = $self->{menu_bar} ;

    # file menu in menu bar

    $self->{file_menu_button} = $mb->Menubutton(text => 'File',
						underline => 0,
						)->pack(side =>, 'left',
							anchor => 'nw',
							'padx' => 2) ;

    # About box
    

    $self->{file_menu_button}->command(-label => 'About...',
				       command => sub { $self->DoAbout() ; } # we do an extra sub level for future AUTOLOADING work
				       ) ;

    $self->{file_menu_button}->separator() ;

    # open item in menu bar

    $self->{open_button} = $self->{file_menu_button}->command(-label => 'Open',
							      -accelerator => 'Alt+O',
							      underline => 0,
							      command => sub { &{$Devel::ptkdb11::cmd_table->{'open'}} }
							      ) ;
    $mw->bind('<Alt-o>' => sub { &{$Devel::ptkdb11::cmd_table->{'open'}} } );

    # Save Breakpoints and Expressions (Enabled only if Data::Dumper is available)


    $self->{save_brks_and_exprs} = $self->{file_menu_button}->command( -label => 'Save Config...',
								       underline => 0,
								       command => sub { &{$Devel::ptkdb11::cmd_table->{'save_brks'}} },
								       @dataDumperEnableOpt) ;

    $self->{restore_brks_and_exprs} = $self->{file_menu_button}->command( -label => 'Restore Config...',
									  underline => 0,
									  command => sub { &{$Devel::ptkdb11::cmd_table->{'restore_brks'}} },
									  @dataDumperEnableOpt) ;
    
    # Goto line

    $self->{goto_line_button} = $self->{file_menu_button}->command(-label => 'Goto Line...',
								   -accelerator => 'Alt+g',
								   underline => 0,
								   command => sub { &{$Devel::ptkdb11::cmd_table->{'goto_line'}} }
								   ) ;

    $mw->bind('<Alt-g>' => sub { &{$Devel::ptkdb11::cmd_table->{'goto_line'}} }) ;


    # Find Text

    $self->{find_text_button} = $self->{file_menu_button}->command(-label => 'Find Text...',
								   -accelerator => 'Ctrl+f',
								   underline => 0,
								   command => sub { &{$Devel::ptkdb11::cmd_table->{'find_text'}} }
								   ) ;

    $mw->bind('<Control-f>' => sub { &{$Devel::ptkdb11::cmd_table->{'find_text'}} }) ;

    # quit item in menu bar

    $self->{file_menu_button}->separator() ;

    $self->{quit_button} = $self->{file_menu_button}->command(-label => 'Quit',
							      -accelerator => 'Alt+Q',
							      underline => 0,
							      command => sub { &{$Devel::ptkdb11::cmd_table->{quit}} }
							      ) ;

    $mw->bind('<Alt-q>' => $Devel::ptkdb11::cmd_table->{quit} );

    # Control Menu

    
    $self->{control_menu_button} = $mb->Menubutton(text => 'Control',
						   underline => 0,
						   )->pack(side =>, 'left',
							   'padx' => 2) ;

    # Run

    $self->{control_menu_button}->command(-label => 'Run',
					  -accelerator => 'Alt+r',
					  underline => 0,
					  command => sub { &{$Devel::ptkdb11::cmd_table->{run}} }
					  ) ;

    $mw->bind('<Alt-r>' => sub { &{$Devel::ptkdb11::cmd_table->{run}} } );

    # Run to

    $self->{control_menu_button}->command(-label => 'Run To Here',
					  -accelerator => 'Alt+t',
					  underline => 5,
					  command => sub { &{$Devel::ptkdb11::cmd_table->{run_to_here}} }
					  ) ;

    $mw->bind('<Alt-t>', sub { &{$Devel::ptkdb11::cmd_table->{run_to_here}} } ) ;


    # Set BrkPt

    $self->{control_menu_button}->separator() ;

    $self->{set_breakpoint_button} = $self->{control_menu_button}->command(-label => "Set Breakpoint",
									   -underline => 4,
									   command => sub { &{$Devel::ptkdb11::cmd_table->{set_breakpoint}} }
									   ) ;

    # Clear BrkPt

    $self->{clr_breakpoint_button} = $self->{control_menu_button}->command(-label => "Clear Breakpoint",
									   command => sub { &{$Devel::ptkdb11::cmd_table->{clear_breakpoint}} }
									   ) ;

    # Clear All Breakpoints

    $self->{clr_all_breakpoints_button} = $self->{control_menu_button}->command(-label => "Clear All Breakpoints",
										-underline => 6,
										command => sub { &{$Devel::ptkdb11::cmd_table->{clear_all_breakpoints}} }
										) ;

    $self->{control_menu_button}->separator() ;
    
    # Step Over

    $self->{step_over_menu_button} = $self->{control_menu_button}->command(-label => "Step Over",
									   -accelerator => 'Alt+N',
									   -underline => 0,
									   command => sub { &{$Devel::ptkdb11::cmd_table->{step_over}} }
									   ) ;
    # Step In

    $self->{step_in_menu_button} = $self->{control_menu_button}->command(-label => "Step In",
									 -accelerator => 'Alt+S',
									 -underline => 5,
									 command => sub { &{$Devel::ptkdb11::cmd_table->{step_in}} }
									 ) ;

    # Return

    $self->{return_menu_button} = $self->{control_menu_button}->command(-label => "Return",
									-accelerator => 'Alt+U',
									-underline => 3,
									command => sub { &{$Devel::ptkdb11::cmd_table->{'return'}} }
									) ;

    for( @Devel::ptkdb11::return_keys ) {
      $mw->bind($_ => sub { &{$Devel::ptkdb11::cmd_table->{'return'}} } );
    }

    # Data Menu

    $self->{data_menu_button} = $mb->Menubutton(text => 'Data',
						underline => 0,
						)->pack(side => 'left',
							'padx' => 2) ;

    # Enter expression

    $self->{enter_expr_menu_button} = $self->{data_menu_button}->command(-label => "Enter Expression",
									 -accelerator => 'Alt+E',
									 command => sub { &{$Devel::ptkdb11::cmd_table->{enter_expr}} }
									 ) ;

    $mw->bind('<Alt-e>' => sub { &{$Devel::ptkdb11::cmd_table->{enter_expr}} } );

    # Delete an Expression

    $self->{data_menu_button}->command(-label => "Delete Expression",
				       -accelerator => 'Alt+D',
				       command => sub { &{$Devel::ptkdb11::cmd_table->{delete_expr}} }
				       ) ;
    $mw->bind('<Control-d>' => sub { &{$Devel::ptkdb11::cmd_table->{delete_expr}} } );

    # Delete All Expressions

    $self->{data_menu_button}->command(-label => "Delete All Expressions",
				       command => sub { &{$Devel::ptkdb11::cmd_table->{delete_all_exprs}} }
				       ) ;

    # Expression Eval window

    $self->{data_menu_button}->separator() ;
    $self->{data_menu_button}->command(-label => "Expression Eval Window...",
				       -accelerator => 'F8',
				       command => sub { &{$Devel::ptkdb11::cmd_table->{eval_window}} }
				       ) ;

    $self->{data_menu_button}->checkbutton(-label => "Use DataDumper for Eval Window?",
					   variable => \$Devel::ptkdb11::useDataDumperForEval,
					   @dataDumperEnableOpt) ;
					   

    $mw->bind('<F8>', sub { &{$Devel::ptkdb11::cmd_table->{eval_window}} }) ;
    #
    # Stack menu
    #
    $self->{stack_menu} = $mb->Menubutton(text => 'Stack',
					  underline => 2,
					  )->pack(side =>, 'left',
						  'padx' => 2) ;

    #
    # Bar for some popular controls
    #

    $self->{button_bar} = $mw->Frame()->pack(side => 'top') ;

    $self->{stepin_button} = $self->{button_bar}->Button(-text, => "Step In", font => $Devel::ptkdb11::button_font,
							 -command => sub { &{$Devel::ptkdb11::cmd_table->{step_in}} } ) ;
    $self->{stepin_button}->pack(-side => 'left') ;

    $self->{stepover_button} = $self->{button_bar}->Button(-text, => "Step Over", font => $Devel::ptkdb11::button_font,
							   -command => sub { &{$Devel::ptkdb11::cmd_table->{step_over}} } ) ;
    $self->{stepover_button}->pack(-side => 'left') ;

    $self->{return_button} = $self->{button_bar}->Button(-text, => "Return", font => $Devel::ptkdb11::button_font,
							 -command => sub { &{$Devel::ptkdb11::cmd_table->{'return'}} } ) ;
    $self->{return_button}->pack(-side => 'left') ;

    $self->{run_button} = $self->{button_bar}->Button(-background => 'green', -text, => "Run", font => $Devel::ptkdb11::button_font,
						      -command => sub { &{$Devel::ptkdb11::cmd_table->{run}} } ) ;
    $self->{run_button}->pack(-side => 'left') ;

    $self->{run_to_button} = $self->{button_bar}->Button(-text, => "Run To", font => $Devel::ptkdb11::button_font,
						      -command => sub { &{$Devel::ptkdb11::cmd_table->{run_to_here}} } ) ;
    $self->{run_to_button}->pack(-side => 'left') ;

    $self->{breakpt_button} = $self->{button_bar}->Button(-text, => "Break", font => $Devel::ptkdb11::button_font,
							  -command => sub { &{$Devel::ptkdb11::cmd_table->{set_breakpoint}} } ) ;
    $self->{breakpt_button}->pack(-side => 'left') ;


    
} # end of setup_menu_bar

sub setup_frames {
    my ($self) = @_ ;
    my $mw = $self->{main_window} ;
    require Tk::HList ;
    require Tk::ROText;

    $self->{frame} = $mw->Frame(-relief => 'sunken')->pack(side => 'top', fill => 'both', expand => 'both',
							   anchor => 'nw'
							   ) ;

    #
    # Text window for the code of our currently viewed file
    #
    $self->{'text'} = $self->{frame}->Scrolled('ROText',
					     @Devel::ptkdb11::scrollbar_cfg,
					     width => 50,
					     -wrap => "none",
					     -font => $Devel::ptkdb11::code_text_font
					     ) ;
    $self->{'text'}->packAdjust(side => 'left', fill => 'both', expand => 'both') ;

    #
    # an hlist for the data entries
    #

    $self->{data_notebook} = $self->{'frame'}->NoteBook()->pack(side => 'left', fill => 'both', expand => 'both'
			     ) ;
    $self->{'expr_page'} = $self->{data_notebook}->add("Exprs", -label => "Exprs") ;
    $self->{'locals_page'} = $self->{data_notebook}->add("Locals", -label => "Locals") ;


    $self->{'data_list'} = $self->{'expr_page'}->Scrolled('HList',
							@Devel::ptkdb11::scrollbar_cfg, 
							width => 50,
							separator => '/',
							-font => $Devel::ptkdb11::expression_text_font,
						  -command => \&Devel::ptkdb11::expr_expand,
						  -selectmode => 'multiple'
						  ) ;

    

    $self->{'data_list'}->pack(side => 'left', fill => 'both', expand => 'both'
			     ) ;


    $self->{'locals_list'} = $self->{'locals_page'}->Scrolled('HList',
							      @Devel::ptkdb11::scrollbar_cfg, 
							      width => 50,
							      separator => '/',
							      -font => $Devel::ptkdb11::expression_text_font,
							      -command => \&Devel::ptkdb11::expr_expand,
							      -selectmode => 'multiple'
							     ) ;

    $self->{'locals_list'}->pack(side => 'left', fill => 'both', expand => 'both'
			     ) ;
    #
    # Entry widget for expressions and breakpoints
    #
    my $frame = $mw->Frame()->pack(side => 'top', fill => 'x') ;
    my $label = $frame->Label('text' => "Enter Expr:")->pack(side => 'left') ;

    $self->{entry} = $frame->Entry()->pack(side => 'left', fill => 'x', -expand => 'y') ;

    $self->{entry}->bind('<Return>', sub { &{$Devel::ptkdb11::cmd_table->{enter_expr}} }) ;

    for( @Devel::ptkdb11::step_over_keys ) {
      $mw->bind($_ => sub { &{$Devel::ptkdb11::cmd_table->{step_over}} } );
    }

    for( @Devel::ptkdb11::step_in_keys ) {
      $mw->bind($_ => sub { &{$Devel::ptkdb11::cmd_table->{step_in}} } );
    }

} # end of setup_frames

#
# The comment below is used by the "Makefile.PL" and makefile
# to adapt this file after auto splitter is done with it.
#

###DBPATCH###

sub DB::updateLocals {
  my($package, $subName) = @_ ;
  my($dbw, $locals, $lcl, @result, @localList) ;
  $dbw = $DB::window ;
  #
  # delete all of the existing expresions
  #
  $dbw->{'locals_list'}->delete('all') ;

  $locals = Devel::ptkdb11::getlocals($subName ? $subName : "") ;

  foreach $lcl ( @$locals  ) {
    next unless $lcl && length $lcl ;

    @result = &DB::dbeval($package, $lcl) ;
    
    if( scalar @result == 1 ) {
      $dbw->insertExpr($dbw->{'locals_list'}, $result[0], $lcl, -1) ;
    }
    else {
      $dbw->insertExpr($dbw->{'locals_list'}, \@result, $lcl, -1) ;
    }
  }
} # end of updateLocals

$DB::VERSION = 1.09 ;
$DB::header = "ptkdb.pm version $DB::VERSION";
$DB::current_file = "" ;

sub DB::BEGIN {
  $DB::on = 0 ;    
    
  $DB::subroutine_depth = 0 ; # our subroutine depth counter
  $DB::step_over_depth = -1 ;

  $Devel::ptkdb11::cmd_table->{'open'} = sub { $DB::window->DoOpen() ; } ;
  $Devel::ptkdb11::cmd_table->{'save_brks'} = sub { &DB::SaveState() ; } ;
  $Devel::ptkdb11::cmd_table->{'restore_brks'} = sub { &DB::RestoreState() ; } ;

  $Devel::ptkdb11::cmd_table->{'goto_line'} = sub { $DB::window->GotoLine() ; } ;
  $Devel::ptkdb11::cmd_table->{'find_text'} = sub { $DB::window->FindText() ; } ;
    
  $Devel::ptkdb11::cmd_table->{'set_breakpoint'} = sub { $DB::window->SetBreakPoint ; } ;
  $Devel::ptkdb11::cmd_table->{'clear_breakpoint'} = sub { $DB::window->UnsetBreakPoint ; } ;
  $Devel::ptkdb11::cmd_table->{'clear_all_breakpoints'} = sub {
     $DB::window->removeAllBreakpoints($DB::current_file) ;
     &DB::clearalldblines() ;
 } ;
    
  $Devel::ptkdb11::cmd_table->{'run'} = sub { $DB::step_over_depth = -1 ; $DB::window->{'event'} = 'run' } ;
  $Devel::ptkdb11::cmd_table->{'run_to_here'} = sub { 
    $DB::window->{'event'} = 'run' if  $DB::window->SetBreakPoint(1) ; 
 } ;
  $Devel::ptkdb11::cmd_table->{'quit'} = sub { $DB::window->{'event'} = 'quit' } ;
  $Devel::ptkdb11::cmd_table->{'step_in'} =  sub { $DB::single = 1 ; $DB::window->{'event'} = 'step_over' } ;
  $Devel::ptkdb11::cmd_table->{'step_over'} = sub { SetStepOverBreakPoint(0) ; $DB::window->{'event'} = 'step_over' } ;
  $Devel::ptkdb11::cmd_table->{'return'} = sub { 
    $DB::step_over = 1 ;
    $DB::step_over_depth = $DB::step_over_depth_saved - 1 ;
    $DB::window->{'event'} = 'run' ;
 } ;

  $Devel::ptkdb11::cmd_table->{delete_expr} = sub { $DB::window->deleteExpr() } ;

  $Devel::ptkdb11::cmd_table->{'delete_all_exprs'} = sub { $DB::window->deleteAllExprs() ; $DB::window->{'expr_list'} = [] ; # clears list by dropping ref to it, replacing it with a new one  
                                                    }  ;
  $Devel::ptkdb11::cmd_table->{'eval_window'} = sub { $DB::window->setupEvalWindow() ; } ;

  $Devel::ptkdb11::cmd_table->{'enter_expr'} = sub  {
      my $dbw = $DB::window ;
      my $str = $dbw->clear_entry_text() ;
      if( $str && $str ne "" && $str !~ /^\s+$/ ) { # if there is an expression and it's more than white space
	$dbw->{'expr'} = $str ;
	$dbw->{'event'} = 'expr' ;
      }

  } ; # end of EnterExpr


} # end of BEGIN

#
# Here's the clue...
# eval only seems to eval the context of
# the executing script while in the DB
# package.  When we had updateExprs in the Devel::ptkdb11
# package eval would turn up an undef result.
#

sub DB::updateExprs {
    my ($package) = @_ ;
    #
    # Update expressions
    # 
  $DB::window->deleteAllExprs() ;
    my ($expr, @result);

    foreach $expr ( @{$DB::window->{'expr_list'}} ) {
	next if length $expr == 0 ;

	@result = &DB::dbeval($package, $expr->{'expr'}) ;

	if( scalar @result == 1 ) {
	  $DB::window->insertExpr($DB::window->{'data_list'}, $result[0], $expr->{'expr'}, $expr->{'depth'}) ;
	}
	else {
	  $DB::window->insertExpr($DB::window->{'data_list'}, \@result, $expr->{'expr'}, $expr->{'depth'}) ;
	}
    }

} # end of updateExprs

no strict ; # turning strict off (shame shame) because we keep getting errrs for the local(*dbline)

#
# returns true if line is breakable
#

sub DB::checkdbline { # prototype this
  my ($fname, $lineno) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};

  return $dbline[$lineno] != 0 ;

} # end of checkdbline

#
# sets a breakpoint 'through' a magic 
# variable that perl is able to interpert
#
sub DB::setdbline {
  my ($fname, $lineno, $value) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};

  $dbline{$lineno} = $value ;
} # end of setdbline

sub DB::getdbline {
  my ($fname, $lineno) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};
  return $dbline{$lineno} ;
} # end of getdbline

sub DB::cleardbline {
  my ($fname, $lineno, $clearsub) = @_ ;
  local(*dbline) = $main::{'_<' . $fname};
  my $value ; # just in case we want it for something

  $value = $dbline{$lineno} ;
  delete $dbline{$lineno} ;

  &$clearsub($value) if $value && $clearsub ;

  return $value ;
} # end of cleardbline

sub DB::clearalldblines {
  my ($key, $value, $clearsub) = @_ ;
  my ($brkPt, $dbkey) ;
  local(*dbline) ;

  while ( ($key, $value) = each %main:: )  { # key loop
    next unless $key =~ /^_</ ;
    *dbline = $value ;

    foreach $dbkey (keys %dbline) {
      $brkPt = $dbline{$dbkey} ;
      delete $dbline{$dbkey} ;
      next unless $brkPt && $clearSub ;
      &$clearsub($brkPt) ; # if specificed, call the sub routine to clear the breakpoint
    }

  } # end of key loop

} # end of clearalldblines

sub DB::getdblineindexes {
  my ($fname) = @_ ;
  local(*dbline) = $main::{'_<' . $fname} ;
  return keys %dbline ;
} # end of getdblineindexes

sub DB::getbreakpoints {
  my (@fnames) = @_ ;
  my ($fname, @retList) ;

  foreach $fname (@fnames) {
    next unless  $main::{'_<' . $fname} ;
    local(*dbline) = $main::{'_<' . $fname} ;    
    push @retList, values %dbline ;
  }
  return @retList ;
} # end of getbreakpoints

#
# Construct a hash of the files
# that have breakpoints to save
#
sub DB::breakpoints_to_save {
  my ($file, @breaks, $brkPt, $svBrkPt, $list) ;
  my ($brkList) ;

  $brkList = {} ;

  foreach $file ( keys %main:: ) { # file loop
    next unless $file =~ /^_</ && exists $main::{$file} ;
    local(*dbline) = $main::{$file} ;

    next unless @breaks = values %dbline ;
    $list = [] ;
    foreach $brkPt ( @breaks ) {
      
      $svBrkPt = { %$brkPt } ; # make a copy of it's data
      
      delete $svBrkPt->{'ctl'} if exists $svBrkPt->{'ctl'} ; # remove any ref to a control
      
      push @$list, $svBrkPt ;

    } # end of breakpoint loop

    $brkList->{$file} = $list ;

  } # end of file loop

  return $brkList ;

} # end of breakpoints_to_save

#
# Restore breakpoints saved above
#
sub DB::restore_breakpoints_from_save {
  my ($brkList) = @_ ;
  my ($key, $list, $brkPt) ;
 
  while ( ($key, $list) = each %$brkList ) { # reinsert loop
    next unless exists $main::{$key} ;
    local(*dbline) = $main::{$key} ;
    
    foreach $brkPt ( @$list ) {
      next unless $dbline[$brkPt->{'line'}] ; # make sure it's still breakable
      $dbline{$brkPt->{'line'}} = { %$brkPt } ; # make a fresh copy
    }
  } # end of reinsert loop
  
} # end of restore_breakpoints_from_save ;

use strict ;

sub DB::dbint_handler {
    my($sigName) = @_ ;
    $DB::signal = 1 ;
    print "signalled\n" ;
} # end of dbint_handler


sub DB::CheckDBWindows {
  my ($Widget) = @_ ;

  if (!$Widget) {
    return 0 ;
  }

  if ( $Widget == $DB::window->{main_window} ) {
    # print "check true on main window $Widget $DB::window->{main_window}\n" ;
    return 1 ;
  }
  # print "check false on main window $Widget $DB::window->{main_window}\n" ;

  return 0 ;
} # end of CheckDBWindows

#
# Do first time initialization at the startup
# of DB::DB
#
sub DB::Initialize {
    my ($fName) = @_ ;
    my ($stateFile, $files, $expr_list, $eval_saved_text) ;
    my $restoreName ;

    $DB::isInitialized = 1 ;
    $DB::window = new Devel::ptkdb11 if !$DB::window ;
  
    Devel::ptkdb11::SetupTkEventFilter() ;

    $DB::dbint_handler_save = $SIG{'INT'} unless $DB::sigint_disable ; # saves the old handler
    $SIG{'INT'} = "DB::dbint_handler" unless $DB::sigint_disable ;
    
    # Save the file name we started up with
    $DB::startupFname = $fName ;
    
    return unless  $Devel::ptkdb11::DataDumperAvailable ;
    $stateFile = makeFileSaveName($fName) ;
    
    if( -e $stateFile && -r $stateFile ) {
	($files, $expr_list, $eval_saved_text ) = $DB::window->get_state($stateFile) ;
	&DB::restore_breakpoints_from_save($files) ;
	$DB::window->{'expr_list'} = $expr_list if defined $expr_list ;
	$DB::window->{eval_saved_text} = $eval_saved_text ;
    }

} # end of Initialize 

sub DB::makeFileSaveName {
    my ($fName) = @_ ;
    my $saveName ;

    $saveName = $fName ;
    if(  $saveName =~ /.p[lm]$/ ) {
	 $saveName =~ s/.pl$/.ptkdb/ ;
    }
    else {
	$saveName .= ".ptkdb" ;
    }

    return $saveName ;
} # end of makeFileSaveName


sub DB::SaveState {
    my ($top, $entry, $okayBtn) ;
    my ($fname, $saveSub, $cancelSub, $saveName, $eval_saved_text, $d) ;    
    my ($files);
    #
    # Create our default name
    #
    if ( defined $DB::window->{save_box} ) {
     $DB::window->{save_box}->raise ;
     $DB::window->{save_box}->focus ;
     return ;
    }

    $saveName = makeFileSaveName($DB::startupFname) ;
    
    $saveSub = sub {
      $DB::window->{'event'} = 'null' ;

	my $saveStr ;

        delete $DB::window->{save_box} ;

	if( exists $DB::window->{eval_window} ) {
	    $eval_saved_text = $DB::window->{eval_text}->get('0.0', 'end') ;
	}
	else {
	    $eval_saved_text =  $DB::window->{eval_saved_text} ;
	}
      
      $files = &DB::breakpoints_to_save() ;

      $d = Data::Dumper->new( [ $files, $DB::window->{'expr_list'}, $eval_saved_text  ], 
			      [ "files", "expr_list", "eval_saved_text" ] ) ;
      
      $d->Purity(1) ;
      if( Data::Dumper->can('Dumpx') ) {
	$saveStr = $d->Dumpx() ;
      } else {
	$saveStr = $d->Dump() ;
      }    
      
      local(*F) ;
      eval {
	open F, ">$saveName" || die "Couldn't open file $saveName" ;
	
	print F $saveStr || die "Couldn't write file" ;
	
	close F ;
      } ;
      $DB::window->DoAlert($@) if $@ ;
    } ; # end of save sub

    $cancelSub = sub {
      delete $DB::window->{'save_box'}
    } ; # end of cancel sub
    
    #
    # Create a dialog
    #
    
    $DB::window->{'save_box'} = $DB::window->simplePromptBox("Save Config?", $saveName, $saveSub, $cancelSub) ;

} # end of SaveState

sub DB::RestoreState {
    my ($top, $restoreSub) ;

    $restoreSub = sub {
	$DB::window->restoreStateFile($Devel::ptkdb11::promptString) ;
    } ;

    $top = $DB::window->simplePromptBox("Restore Config?", makeFileSaveName($DB::startupFname), $restoreSub) ;

} # end of RestoreState

sub DB::SetStepOverBreakPoint {
  my ($offset) = @_ ;
  $DB::step_over_depth = $DB::step_over_depth_saved + ($offset ? $offset : 0) ;
  $DB::step_over = 1 ;

} # end of SetStepOverBreakPoint

#
# NOTE:   It may be logical and somewhat more economical
#         lines of codewise to set $DB::step_over_depth_saved 
#         when we enter the subroutine, but this gets called
#         for EVERY callable line of code in a program that
#         is being debugged, so we try to save every line of
#         execution that we can.
#
sub DB::isBreakPoint {
    my ($fname, $line, $package) = @_ ;
    my ($brkPt) ;

    #
    # doing a step over/in
    # 

    if( $DB::single || $DB::signal ) {
      $DB::single = 0 ;
      $DB::signal = 0 ;
      $DB::step_over_depth_saved = $DB::subroutine_depth ;
      return 1 ;
    }
    $DB::step_over_depth_saved = $DB::subroutine_depth ;

    #
    # 1st Check to see if there is even a breakpoint there.  
    # 2nd If there is a breakpoint check to see if it's check box control is 'on'
    # 3rd If there is any kind of expression, evaluate it and see if it's true.  
    #
    $brkPt = &DB::getdbline($fname, $line) ;

    return 0 if( !$brkPt || !${$brkPt->{value_ref}} || !breakPointEvalExpr($brkPt, $package) ) ;

    &DB::cleardbline($fname, $line) if( $brkPt->{'type'} eq 'temp' ) ;

    return  1 ;
} # end of isBreakPoint

#
# Check the breakpoint expression to see if it
# is true.  
#
sub DB::breakPointEvalExpr {
    my ($brkPt, $package) = @_ ;
    my (@result) ;

    return 1 unless $brkPt->{expr} ; # return if there is no expression

    no strict ;

    @result = &DB::dbeval($package, $brkPt->{'expr'}) ;

    use strict ;
    
    $DB::window->DoAlert($@) if $@ ;

    return $result[0] ;

} # end of breakPointEvalExpr

#
# Check to see if we're in a different file from the last
# time that we were in DB::DB.  If so, change the file viewed
# in the code pane and scroll to the line where we've stopped
# by calling set_file, or set_line.  
#
sub DB::CheckForNewFile {
    my( $filename, $line ) = @_ ;

  if( $DB::current_file ne $filename ) {
    $DB::window->set_file($filename, $line) ; #restore any previous breakpoints
    $DB::current_file = $filename ;
  }
  else {
    $DB::window->set_line($line) ;
  }
    
} # end of CheckForNewFile

#
# Evaluate the given expression, return the result.
# MUST BE CALLED from within DB::DB in order for it
# to properly interpret the vars
#
sub DB::dbeval {
    my ($package, $expr) = @_ ;
    my (@result, $str, $saveW) ;

    no strict ;
    $saveW = $^W ; # save the state of the "warning"(-w) flag
    $^W = 0 ;

    @result = eval <<__EVAL__ ;

    package $package ;

    $expr ;

__EVAL__

    @result = ("ERROR ($@)") if $@ ;

    $^W = $saveW ; # restore the state of the "warning"(-w) flag

    use strict ;

    return @result ;
} # end of dbeval

#
# Call back we give to our 'quit' button
# and binding to the WM_DELETE_WINDOW protocol
# to quit the debugger.  
#
sub DB::dbexit {
    exit ;
} # end of dbexit

#
# This is the primary entry point for the debugger.  When a perl program
# is parsed with the -d(in our case -d:ptkdb) option set the parser will
# insert a call to DB::DB in front of every excecutable statement.  
# 
# Refs:  Progamming Perl 2nd Edition, Larry Wall, O'Reilly & Associates, Chapter 8
#
sub DB::DB {
  my ($package, $filename, $line) = caller ;
  my ($subName) ;
  my $stop ;

  # print "DB::DB called from $package, $filename, $line\n" ;

  return unless isBreakPoint($filename, $line, $package) ;

  my ($saveP) ;
  $saveP = $^P ;
  $^P = 0 ;

 $DB::on = 1 ;



  &DB::Initialize($filename) unless $DB::isInitialized ; # do some setup stuff our first time through

  if( !$DB::sigint_disable ) {
      $SIG{'INT'} = $DB::dbint_handler_save if $DB::dbint_handler_save ; # restore original signal handler
      $SIG{'INT'} = "DB::dbexit" unless  $DB::dbint_handler_save ;
  }

 $DB::window->{main_window}->raise() ; # bring us to the top make sure OUR event loop runs
 # $DB::window->{main_window}->focus() ;
 # Devel::ptkdb11::RaiseWM($DB::window->{main_window}->frame) ;

 DB::CheckForNewFile($filename, $line) ; # check to see if we're in a new file

 #  $^D = 8 ; # turn on -Dt


  #
  # Refresh the exprs to see if anything has changed
  #

  $subName = ( caller(1) )[3] ;
  updateExprs($package) ;
  &DB::updateLocals($package, $subName) ;
  #
  # Update the subroutine stack menu
  #
 $DB::window->refresh_stack_menu() ;

 $DB::window->{run_flag} = 1 ;

    my ($evt, @result) ;

  for( ; ; ) {
      #
      # we wait here for something to doe
      #
     $evt = $DB::window->main_loop() ;

     if( $evt eq 'step_over' ) {
       $DB::step_over_depth_saved = $DB::subroutine_depth ;	 
       last ;
     }

     if ($evt eq 'run' ) {
       $DB::single = 0 ;
       $DB::step_over = 0 ;
     }

      if( $evt eq 'expr' ) {
	  #
	  # Append the new expression to the list
	  # but first check to make sure that we don't
	  # already have it.
	  #
	  
	  if ( grep $_->{'expr'} eq $DB::window->{'expr'}, @{$DB::window->{'expr_list'}} ) {
	      $DB::window->DoAlert("$DB::window->{'expr'} is already listed") ;
	      next ;
	  }

	  push @{$DB::window->{'expr_list'}}, { 'expr' => $DB::window->{'expr'}, 'depth' => $Devel::ptkdb11::expr_depth } ;

	  @result = &DB::dbeval($package, $DB::window->{expr}) ;

	  if( scalar @result == 1 ) {
	    $DB::window->insertExpr($DB::window->{'data_list'}, $result[0], $DB::window->{'expr'}, $Devel::ptkdb11::expr_depth) ;
	  }
	  else {
	    $DB::window->insertExpr($DB::window->{'data_list'}, \@result, $DB::window->{'expr'}, $Devel::ptkdb11::expr_depth)  ;
	  }
	  
	  next ;
    }
     if( $evt eq 'update' ) {
	 updateExprs($package) ;
	 next ;
     }
     if( $evt eq 'reeval' ) {
	 #
	 # Reevaluate the contents of the expression eval window
	 #
	 my $txt = $DB::window->{'eval_text'}->get('0.0', 'end') ;
	 my @result = &DB::dbeval($package, $txt) ;

       $DB::window->updateEvalWindow(@result) ;

	 next ;
     }
    last ;
  }
  $^P = $saveP ;
  $SIG{'INT'} = "DB::dbint_handler"  unless $DB::sigint_disable ; # set our signal handler

 $DB::on = 0 ;
} # end of DB

#
# This is another place where we'll try and keep the
# code as 'lite' as possible to prevent the debugger
# from slowing down the user's application
#
# When a perl program is parsed with the -d(in our case a -d:ptkdb) option
# the parser will route all subroutine calls through here, setting $DB::sub
# to the name of the subroutine to be called, leaving it to the debugger to
# make the actual subroutine call and do any pre or post processing it may
# need to do.  In our case we take the oppurtunity to track the depth of the call
# stack so that we can update our 'Stack' menu when we stop.  
#
# Refs:  Progamming Perl 2nd Edition, Larry Wall, O'Reilly & Associates, Chapter 8
#
#
sub DB::sub {
    my ($result, @result) ;
    #my ($package, $filename, $line, $subName) = caller ;
    #print "sub called for $package, $filename, $line, $subName\n" ;

    if ( $DB::step_over ) {
      $DB::single = 0 ;
      $DB::step_over = 0 ;
    }

#
# See NOTES(1)
#
    if( wantarray ) {
      $DB::subroutine_depth += 1 unless $DB::on ;
      no strict ; # otherwise perl gripes about calling the sub by the reference
      @result = &$DB::sub ; # call the subroutine by name
      use strict ;
      $DB::subroutine_depth -= 1 unless $DB::on ;
      $DB::single = 1 if ($DB::step_over_depth >= $DB::subroutine_depth ) ;   
      return @result ;
    }
    else {
      $DB::subroutine_depth += 1 unless $DB::on ;
      no strict ; # otherwise perl gripes about calling the sub by the reference
      $result = &$DB::sub ; # call the subroutine by name
      use strict ;
      $DB::subroutine_depth -= 1 unless $DB::on ;
      $DB::single = 1 if ($DB::step_over_depth >= $DB::subroutine_depth ) ;
      return $result ;	
    }
	
} # end of sub 

# Autoload methods go after __END__, and are processed by the autosplit program.

1;

__END__

#
# This supports the File -> Open menu item
# We create a new window and list all of the files
# that are contained in the program.  We also
# pick up all of the perlTk files that are supporting
# the debugger.  
#
sub DoOpen {
    my $self = shift ;
    my ($topLevel, $listBox, $frame, $selectedFile, @fList) ;

    #
    # subroutine we call when we've selected a file
    #

    my $chooseSub = sub { $selectedFile = $listBox->get('active') ;
			  &DB::CheckForNewFile($selectedFile, 0) ;
			  destroy $topLevel ; 
		      } ;

    #
    # Take the list the files and resort it.  
    # we put all of the local files first, and
    # then list all of the system libraries.
    #
    @fList = sort { 
	# sort comparison function block
	my $fa = substr($a, 0, 1) ;
	my $fb = substr($b, 0, 1) ;

	return $a cmp $b if ($fa eq '/') && ($fb eq '/') ;

	return -1 if ($fb eq '/') && ($fa ne '/') ;
	return 1 if ($fa eq '/' ) && ($fb ne '/') ;

	return $a cmp $b ;

    } grep s/^_<//, keys %main:: ;

    #
    # Create a list box with all of our files
    # to select from
    #
    $topLevel = $self->{main_window}->Toplevel(-title => "File Select", -overanchor => 'cursor') ;

    $listBox = $topLevel->Scrolled('Listbox', 
				   @Devel::ptkdb11::scrollbar_cfg,
				   font => $Devel::ptkdb11::expression_text_font,
				   'width' => 30)->pack(side => 'top', fill => 'both', -expand => 'y') ;

    # Bind a double click on the mouse button to the same action
    # as pressing the Okay button

    $listBox->bind('<Double-Button-1>' => $chooseSub) ;
  
    $listBox->insert('end', @fList) ;

    $topLevel->Button( text => "Okay", -command => $chooseSub, font => $Devel::ptkdb11::button_font,
		       )->pack(side => 'left', fill => 'both', -expand => 'y') ;

    $topLevel->Button( text => "Cancel", font => $Devel::ptkdb11::button_font,
		       -command => sub { destroy $topLevel ; } )->pack(side => 'left', fill => 'both', -expand => 'y') ;
} # end of DoOpen


#
# This is our callback from a double click in our
# HList.  A click in an expanded item will delete
# the children beneath it, and the next time it
# updates, it will only update that entry to that
# depth.  If an item is 'unexpanded' such as 
# a hash or a list, it will expand it one more
# level.  How much further an item is expanded is
# controled by package variable $Devel::ptkdb11::add_expr_depth
#
sub expr_expand {
    my ($path) = @_ ;
    my $hl = $DB::window->{'data_list'} ;
    my ($parent, $root, $index, @children, $depth) ;

    $parent = $path ;
    $root = $path ;
    $depth = 0 ;

    for( $root = $path ; defined $parent && $parent ne "" ; $parent = $hl->infoParent($root) ) {
	$root = $parent ;
	$depth += 1 ;
    } #end of root search

    #
    # Determine the index of the root of our expression
    #
    $index = 0 ;
    for( @{$DB::window->{'expr_list'}} ) {
	last if $_->{'expr'} eq $root ;
	$index += 1 ;
    }

    #
    # if we have children we're going to delete them
    #

    @children = $hl->infoChildren($path) ;

    if( scalar @children > 0 ) {

	$hl->deleteOffsprings($path) ;

        $DB::window->{'expr_list'}->[$index]->{'depth'} = $depth - 1 ; # adjust our depth
    }
    else {
	#
	# Delete the existing tree and insert a new one
	#
	$hl->deleteEntry($root) ;
	$hl->add($root, -at => $index) ;
        $DB::window->{'expr_list'}->[$index]->{'depth'} += $Devel::ptkdb11::add_expr_depth ;
	#
	# Force an update on our expressions
	#
      $DB::window->{'event'} = 'update' ;
    }
} # end of expr_expand

sub DoAlert {
    my($self, $msg, $title) = @_ ;
    my($dlg) ;
    my $okaySub = sub {
	destroy $dlg ;
    } ;

    $dlg = $self->{main_window}->Toplevel(-title => $title || "Alert", -overanchor => 'cursor') ;

    $dlg->Label( 'text' => $msg )->pack( side => 'top' ) ;

    $dlg->Button( 'text' => "Okay", -command => $okaySub )->pack( side => 'top' )  ;
    $dlg->bind('<Return>', $okaySub) ;
} # end of DoAlert

sub simplePromptBox {
    my ($self, $title, $defaultText, $okaySub, $cancelSub) = @_ ;
    my ($top, $entry, $okayBtn) ;

    $top = $self->{main_window}->Toplevel(-title => $title, -overanchor => 'cursor' ) ;

    $Devel::ptkdb11::promptString = $defaultText ;

    $entry = $top->Entry('-textvariable' => 'Devel::ptkdb11::promptString')->pack('side' => 'top', fill => 'both', -expand => 'y') ;
    
    
    $okayBtn = $top->Button( text => "Okay", font => $Devel::ptkdb11::button_font, -command => sub {  &$okaySub() ; $top->destroy ;}
			     )->pack(side => 'left', fill => 'both', -expand => 'y') ;
    
    $top->Button( text => "Cancel", -command => sub { &$cancelSub() if $cancelSub ; $top->destroy() }, font => $Devel::ptkdb11::button_font,
		  )->pack(side => 'left', fill => 'both', -expand => 'y') ;
    
    $entry->icursor('end') ;
    
    $entry->selectionRange(0, 'end') if $entry->can('selectionRange') ; # some win32 Tk installations can't do this

    $entry->focus() ;

    return $top ;
 
} # end of simplePromptBox

sub get_entry_text {
    my($self) = @_ ;
    
    return $self->{entry}->get() ; # get the text in the entry
} # end of get_entry_text

#
# remove_ctl_from_breakpoints(@fnames)
#
#   Removes all of the control widgets from each
# breakpoint specified in $fname
#
sub remove_ctl_from_breakpoints {

  for ( DB::getbreakpoints(@_) ) {
    next unless  $_ && exists $_->{'ctl'} ;
    delete $_->{'ctl'} ;
  }

} # end of remove_ctl_from_breakpoints


#
# Clear any text that is in the entry field.  If there
# was any text in that field return it.  If there
# was no text then return any selection that may be active.  
#
sub clear_entry_text {
    my($self) = @_ ;
    my $str =  $self->{'entry'}->get() ;
    $self->{'entry'}->delete(0, 'end') ;

    #
    # No String
    # Empty String
    # Or a string that is only whitespace
    #
    if( !$str || $str eq "" || $str =~ /^\s+$/ ) {
	#
	# If there is no string or the string is just white text
	# Get the text in the selction( if any)
	# 
	if( $self->{text}->tagRanges('sel') ) { # check to see if 'sel' tag exists (return undef value)
	    $str = $self->{text}->get("sel.first", "sel.last") ; # get the text between the 'first' and 'last' point of the sel (selection) tag
	}
	# If still no text, bring the focus to the entry
	elsif( !$str || $str eq "" || $str =~ /^\s+$/ ) {
	  $self->{'entry'}->focus() ;
	  $str = "" ;
	}
    }
    #
    # Erase existing text
    #
    return $str ;
} # end of clear_entry_text

#
# insert a breakpoint control into our breakpoint list.  
# returns a handle to the control
#
#  Expression, if defined, is to be evaluated at the breakpoint
# and execution stopped if it is non-zero/defined.
#
# If action is defined && True then it will be evalled
# before continuing.  
#
sub insertBreakpoint {
    my ($self, $fname, @brks) = @_ ;
    my(@ctlList) ;

    while( @brks ) {
	my($index, $setValue, $expression, $action, $isAction) = splice @brks, 0, 5 ; # take args 5 at a time
	my $brkPt = {} ; 

	my $value = $setValue ;
	@$brkPt{'type', 'line',  'expr',      'isAction', 'action', 'value_ref', 'fname'} =
	       ('user',  $index, $expression, $isAction,  $action,  \$value,     $fname) ;
	
	my $ctl = $self->{text}->Checkbutton( 'text' => $isAction ? 'A' : 'B', 
					   command => $action ,
					   -font => $Devel::ptkdb11::code_text_font,
					   variable => $brkPt->{value_ref}
					   ) ;
	
	$brkPt->{'ctl'} = $ctl ;
	push @ctlList, $ctl ;
	
	# Syntax of text index is lineno.column
	
	$self->{text}->window('create', "$index.$Devel::ptkdb11::linenumber_offset", -window => $ctl) ;

	#
	# If there's an expression controlling this breakpoint
	# insert the text of this expression in italics at the end 
	# of the line.  
	#
	if( $expression ) {
	    $brkPt->{brkTextStart} = $self->{text}->index("$index.0 lineend") ;
	    $self->{text}->tagAdd('brkPtExpr', $brkPt->{brkTextStart}, "$self->{current_line}.0 lineend") ;
	    $self->{text}->tagConfigure('brkPtExpr', @Devel::ptkdb11::brkExprTagCfg) ;
	    $self->{text}->insert("$index.0 lineend", "   $expression", 'brkPtExpr') ; # pad it with some spaces
	    $brkPt->{brkTextEnd} = $self->{text}->index("$index.0 lineend") ;
	}	

	&DB::setdbline($fname, $index, $brkPt) ;
	
    } # end of loop

    return $ctlList[0] unless wantarray ;

    return @ctlList ;
    
} # end of insertBreakpoint

#
# Supporting the "Run To Here..." command
#
sub insertTempBreakpoint {
    my ($self, $fname, $index) = @_ ;
    my ($val) ;
    return if( &DB::getdbline($fname, $index) ) ; # we already have a breakpoint here

    my $brkPt = {} ; 
    $brkPt->{'type'} = 'temp' ; # temporary breakpoint will be removed when we hit it
    $brkPt->{'line'} = $index ;
    $val = 1 ;
    $brkPt->{value_ref} = \$val ; # we 'fake' a control box value
    &DB::setdbline($fname, $index, $brkPt) ;

} # end of insertTempBreakpoint

sub reinsertBreakpoints {
    my ($self, $fname) = @_ ;
    my ($brkPt) ;

    foreach $brkPt ( &DB::getbreakpoints($fname) ) {
	#
	# Our breakpoints are indexed by line
	# therefore we can have 'gaps' where there
	# lines, but not breaks set for them.
	#
	next unless defined $brkPt ;
	
	$self->insertBreakpoint($fname, $brkPt->{line}, ${$brkPt->{'value_ref'}}, $brkPt->{expr}, $brkPt->{action}, $brkPt->{isAction}) if( $brkPt->{'type'} eq 'user' ) ;
	$self->insertTempBreakpoint($fname, $brkPt->{line}) if( $brkPt->{'type'} eq 'temp' ) ;
    } # end of reinsert loop

} # end of reinsertBreakpoints

#
# Remove a breakpoint from the current window
#
sub removeBreakpoint {
    my ($self, $fname, @idx) = @_ ;
    my ($idx) ;

    foreach $idx (@idx) {
	next unless defined $idx ;
	my $brkPt = &DB::getdbline($fname, $idx) ;
	next unless $brkPt ; # if we do not have an entry, return
	
	$self->{text}->delete($brkPt->{ctl}) ;
	
	# Delete the ext associated with the breakpoint expression (if any)

	$self->{text}->delete($brkPt->{brkTextStart}, $brkPt->{brkTextEnd}) if( $brkPt->{expr} ) ;	
	&DB::cleardbline($fname, $idx) ;
    }
    
    return ;
} # end of removeBreakpoint

sub removeAllBreakpoints {
    my ($self, $fname) = @_ ;
    
    $self->removeBreakpoint($fname, &DB::getdblineindexes($fname)) ;

} # end of removeAllBreakpoints

sub getExprs {
    my ($self) = @_ ;
    
    return $self->{'data_list'}->info('children') ;
} # end of getExprs

#
# Delete expressions prior to an update
#
sub deleteAllExprs {
     my ($self) = @_ ;
     $self->{'data_list'}->delete('all') ;
} # end of deleteAllExprs

sub deleteExpr {
    my ($self) = @_ ;
    my ($entry) ;
    my @sList = $self->{'data_list'}->info('select') ;
    my ($i) ;

    #
    # if we're deleteing a top level expression
    # we have to take it out of the list of expressions
    #

    my @indexes ; # indexes we want to remove
    foreach $entry ( @sList ) {
	next if ($entry =~ /\//) ; # goto next expression if we're not a top level ( expr/entry)
	$i = 0 ;
	grep { push @indexes, $i if ($_->{'expr'} eq $entry) ; $i++ ; } @{$self->{'expr_list'}} ;
    } # end of check loop
    
    # now take out our list of indexes ;

    for( $i = 0 ; $i <= $#indexes ; $i++ ) {
	 splice @{$self->{'expr_list'}}, $indexes[$i] - $i, 1 ;
    }

    for( @sList ) {
	$self->{'data_list'}->delete('entry', $_) ;
    }
}

sub insertExpr {
    my($self, $dl, $topRef, $name, $depth, $dirPath) = @_ ;
    my($theRef, $label, $type) ;

    #
    # Add data new data entries to the bottom
    # 
    $dirPath = "" unless defined $dirPath ;

    $theRef = $topRef ;
    $label = "" ;

    while( ref $theRef eq 'SCALAR' ) {
	$theRef = $$theRef ;
    }
    
  REF_CHECK: for( ; ; ) {
      $type = ref $theRef ;
      last unless ($type  eq "REF")  ;
      $theRef = $$theRef ; # dref again
      $label .= "\\" ; # append a 
    }

    if( !$type || $type eq "" || $type eq "GLOB" || $type eq "CODE") {
	my $saveW = $^W ;
	$^W = 0 ;
	eval {
	    if( !defined $theRef ) {
		$dl->add($dirPath . "$name", -text => "$name = $label" . "undef") ;
	    }
	    else {
		$dl->add($dirPath . "$name", -text => "$name = $label$theRef") ;
	    }
	} ;
	$^W = $saveW ;
	$self->DoAlert($@) if $@ ;
	return ;
    }

# 
# Anything else at this point is
# either a 'HASH' or an object
# of some kind.
#
    if( $type eq 'ARRAY' ) {
	my ($r, $idx) ;
	$idx = 0 ;
	eval {
	    $dl->add($dirPath . $name, -text => "$name = $theRef") ;
	} ;
	$self->DoAlert($@) if $@ ;
	foreach $r ( @{$theRef} ) {
	    $self->insertExpr($dl, $r, "[$idx]", $depth-1, $dirPath . $name . "/") unless $depth == 0 ;
	    $idx += 1 ;
	}
	return ;
    } # end of array case

    if(  "$theRef" !~ /HASH\050\060x[0-9a-f]*\051/o ) {
	$dl->add($dirPath . "$name", -text => "$name = $theRef") ;
	return ;
    }

    my($r, @theKeys, $idx) ;
    $idx = 0 ;
    @theKeys = keys %{$theRef} ;

    $dl->add($dirPath . "$name", -text => "$name = $theRef") ;
    foreach $r ( values %{$theRef} ) {
	$self->insertExpr($dl, $r, "$theKeys[$idx]", $depth-1, $dirPath . $name . "/") unless $depth == 0 ;
	$idx += 1 ;
    }
    return ;
} # end of insertExpr

#
# We're setting the line where we are stopped.  
# Create a tag for this and set it as bold.  
#
sub set_line {
    my ($self, $lineno) = @_ ;
    my $text = $self->{text} ;

    return if( $lineno <= 0 ) ;

    if( $self->{current_line} > 0 ) {
	$text->tagRemove('stoppt', "$self->{current_line}.0 linestart", "$self->{current_line}.0 lineend") ;
    }
    $self->{current_line} = $lineno ;
    $text->tagAdd('stoppt', "$self->{current_line}.0 linestart", "$self->{current_line}.0 lineend") ;
    $self->{text}->tagConfigure('stoppt', @Devel::ptkdb11::stop_tag_cfg) ;

    $self->{text}->see("$self->{current_line}.0 linestart") ;
} # end of set_line

#
# Set the file that is in the code window.
#
# $fname the 'new' file to view
# $line the line number we're at
# $brkPts any breakpoints that may have been set in this file
#
sub set_file {
    my ($self, $fname, $line) = @_ ;
    my ($line_cnt, $i, $j, $lineStr, $offset) ;
    my $dbline = $main::{'_<' . $fname};

    if( $fname eq $self->{current_file} ) {
	$self->set_line($line) ;
	return ;
    } ;

    $fname =~ s/^\-// ; # Tk does not like leadiing '-'s 
    $self->{main_window}->configure('-title' => $fname) ;

    # Erase any existing breakpoints by replacing the table's reference

    # we're going to erase the text, we don't want to be hanging onto controls that
    # could become bogus
    remove_ctl_from_breakpoints($self->{current_file}) ; 
    
    # Erase any existing text

    $self->{text}->delete('0.0','end') ; 

    $line_cnt = 0 ;
    $i = 0 ;
    $offset = 0 ;

    #
    # with the #! /usr/bin/perl -d:ptkdb at the header of the file
    # we've found that with various combinations of other options the
    # files haven't come in at the right offsets
    #

    $offset = 1 if $dbline->[1] =~ /use\s+.*Devel::_?ptkdb/ ;

    $j = scalar @$dbline ;
    for( $i = 1 ; $i < $j ; $i++ ) {
	$lineStr = "" ; # start with a fresh line
	$lineStr = sprintf($Devel::ptkdb11::linenumber_format, $i) if $Devel::ptkdb11::linenumber_format ;
	$lineStr .= $dbline->[$i + $offset] if $dbline->[$i + $offset] ;
	$lineStr .= "\n" if $lineStr !~ /\n$/ ; # append a \n if there isn't one already
 	$self->{text}->insert('end', $lineStr) ;
 	$line_cnt += 1 ;
    }

    $self->set_line($line) ;

    #
    # Reinsert breakpoints (if info provided)
    # return the controls that are generated
    #
    $self->{current_file} = $fname ;
 
    return $self->reinsertBreakpoints($fname) ;

} # end of set_file

#
# Get the current line that the insert cursor is in
#
sub get_lineno {
    my ($self) = @_ ; 
    my ($info) ;
    
    $info = $self->{text}->index('insert') ; # get the location for the insertion point
    $info =~ s/\..*$/\.0/ ;

    return int $info ;
} # end of get_lineno

sub GotoLine {
    my ($self) = @_ ;
    my ($topLevel) ;

    if( $self->{goto_window} ) {
	$self->{goto_window}->raise() ;
	$self->{goto_text}->focus() ;
	return ;
    }
    

    # subroutine we exect when the 'Okay' Button is pressed.  
    my $okaySub = sub {
	# Get the text in the entry
	my $txt = $self->{goto_text}->get() ;
	
	$txt =~ s/(\d*).*/$1/ ; # take the first blob of digits
	if( $txt eq "" ) {
	    print "invalid text range\n" ;
	    return if $txt eq "" ;
	}

	$self->{text}->see("$txt.0") ;

	$self->{goto_text}->selectionRange(0, 'end') if $self->{goto_text}->can('selectionRange')

    } ;

    #
    # Construct a dialog that has an
    # entry field, okay and cancel buttons
    #
 
     $topLevel = $self->{main_window}->Toplevel(-title => "Goto Line?", -overanchor => 'cursor') ;

    $self->{goto_text} = $topLevel->Entry()->pack(side => 'top', fill => 'both', -expand => 'x') ;

    $self->{goto_text}->bind('<Return>', $okaySub) ; # make a CR do the same thing as pressing an okay

    $self->{goto_text}->focus() ;

    # Bind a double click on the mouse button to the same action
    # as pressing the Okay button

    $topLevel->Button( text => "Okay", -command => $okaySub, font => $Devel::ptkdb11::button_font,
		       )->pack(side => 'left', fill => 'both', -expand => 'y') ;

    #
    # Subroutone called when the 'Dismiss'
    # button is pushed.
    #
    my $dismissSub = sub {
	delete $self->{goto_text} ;
	destroy {$self->{goto_window}} ;
	delete $self->{goto_window} ; # remove the entry from our hash so we won't
    } ;

    $topLevel->Button( text => "Dismiss", font => $Devel::ptkdb11::button_font,
		       -command => $dismissSub )->pack(side => 'left', fill => 'both', -expand => 'y') ;

    $topLevel->protocol('WM_DELETE_WINDOW', sub { destroy $topLevel ; } ) ;

    $self->{goto_window} = $topLevel ;

} # end of GotoLine

#
# Support for the Find Text... Menu command
#
sub FindText {
    my ($self) = @_ ;
    my ($top, $entry, $rad1, $rad2, $chk, $regExp, $frm, $okayBtn) ;

    #
    # if we already have the Find Text Window
    # open don't bother openning another, bring
    # the existing one to the front.  
    #
    if( $self->{find_window} ) {
	$self->{find_window}->raise() ;
	$self->{find_text}->focus() ;
	return ;
    }

    $self->{search_start} = $self->{text}->index('insert') if( $self->{search_start} eq "" ) ;

    #
    # Subroutine called when the 'okay' button is pressed
    #
    my $okaySub = sub { 
	my (@switches, $result) ;
	my $txt = $self->{find_text}->get() ;

	return if $txt eq "" ; 

	push @switches, "-forward" if $self->{fwdOrBack} eq "forward" ;
	push @switches, "-backward" if $self->{fwdOrBack} eq "backward" ;
       
	if( $regExp ) {
	    push @switches, "-regexp" ;
	}
	else {
	    push @switches, "-nocase" ; # if we're not doing regex we may as well do caseless search
	}

	$result = $self->{text}->search(@switches, $txt, $self->{search_start}) ;
	if( !$result || $result eq "" ) {
	  # No Text was found
	  $okayBtn->flash() ;
	  $okayBtn->bell() ;
	  $self->{text}->tagDelete('search_tag') if( exists $self->{search_tag} ) ;
	}
	else { # text found
	    $self->{text}->see($result) ;
	    # set the insertion of the text as well
	    $self->{text}->markSet('insert' => $result) ;
	    my $len = length $txt ;

	    $self->{text}->tagDelete('search_tag') if( exists $self->{search_tag} ) ;

	    if( $self->{fwdOrBack} eq "forward" ) {
		$self->{search_start}  = "$result +$len chars" if $self->{fwdOrBack} eq "forward" ;
		$self->{search_tag} = [ $result, $self->{search_start} ]  ;
	    }
	    else {
		# backwards search 
		$self->{search_start}  = "$result -$len chars" if $self->{fwdOrBack} eq "backward" ;
		$self->{search_tag} = [ $result, "$result +$len chars"  ]  ;
	    }

	    $self->{text}->tagAdd('search_tag', @{$self->{search_tag}}) ;
	    $self->{text}->tagConfigure('search_tag', "-background", "green") ;
	} # end of text found
	$self->{find_text}->selectionRange(0, 'end') if $self->{find_text}->can('selectionRange') ;

	} ; # end of $okaySub

    #
    # Construct a dialog that has an entry field, forward, backward, regex option, okay and cancel buttons
    #
    #
    $top = $self->{main_window}->Toplevel(-title => "Find Text?") ;

    $self->{find_text} = $top->Entry()->pack('side' => 'top', fill => 'both', -expand => 'y') ;
    $self->{find_text}->bind('<Return>', $okaySub) ;
    
    $frm = $top->Frame()->pack('side' => 'top', fill => 'both', -expand => 'y') ;

    $self->{fwdOrBack} = 'forward' ;
    $rad1 = $frm->Radiobutton('text' => "Forward", 'value' => "forward", 'variable' => \$self->{fwdOrBack}) ;
    $rad1->pack(side => 'left', fill => 'both', -expand => 'x') ;
    $rad2 = $frm->Radiobutton('text' => "Backward", 'value' => "backward", 'variable' => \$self->{fwdOrBack}) ;
    $rad2->pack(side => 'left', fill => 'both', -expand => 'x') ;

    $regExp = 0 ;
    $chk = $frm->Checkbutton('text' => "RegExp", 'variable' => \$regExp) ;
    $chk->pack(side => 'left', fill => 'both', -expand => 'x') ;

    # Okay and cancel buttons

    # Bind a double click on the mouse button to the same action
    # as pressing the Okay button

    $okayBtn = $top->Button( text => "Okay", -command => $okaySub, font => $Devel::ptkdb11::button_font,
		       )->pack(side => 'left', fill => 'both', -expand => 'y') ;

    #
    # Subroutine called when the 'Dismiss' button
    # is pushed.  
    #
    my $dismissSub = sub {
	$self->{search_start} = "" ;
	destroy {$self->{find_window}} ; 
	$self->{text}->tagDelete('search_tag') if( exists $self->{search_tag} ) ;
	delete $self->{search_tag} ;
	delete $self->{find_window} ;
    } ;

    $top->Button( text => "Dismiss", font => $Devel::ptkdb11::button_font,
		  -command => $dismissSub)->pack(side => 'left', fill => 'both', -expand => 'y') ;

    $top->protocol('WM_DELETE_WINDOW', $dismissSub) ;

    $self->{find_text}->focus() ;

    $self->{find_window} = $top ;

} # end of FindText

sub main_loop {
    my ($self) = @_ ;
    my ($evt, $str, $result) ;
    
  SWITCH: for ($self->{'event'} = 'null' ; ; $self->{'event'} = 'null' ) {
      Tk::DoOneEvent(0);
	$evt = $self->{'event'} ;
	$evt =~ /step_over/o && do { last SWITCH ; } ;
	$evt =~ /null/o && do { next SWITCH ; } ;
	$evt =~ /run/o && do { last SWITCH ; } ;
	$evt =~ /quit/o && do { exit ; } ;
	$evt =~ /expr/o && do { return $evt ; } ; # adds an expression to our expression window
	$evt =~ /update/o && do { return $evt ; } ; # forces an update on our expression window
	$evt =~ /reeval/o && do { return $evt ; } ; # updated the open expression eval window
  } # end of switch block
    return $evt ;
} # end of main_loop

#
# $subStackRef   A reference to the current subroutine stack
#

sub goto_sub_from_stack {
    my ($self, $f, $lineno) = @_ ;
    $self->set_file($f, $lineno) ;
} # end of goto_sub_from_stack ;

sub refresh_stack_menu {
    my ($self) = @_ ;
    my ($str, $name, $i, $sub_offset, $subStack) ;

    #
    # CAUTION:  In the effort to 'rationalize' the code
    # are moving some of this function down from DB::DB
    # to here.  $sub_offset represents how far 'down'
    # we are from DB::DB.  The $DB::subroutine_depth is
    # tracked in such a way that while we are 'in' the debugger
    # it will not be incremented, and thus represents the stack depth
    # of the target program.  
    #
    $sub_offset = 1 ;
    $subStack = [] ;

    # clear existing entries

    for( $i = 0 ; $i <= $DB::subroutine_depth ; $i++ ) {
	my ($package, $filename, $line, $subName) = caller $i+$sub_offset ;
	last if !$subName ;
	push @$subStack, { 'name' => $subName, 'pck' => $package, 'filename' => $filename, 'line' => $line } ;
    }

    $self->{stack_menu}->menu->delete(0, 'last') ; # delete existing menu items

    for( $i = 0 ; $subStack->[$i] ; $i++ ) {

	$str = defined $subStack->[$i+1] ? "$subStack->[$i+1]->{name}" : "MAIN" ;

	my ($f, $line) = ($subStack->[$i]->{filename}, $subStack->[$i]->{line}) ; # make copies of the values for use in 'sub'
	$self->{stack_menu}->command(-label => $str, -command => sub { $self->goto_sub_from_stack($f, $line) ; } ) ;
    }
} # end of refresh_stack_menu

no strict ;

sub get_state {
    my ($self, $fname) = @_ ;
    my ($val) ;
    local($files, $expr_list, $eval_saved_text) ;
 
    do "$fname"  ;

    if( $@ ) {
      $self->DoAlert($@) ;
	return (undef, undef) ;
    }

    return ($files, $expr_list, $eval_saved_text) ;
} # end of get_state

use strict ;

sub restoreStateFile {
    my ($self, $fname) = @_ ;
    local(*F) ;
    my ($saveCurFile, $s, @n, $n) ;

    if (!(-e $fname && -r $fname)) {
      $self->DoAlert("$fname does not exist") ;
      return ;
    }

    my ($files, $expr_list, $eval_saved_text) = $self->get_state($fname) ;
    my ($f, $brks) ;

    return unless defined $files || defined $expr_list ;

    &DB::restore_breakpoints_from_save($files) ;

    #
    # This should force the breakpoints to be restored
    #
    $saveCurFile = $self->{current_file} ;
    $self->{eval_saved_text} = $eval_saved_text ;

    $self->{current_file} = "" ;
    $self->{'expr_list'} = $expr_list ;
    $self->{eval_saved_text} = $eval_saved_text ;
    $self->set_file($saveCurFile, $self->{current_line}) ;

    $self->{'event'} = 'update' ;
} # end of retstoreState

sub updateEvalWindow {
    my ($self) = shift ;
    my @result = @_ ;
    my ($index, $index2, $leng, $str, $txt, $d) ;

    $leng = 0 ;
    for( @result ) {
        if( !$Devel::ptkdb11::DataDumperAvailable || !$Devel::ptkdb11::useDataDumperForEval ) {
	    $str = "$_\n" ;
	}
	else {
	    $d = Data::Dumper->new([ $_ ]) ;
	    $d->Indent($Devel::ptkdb11::eval_dump_indent) ;
	    $d->Terse(1) ;
	    if( Data::Dumper->can('Dumpx') ) { 
		$str = $d->Dumpx( $_ ) ;
	    }
	    else {
		$str = $d->Dump( $_ ) ;
	    }
	}
	$leng += length $str ;
	$self->{eval_results}->insert('end', $str) ;
    }
} # end of updateEvalWindow

sub setupEvalWindow {
    my($self) = @_ ;
    my($top, $dismissSub) ;
    my $f ;
    $self->{eval_window}->focus(), return if exists $self->{eval_window} ; # already running this window?

    $top = $self->{main_window}->Toplevel(-title => "Evaluate Expressions...") ;
    $self->{eval_window} = $top ;
    $self->{eval_text} = $top->Scrolled('TextUndo',
					@Devel::ptkdb11::scrollbar_cfg,
					width => 50,
					height => 10,
					-wrap => "none",
					-font => $Devel::ptkdb11::eval_text_font
					)->packAdjust('side' => 'top', 'fill' => 'both', -expand => 'y') ;

    $self->{eval_text}->insert('end', $self->{eval_saved_text}) if exists $self->{eval_saved_text} && defined $self->{eval_saved_text} ;

    $top->Label(-text, "Results:")->pack('side' => 'top', 'fill' => 'both', -expand => 'n') ;

    $self->{eval_results} = $top->Scrolled('Text',
					   @Devel::ptkdb11::scrollbar_cfg,
					   width => 50,
					   height => 10,
					   -wrap => "none",
					   -font => $Devel::ptkdb11::eval_text_font
					   )->pack('side' => 'top', 'fill' => 'both', -expand => 'y') ;


    $top->Button(-text => 'Eval...', -command => sub { $DB::window->{event} = 'reeval' ; }
		 )->pack('side' => 'left', 'fill' => 'x', -expand => 'y') ;

    $dismissSub = sub { 
	$self->{eval_saved_text} = $self->{eval_text}->get('0.0', 'end') ;
	$self->{eval_window}->destroy ;
	delete $self->{eval_window} ;
    } ;

    $top->protocol('WM_DELETE_WINDOW', $dismissSub ) ;

    $top->Button(-text => 'Clear Eval', -command => sub { $self->{eval_text}->delete('0.0', 'end') }
		 )->pack('side' => 'left', 'fill' => 'x', -expand => 'n') ;

    $top->Button(-text => 'Clear Results', -command => sub { $self->{eval_results}->delete('0.0', 'end') }
		 )->pack('side' => 'left', 'fill' => 'x', -expand => 'n') ;

    $top->Button(-text => 'Dismiss', -command => $dismissSub)->pack('side' => 'left', 'fill' => 'x', -expand => 'y') ;

} # end of setupEvalWindow ;


sub filterBreakPts {
    my ($breakPtsListRef, $fname) = @_ ;
    my $dbline = $main::{'_<' . $fname}; # breakable lines
    my $saveW ;
    #
    # Go through the list of breaks and take out any that
    # are no longer breakable
    #
    $saveW = $^W ; # we're getting some warnings about using the line array like this
    $^W = 0 ;
    for( @$breakPtsListRef ) {
	next unless defined $_ ;

	next if $dbline->[$_->{'line'}] != 0 ; # still breakable

	$_ = undef ;
    }
    $^W = $saveW ;

    
} # end of filterBreakPts

sub DoAbout {
  my $self = shift ;
  my $str = "ptkdb $DB::VERSION\nCopyright 1998 by Andrew E. Page\nFeedback to aep\@world.std.com\n\n" ;
  my $threadString = "" ;
  
  $threadString = "Threads Available" if $Config::Config{usethreads} ;
  $threadString = " Thread Debugging Enabled" if $DB::usethreads ;
  
  $str .= <<"__STR__" ;
This program is free software; you can redistribute it and/or modify
    it under the terms of either:

	a) the GNU General Public License as published by the Free
	Software Foundation; either version 1, or (at your option) any
	later version, or

	b) the "Artistic License" which comes with this Kit.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
    the GNU General Public License or the Artistic License for more details.

OS $^O
Tk Version $Tk::VERSION
Perl Version $]
$threadString
__STR__

    $self->DoAlert($str, "About ptkdb") ;
} # end of DoAbout


#
# return 1 if succesfully set,
# return 0 if otherwise
#
sub SetBreakPoint {
    my ($self, $isTemp) = @_ ;
    my $dbw = $DB::window ;
    my $lineno = $dbw->get_lineno() ;
    my $expr = $dbw->clear_entry_text() ;
    my $saveW = $^W ;

    $^W = 0 ;
    if( !&DB::checkdbline($DB::current_file, $lineno) ) {
	$^W = $saveW ;
	$dbw->DoAlert("line $lineno in $DB::current_file is not breakable") ;
	return 0 ;
    }

    $^W = $saveW ;
    if( !$isTemp ) {
	$dbw->insertBreakpoint($DB::current_file, $lineno, 1, $expr) ;
	# print "attempting break on line $lineno in $DB::current_file\n" ;
	# &DB::setdbline($DB::current_file, $lineno, 1) ;
	return 1 ;
    }
    else {
	$dbw->insertTempBreakpoint($DB::current_file, $lineno) ;
	return 1 ;
    }

    return 0 ;
} # end of SetBreakPoint

sub UnsetBreakPoint {
      my ($self) = @_ ;
      my $lineno = $self->get_lineno() ;
 
      $self->removeBreakpoint($DB::current_file, $lineno) ;
} # end of UnsetBreakPoint

