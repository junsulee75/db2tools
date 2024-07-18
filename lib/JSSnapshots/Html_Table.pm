package JSSnapshots::Html_Table ;

use HTML::Table ;
use List::MoreUtils qw/ uniq /;
use JSSnapshots::Functions qw(commafy);
use strict ;

=pod

=head1 VERSION
	Version 	: $Revision: 59 $
	Last modified 	: $Date: 2014-05-09 11:49:37 +1000 (Fri, 09 May 2014) $
	URL		: $HeadURL: file:///D:%5CSVN/PerlMod/Snapshots/Html_Table.pm $ ;

=cut

my $debug = 0 ;
my %ROW = () ;
my %TABLE = () ;			# my internal table of rows/columns before flushing down to the HTML::Table
		
##  The input string has to be yyyy-mm-dd-hh-min-ss-ns
##  Methods :
##  
##  set_start , set_end , diff
sub new 
{
	my ( $class ) = @_ ;

      my $self = () ;
  		$self->{TABLE} = new HTML::Table( -border => 1 ); 
  		$self->{TRANSPOSE} = 0 ;
  		$self->{ROW} = 0 ;
      bless ( $self, $class ) ; 
      return $self ; 
}

# Set options
sub setopt {
	
	my ( $class , $opt ) = @_ ;

	foreach my $k ( keys %$opt ) {
		$class->{$k} = $opt->{$k} 
	}
	
}

# Note the deltas that need to be applied on which columns
sub rowdelta 
{
	my ( $class , @colnames ) = @_ ;
	$class->{DELTA} = \@colnames ;
}

#  Add column names, and note position of column names in hash %HEADER
sub set_colnames
{
		my ( $class , @l ) = @_ ;
		
		$class->{COLUMNNAMES} = \@l ;
		
		# make this into a hash table to COLUMN-NAME => COLUMN NUMBER so I can reference it quickly
		# for ( my $i = 0 ; $i < @l ; $i++ ) {
		#	my $colname = $l[$i] ;
		#	$COLUMN{$colname} = $i ;
		# }  Why is this here ???
	
		# first column is key by default
		@ { $class->{KEY} } = ( $l[0] ) ;
}

# A key can be made up of multiple columns, like schema, tabname
sub setKey
{
		my ( $class , @cols ) = @_ ;
		@ { $class->{KEY} } = @cols ;
}

# Call base method to add a row, passed in a hash pointer
sub addRow
{
		my ( $class , $ptr ) = @_ ;

		my @fn = @ { $class->{COLUMNNAMES} } ;
	
	  # get the key names X:Y:Z ....and change to valX:valY:valZ....
		my $key = join ( ":" , map { $ptr->{$_} } @ { $class->{KEY} } ) ;
		# print "Key = $key\n" ;
		
		if ( exists $ROW{$key} ) {
				
				my $row_number = $ROW{$key} ;
				print "Update Key : $key , Row = $row_number , Values = " if ( $debug == 1 ) ;
				my @oldrow = @ { $TABLE{$row_number} } ;
				my @newrow = map { $ptr->{$_} } @fn ;	
				# key exist , update the value
			
				for ( my $i = 0 ; $i < @oldrow ; $i++ ) {
						$oldrow[$i] .= ",$newrow[$i]" ;
				}
			  
			  @ { $TABLE{$row_number} } = @oldrow ;
				# print join( " ** " , @oldrow ) . "\n" ;
				print join (" : " , @ { $TABLE{$row_number} } )  . "\n" if ( $debug == 1 ) ;

				
		} else {
				
				# key does not exist.  make new entry
				my $row_number = $class->{ROW} ;
				print "Insert -  Key = $key , Row = $row_number , Values = " if ( $debug == 1 ) ;

				$ROW{$key} = $row_number ;															# store the row number for quick lookup on key
				@ { $TABLE{$row_number} } = map { $ptr->{$_} } @fn ;		# transform the column names to values
				$class->{ROW}++ ;
				
				print join (" : " , @ { $TABLE{$row_number} } )  . "\n" if ( $debug == 1 ) ;
				
		}
		
}


# Transpose.  Rows become columns, and vice versa.  Do this by creating a new table
sub transpose
{
	my ( $class ) = @_ ;
	my $tab = $class->{TABLE} ;

	my $newtab = new HTML::Table( -border => 1 );  ;
	my @arr = () ;
	my ( $r , $c ) = ( 0 , 0 ) ;
	
	for ( $r = 1 ; $r <= $tab->getTableRows() ; $r++ ) {
		
		for ( $c = 1 ; $c <= $tab->getTableCols() ; $c++ ) {
			
			my $v = $tab->getCell ( $r , $c ) ;
			push ( @arr , $tab->getCell ( $r , $c ) ) ;
		}
		
		$newtab->addCol ( @arr ) ;
		@arr = () ;
	}
	
	# print "Ended\n" ;
	$class->{TABLE} = $newtab ;
}


