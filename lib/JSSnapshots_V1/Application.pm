package JSSnapshots::Application ;

=pod

=head1 NAME

JSSnapshots::Application - Module to process application snapshots

=head1 VERSION
	Version 	: $Revision: 58 $
	Last modified 	: $Date: 2014-05-09 11:38:05 +1000 (Fri, 09 May 2014) $
	URL		: $HeadURL: file:///D:%5CSVN/PerlMod/JSSnapshots/Application.pm $ ;

=head1 DESCRIPTION

This module parse the application snapshot file, and write out statistics to Application.xls.  Use EXCEL facilities to sort/filter.

=head1 METHODS

=cut

use JSSnapshots::Cfg ;
use JSSnapshots::Functions qw(ratio hitrate commafy sum_of_diff tmdiff orderby hashdiff resolve_formula_fields evalstr inputcheck);
use strict ;
use Time ;
use List::MoreUtils qw(uniq);

my $section = "application" ;
my $cfg = new Cfg() ;  

sub new 
{
	my ( $class , $xls  ) = @_ ;
	
  	my $self = () ;
	my $section = "dbsnap" ;
	$self->{XLS} = $xls ;
  	bless ( $self, $class ) ;
  	return $self ;
}

# Flush the values of $p to column number.  Set the comment with the text of the formula if the field is a lookup field.  
# Bold/red if it is header, and just red if it is value.
sub flush_to_xls
{
	my ( $class , $xlsrow , $p ) = @_ ;
	my $xls = $class->{XLS} ;
	
	my $xlscol = 0 ;
	foreach my $key ( keys %$p ) {
		$xls->write ( 0 , $xlscol , $key ) ;				# write the column header
		my $lookup = $cfg->get( "common", $key ) ;			# test if this field is a lookup/formula field
		if ( defined $lookup ) {
			$xls->comment ( 0 , $xlscol , $lookup ) ;							# insert comment
			$xls->setformat ( 0 , $xlscol , { color => 'red' , bold => 1 } ) ;	# bold/red for the comment
			$xls->setformat ( $xlsrow , $xlscol , { color => 'red' } ) ;		# red for the value
		}
		# print "Writing out key = $key , [$xlsrow,$xlscol] , Value = $p->{$key}\n" ;
		$xls->write ( $xlsrow , $xlscol++ , $p->{$key} ) ;
	}
}


sub print_handles
{
	my ( $class , $J ) = @_ ;
	
	my $xls = $class->{XLS} ;
	$xls->worksheet("Handles");
		
	my @columns = $cfg->List ( $section , "columns" ) ;		# get column names
	
	# Go through each bufferpool and write to excel
	my $xlsrow = 1;
	foreach my $apphld ( sort keys %$J ) {
		my $new = 1 ;
		foreach my $h ( @{ $J->{$apphld} } ) {
			resolve_formula_fields ( $h , @columns ) ;				# resolve formula fields
			my $H = orderby ( $h , @columns ) ;						# get an ordered list
			$H->{'Application handle'} = "" if ( $new == 0 ) ;		# make it look nice in excel
			$class->flush_to_xls ( $xlsrow , $H ) ;					# write out hash values to row
			$xlsrow++;
			$new = 0 ;
		}
	}
}

sub print_handles_delta
{
	my ( $class , $J ) = @_ ;
	my $xls = $class->{XLS} ;
	
	# Go through each buffer pool , find the diff and write to excel
	$xls->worksheet("Handles_Delta");
	my @delta  = ( $cfg->List ( $section , "delta" ) , 'Interval' ) ;		# get column names

	my $xlsrow = 1;
	foreach my $apphld ( sort keys %$J ) {
		my @arr = @{ $J->{$apphld} } ;
		my $new = 1 ;
		for ( my $i = 1 ; $i < @arr ; $i++ ) {
			# get the differences in values
			my $t0 = $arr[$i-1] ;
			my $t1 = $arr[$i] ;
			my $H = hashdiff ( $t0 , $t1 ) ;			# get the difference between this and previous sample
			$H->{Interval} = tmdiff ( $t0->{'Snapshot timestamp'} , $t1->{'Snapshot timestamp'} ) ; 
			
			resolve_formula_fields ( $H , @delta ) ;			# resolve formula fields
			$H = orderby ( $H , @delta ) ;						# get an ordered list
			
			$H->{'Application handle'} = "" if ( $new == 0 ) ;	# make it look nice in excel
			$class->flush_to_xls ( $xlsrow , $H ) ;				# write out hash values to row
			$xlsrow++;
			$new = 0 ;
		}
	}
}

