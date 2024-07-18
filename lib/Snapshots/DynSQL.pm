package Snapshots::DynSQL ;
use Snapshots::Cfg ;
use Snapshots::Functions qw(ratio hitrate evalstr resolve_formula_fields orderby commafy inputcheck);
use LibFunc qw(roundup) ;
use HTML::Table ;
use Digest::MD5 qw(md5);
use strict ;

my $cfg = new Cfg() ; 

# Some common strings
my $MAP = {

	Factor 	=>  "Total execution time (sec.microsec) / (  Total user cpu time (sec.microsec) + Total system cpu time (sec.microsec) )" ,
	'Rows per execution' => "ratio ( 0 , Rows read , Number of executions )"  ,
	'High Physical Reads' => '( Buffer pool data physical reads + Buffer pool index physical reads + Buffer pool temporary data physical reads + Buffer pool xda physical reads ) / Number of executions' ,
	'High Logical Reads' => '( Buffer pool data logical reads + Buffer pool temporary data logical reads + Buffer pool index logical reads + Buffer pool temporary index logical reads + Buffer pool temporary xda logical reads ) / Number of executions' ,

} ;

sub new 
{
	my ( $class , $xls  ) = @_ ;
	
  	my $self = () ;
	my $section = "dbsnap" ;
    $self->{XLS} = $xls;
 	bless ( $self, $class ) ;
  	return $self ;
}

my $H = {} ;
sub summary
{
	my ( $class , @filelist ) = @_ ;
	
	inputcheck ( scalar @filelist , 2 ) ;

	my $Files = {} ;


	my $fileindex = 0 ;
	my $skip  = 0 ;
	my $total = 0 ;
	foreach my $fp ( @filelist ) {

		my $cnt = $fp->count ('SQL') ;					# count number of Dyn SQLs in this file
		$Files->{$fileindex} = $fp->{FILE} ;

		for ( my $i = 0 ;; $i++ ) {		# remember to remove the 5000 limit later
	
			printf "$fp->{FILE} : record %s of %s ( %.1f %% )\r" , commafy($i), commafy($cnt),($i/$cnt)*100 if ( $i % 20 == 0 )  ;

			my $p = $fp->record ( 'SQL', $i , 1 ) ;
			
			# skip those that read 1000 or less.  Wont be a contributing factor to performance
			if ( $p->{'Rows read'} > 1000 ) {
				my $cksum = unpack ( 'L' , substr( md5( $p->{'Statement text'} ), 0, 4 ) ) ;
				push ( @ { $H->{$cksum} } , "$fileindex,$i" ) ;	# store the file/index pair
			} else { $skip++ } ;
	
			$total++ ;
			# no more records
			last if ( ! exists $p->{'Number of executions'} ) ;	
		}
		print "\n" ;

		# increment the file index
		$fileindex++ ;
	}

	my $xls = $class->{XLS} ;
	$xls->worksheet("Files");
	$xls->write_row ( 0 , 0 , [ 'File Index' , 'File Name' ] ) ;
	for ( my $row = 0 ; $row < @filelist  ; $row++ ) {
		my $fname = $Files->{$row} ;
		$xls->write_row ( $row+1 , 0 , [ $row  , $fname ] ) ;
	}

    my @columns = ( 'Cksum' , 'FileIdx' , 'Idx' , split /\s*,\s*/ , $cfg->get ( "dynsql" , "columns" ) ) ;
	# print join ( ' <=> ' , @columns ) . "\n" ; exit ;

	$xls->worksheet("Data") ;
	my $row = 1 ;
	foreach my $cksum ( keys %$H ) {

		foreach my $h ( @ { $H->{$cksum} } ) { 

			my ( $fileindex,$entry ) = split /,/,$h ;

			my $fp = $filelist[$fileindex] ;
			my $p = $fp->record ( 'SQL', $entry )  ;

			$p->{Cksum} = $cksum ;
			$p->{FileIdx} = $fileindex ;
			$p->{Idx} = $entry ;

			resolve_formula_fields ( $p , @columns ) ;
			my $TH = orderby ( $p , @columns ) ;
			# print Data::Dumper->Dump ( [ $TH ] , [ 'TH' ] ) ; exit ;
			$class->flush_to_xls ( $row++ , $TH ) ;
		}
	}
	my $pctskip = ( $skip / $total ) * 100 ;
	printf "Note : SQLs with 'Rows read' that are < 1000 are skipped. Total skip = %s out of %s ( %.2f %%)\n" , commafy($skip) , commafy($total) , $pctskip ;
}