# Print the table.   Apply deltas if required.
sub apply_delta
{
	my ( $class ) = @_ ;
	
	my $tab = $class->{TABLE} ;
	my $colnames = $class->{COLUMNNAMES} ;
	my %HEADER = () ;
	
	# print "Apply_delta\n" ; exit ;
	# form a hash table of column-name vs column-number for quick access
	for ( my $i = 0 ; $i < @$colnames ; $i++ ) {
			$HEADER{$colnames->[$i]} = $i ;
	}
	
	# print Data::Dumper->Dump ( [ \%HEADER ] , [ HEADER ] ) ; 
		
	foreach my $rownum ( @{$class->{DELTA}} ) {
			
			# print "Apply delta on Rownum = $rownum ... " ;
			# Get column number
			$rownum = $HEADER{$rownum} + 1 ;
			# print "Rownum = $rownum\n" ;
		
			for ( my $col = $tab->getTableCols() ; $col > 2 ; $col-- ) {
		
				# get current value
				my $val = $tab->getCell ( $rownum , $col ) ;
			
				my $number = ( $val =~ m/^\d+$/ || $val =~ m/^\d+\.\d+$/ ) ? 1 : 0 ;
				
				# get delta if it all numeric or decimal )
				if  ( $number == 1 ) {
					my $delta = $val - $tab->getCell ( $rownum , $col-1 ) ;
					$delta = sprintf "%.3f" , $delta if ( $delta =~ m/\d+\.\d+/ ) ;		# remove too many zeroes
					$delta = commafy ( $delta ) ;
					
					# insert back into table if delta is applicable
					$tab->setCell ( $rownum , $col , "$val ($delta)" ) ;
					# print "SetCell $rownum , $col , $val ($delta)\n" ;		
				}
			}
		}
}

# Merge a cell of string of X,X,X to become X.  If cannot merge , X1,X2,X3 becoems X1,X2(X2-X1),X3(X3-X2)
sub merge_row
{
		my ( @rec ) = @_ ;
		
		for ( my $i = 0 ; $i < @rec ; $i++ ) {
			
				print "Merging $rec[$i]  " if ( $debug == 1 ) ;
				my @unique = uniq split /,/ , $rec[$i] ;
				my $cnt = @unique ; 
				$rec[$i] = $unique[0] if ( @unique == 1 ) ;
				print "to $rec[$i] , count = $cnt\n" if ( $debug == 1 ) ; ;
				
				my @h = split /,/,$rec[$i] ;
				for ( my $j = @h-1 ; $j > 0 ; $j-- ) {
					
					# get the difference only if the value is numeric or decimal
					my $prev_val = $h[$j-1] ;
					my $number = ( $prev_val =~ m/^\d+$/ || $prev_val =~ m/^\d+\.\d+$/ ) ? 1 : 0 ;
					next if ( $number == 0 ) ;
					
					my $diff = $h[$j] - $h[$j-1] ;
					$diff = sprintf "%.3f" , $diff if ( $diff =~ m/\d+\.\d+/ ) ;		# remove too many zeroes
					$diff = commafy ( $diff ) ;
					$h[$j] = "$h[$j] ( $diff ) " ;	
				}
				$rec[$i] = join("<br>",@h)  ;

		}	
		return @rec ;
}

sub myprint
{
		my ( $class ) = @_ ;
		
		my $tab = $class->{TABLE} ;
	
		# dump all my HEADER and rows to the HTML table
		$tab->addRow ( @ { $class->{COLUMNNAMES} } ) ;
		foreach my $row ( sort { $a <=> $b } keys %TABLE ) {
			
				my @rec = @ { $TABLE{$row} } ;
				@rec = merge_row ( @rec ) if ( $class->{MERGE} == 1 ) ;
				$tab->addRow ( @rec ) ;
		}

		# If Transpose is set
		transpose ( $class ) if ( $class->{TRANSPOSE} == 1 ) ;
		
		# Apply delta always happen after transpose
		apply_delta ( $class ) if ( exists $class->{DELTA} && $class->{TRANSPOSE} == 1 ) ;
		
		# transposes has changed the value of class->TABLE , so $tab is no longer same value
		$class->{TABLE}->print ;
}

sub addSect_TBD
{
		my ( $class , $lines ) = @_ ;
		$class->{DEFINITON} = $lines ;
}

sub dumpdata
{
	my ( $class ) = @_ ;
	
	print "COLNAMES = " . join(" | ", @{$class->{COLUMNNAMES}} ) . "\n" ;
	foreach my $row ( sort { $a <=> $b } keys %TABLE ) {
		print "ROW-$row = " . join(" | ", @{$TABLE{$row}} ) . "\n" ;
	}
	
}


return 1 ;