# Show the full text of all executing handles
sub executing
{
	my ( $class , @filelist  ) = @_ ;

	inputcheck ( scalar @filelist , 1 , 1 ) ;
	foreach my $fp ( @filelist ) {

		print "FILE = $fp->{FILE} ,  $fp->{'Snapshot timestamp'}\n\n"  ;

		for ( my $app = 0 ;; $app++ ) {

			my $p = $fp->record ( "APPLICATION" , $app ) ;

			# If this field does not exist, means hit end of subject matter.
			last if ( ! exists $p->{'Application handle'} ) ;
	
			if ( $p->{'Application status'} eq 'UOW Executing' ) {
				$fp->fulltext ( 'APPLICATION' , $p->{INDEX} ) ;
			}

		}
		print "\n\n" ;
	}
}

sub waiter {

	my ( $class , @filelist ) = @_ ;
	
	inputcheck ( scalar @filelist , 1 , 1 ) ;

	# Each handle is a pointer to a snapshot file
	my $handle = $filelist[0] ;
	
	foreach my $fp ( @filelist ) {
	
		for ( my $app = 0 ;; $app++ ) {

			my $p = $fp->record ( "APPLICATION" , $app ) ;

			# If this field does not exist, means hit end of subject matter.
			last if ( ! exists $p->{'Application handle'} ) ;
	
			if ( $p->{'Application status'} eq 'Lock-wait' ) {
			
				# Cater to situation when status UOW not collected
				my $elapse = 0;
				if ( $p->{'Status change time'} !~ m/Not Collected/ ) {
					my $t = new Time("mm/dd/yyyy hh:min:ss.ns");
					$elapse =  sprintf "%f" , $t->diff ( $p->{'Status change time'} , $p->{'Snapshot timestamp'} ) ;
				}
				
				my $requestor = $p->{'Application handle'} ;
				print "\nRequestor : $requestor : ";
				print "\tLast change = $p->{'Status change time'} , Snapshot time = $p->{'Snapshot timestamp'}, Elapse = $elapse\n";
				
				my $ts ;
				
				open MEM, '>', \$ts or die "Can't open MEM: $!";
				select ( MEM ) ;
				$fp->fulltext ( 'APPLICATION' , $p->{INDEX} ) ;
				select ( STDOUT ) ;
				
				foreach my $ln ( split /\n/,$ts  ) {
					if ( $ln =~ m/ID of agent holding lock/ ) {
						print "\tHolder $ln\n";
					}
				}
			}

		}
		print "\n\n" ;
	}


}

sub summary 
{
	my ( $class , @filelist  ) = @_ ;

	inputcheck( scalar @filelist , 2 ) ;       # need at least 2 files

	my $xls = $class->{XLS} ;
	$xls->worksheet("Summary");

	my $J = {} ;
	my ( $row , $col ) = ( 0 , 0 ) ;

	foreach my $fp ( @filelist ) {

		my %STATUS_COUNT = () ;

		$col = 0 ;
		$xls->write ( $row++ , $col++ , "FILE = $fp->{FILE}" ) ;

		for ( my $app = 0 ;; $app++ ) {
		
			my $p = $fp->record ( "APPLICATION" , $app ) ;
			
			# If this field does not exist, means hit end of subject matter.
			last if ( ! exists $p->{'Application handle'} ) ;

			print "Doing File = $p->{FILE} , application ($p->{'Application handle'})\n" ;
			
			# J is of the form : J->{Application handle} -> [ an array of snapshot records ]
			my $apphld = $p->{'Application handle'} ;
			push ( @{ $J->{$apphld}  } , $p ) ;

			# Count how many applications in whatever status
			my $status = $p->{'Application status'} ;
			$STATUS_COUNT{$status}++ ;
		}

		foreach my $status ( keys %STATUS_COUNT ) {
			$xls->write ( $row++ , $col , "Status = $status , Count = $STATUS_COUNT{$status}" )  ;
			print "\tStatus = $status , Count = $STATUS_COUNT{$status}\n" ;
		}
	}
	
	# $class->print_summary ( @filelist ) ;
	$class->print_handles ( $J ) ;
	$class->print_handles_delta ( $J ) if ( @filelist > 1 ) ;
}