sub top10
{
	my ( $class , @filelist ) = @_ ;
	my $fp = $filelist[0] ;
	my %H = () ;
	
	inputcheck ( scalar @filelist , 1 , 1 ) ;
	# write out the column names on row 0 and bold/red it if it is a computed field.  Them comment is the formula
    # Each handle is a pointer to a snapshot file
    my @columns = split /\s*,\s*/ , $cfg->get ( "dynsql" , "top10" ) ;

	system ( 'cls' ) ;
	my $cnt = $fp->count ('SQL') ;
	print "\n\nNUmber of Dynamic SQLs = $cnt.  Pick a field to sort on  :\n\n" ;
	for ( my $i = 0 ; $i < @columns ; $i++ ) {
		printf "[%2d] $columns[$i]\n" , $i ;
	}

	print "\nChoice : " ;
    my $ans = <STDIN>;

    chomp $ans;
	my $field = $columns[$ans] ;
	print "Ans = $ans, Field = $field\n" ;

	for ( my $i = 0 ;; $i++ ) {
	
		printf "Doing SQL record %s of %s ( %.1f %% )\r" , commafy($i), commafy($cnt),($i/$cnt)*100 if ( $i % 20 == 0 )  ;
		my $p = $fp->record ( 'SQL', $i , 1 ) ;
		last if ( ! exists $p->{'Number of executions'} ) ;	
		
		# ignore with no reads
		next if ( $p->{'Number of executions'} == 0 ) ;
		
        resolve_formula_fields ( $p , @columns ) ;

		# Evaluate the average 
		my $ratio = ratio ( 0 , $p->{$field} , $p->{'Number of executions'} ) ;

		# The value of the field will be the key.  E.g.  FACTOR = 1234.  1234 will be the key.  Then sort in descending to get top 10
		$H{ $ratio } = $i ;
	}
	print "\n" ;
	
	# show only top 10
	my $counter = 0 ;
	my $tab ;
	my $row ;

	close STDOUT;
	open STDOUT, "> top10.html" or die ;
	print "<pre>" ;
	print "<br>$fp->{FILE} - Field of interest : $field\n" ;

 	my @columns = split /\s*,\s*/ , $cfg->get ( "dynsql" , "columns" ) ;
	foreach my $avg ( sort { $b <=> $a } keys %H ) {
		
		$tab = new HTML::Table( -border => 1 ); 
		$tab->setWidth("90%");
		$row = $tab->addRow(('FIELD','VALUE'));
		$tab->setColWidth ( 1 , "300" ) ;
		$tab->setColWidth ( 2 , "400" ) ;
		$tab->setRowBGColor($row, 'yellow' ) ;
		
		$counter++ ;
		last if ( $counter > 10 ) ;
		
		my  $index = $H{$avg} ;
		my $q = $fp->record ( 'SQL', $index ) ;

        # resolve derived fields
        resolve_formula_fields ( $q , @columns ) ;

        # $q has ALL fields and unordered.  i only want some fields and in my order
        my $H = orderby ( $q , @columns ) ;

		$H->{AVG} = $avg ;
		
		# print Data::Dumper->Dump ( [ $q , $H ] , [ 'q' , 'H' ] ) ; exit ;

		foreach my $k ( keys %$H ) {
	
				if ( $k eq "Statement text" ) {
					my $cell = $tab->addRow ( $H->{$k} ) ;   # need the entire line, not just $s2
					$tab->setCellColSpan($cell, 1, 2) ;
					
				} else {
					$row = $tab->addRow( $k , $H->{$k} ) ;
				}
		}
		$tab->print ;
		
	}
}

sub show_record
{
	my ( $class , $entry , @filelist ) = @_ ;

	inputcheck ( scalar @filelist , 1 , 1 ) ;
	my $fp = shift @filelist ;
	$fp->fulltext ( 'SQL' , $entry ) ;
}

# Flush the values of $p to column number.  Set the comment with the text of the formula if the field is a lookup field.
# Bold/red if it is header, and just red if it is value.
sub flush_to_xls
{
    my ( $class , $xlsrow , $p ) = @_ ;
    my $xls = $class->{XLS} ;

    my $xlscol = 0 ;
    foreach my $key ( keys %$p ) {
        $xls->write ( 0 , $xlscol , $key ) ;                # write the column header
        my $lookup = $cfg->get( "common", $key ) ;          # test if this field is a lookup/formula field
        if ( defined $lookup ) {
            $xls->comment ( 0 , $xlscol , $lookup ) ;                           # insert comment
            $xls->setformat ( 0 , $xlscol , { color => 'red' , bold => 1 } ) ;  # bold/red for the comment
            $xls->setformat ( $xlsrow , $xlscol , { color => 'red' } ) ;        # red for the value
        }
        # print "Writing out key = $key , [$xlsrow,$xlscol] , Value = $p->{$key}\n" ;
        $xls->write ( $xlsrow , $xlscol++ , $p->{$key} ) ;
    }
}


return 1 ;