# give a list of lines, get the SQL text.  It search for string "Dynamic SQL statement text:", and get the next few lines until a blank line

sub sqltext {
    my (@lns) = @_;
    my $want  = 0;
    my $stmt  = "";

    for ( my $i = 0 ; $i < @lns ; $i++ ) {

        my $ln = $lns[$i];

        if ( $ln =~ m/Dynamic SQL statement text/i ) {
            $stmt .= "\t$lns[$i+1]\n";

            # $stmt  =~ s/\s+$//g ;
        }

    }
    return $stmt;
}

sub regex {
    my ( $class, $expr, @filelist ) = @_;

    my $pflag = 0;

    # Each handle is a pointer to a snapshot file
    foreach my $handle (@filelist) {

        # read all the lines belonging to Application Snapshot
        my $lns = $handle->lines("Application Snapshot");

	# break it into pieces. p{0} is a application lines, p{1} is another application lines and so on
	### junsu
        my $s = new JSSnapshots::Sections($lns); my $x = $s->pieces( "Application handle", "Application Snapshot" );

        for ( my $i = 0 ; $i < $s->num_sections() ; $i++ ) {

            # need this to get the File name
            my $q = $s->slurp($i);

            # set the print flag to off
            $pflag = 0;

	    # get all the lines of this section and set pflag to 1 if it matches the regular expression
            my $k = $s->section($i);
            foreach my $ln (@$k) {
                $pflag = 1 if ( $ln =~ m/$expr/i );
            }

            # print out section if pflag is set
            if ( $pflag == 1 ) {
                print "File = $q->{FILE}\n";
                $s->print($i);
            }

        }
    }

}

sub overall 
{
	my ( $class , @filelist  ) = @_ ;
	
	foreach my $fp ( @filelist ) {
		
		print "Doing File = $fp->{FILE}\n" ;
		
		my %H = () ;
		for ( my $app = 0 ;; $app++ ) {
		
			my $p = $fp->record ( "APPLICATION" , $app ) ;
			
			# If this field does not exist, means hit end of subject matter.
			last if ( ! exists $p->{'Application handle'} ) ;
			
			# Evaluate the average 
			evalstr ( $p , "LOGICAL READ" , 'Buffer pool data logical reads + Buffer pool temporary data logical reads + Buffer pool index logical reads + Buffer pool temporary index logical reads' ) ;
			
			# print Data::Dumper->Dump ( [ $p ] , [ 'P' ] ) ; exit ;
			
			if ( $p->{'Application status'} eq 'UOW Executing' ) {
				print "\tHandle = $p->{'Application handle'}\n" ;
				print "\t\tStatus change time = $p->{'Status change time'}\n" ;
				print "\t\tSnapshot timestamp = $p->{'Snapshot timestamp'}\n" ;
				my $itv = tmdiff ( $p->{'Status change time'} , $p->{'Snapshot timestamp'} ) ;
				print "\t\tInterval = $itv\n" ;
				
			}
			my $stat = $p->{'Application status'} ;
			$H{$stat}++ ;
			
		}
		
		foreach ( sort keys %H ) {
			printf "\t%20s, $H{$_}\n" , $_  ;
		}
	}
	
}

# Print in report format the progress of an application handle
sub progress
{
	my ( $class , $handle , @filelist  ) = @_ ;

   	my @columns = $cfg->List ( $section , "progress" ) ;     # get column names
	my $PREV ;		#	previous value holder

	foreach my $fp ( @filelist ) {

		# get the record with the handle number
		my $p = $fp->record_by_name ( 'APPLICATION' , 'Application handle' , $handle , 1  ) ;
		next if ( ! %$p ) ;     # skip if empty hash

		resolve_formula_fields ( $p , @columns ) ;

		print "Application handle = $handle , File = $p->{FILE} , Snapshot timestamp = $p->{'Snapshot timestamp'}\n" ;
		foreach my $field ( @columns ) {
			printf "\t$field = $p->{$field} ( %s )\n" , $p->{$field} - $PREV->{$field} ;
			$PREV->{$field} = $p->{$field} ;
		}
		print "\n" ;
	}

}

return 1;

