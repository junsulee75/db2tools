package xls;

use Excel::Writer::XLSX ;
use Data::Dumper;
use Storable qw(dclone);
use Tie::IxHash;
use strict;

=pod

=head1 VERSION
	Version 	: $Revision: 59 $
	Last modified 	: $Date: 2014-05-09 11:49:37 +1000 (Fri, 09 May 2014) $
	URL		: $HeadURL: file:///D:%5CSVN/PerlMod/Snapshots/Database.pm $ ;

=head1 DESCRIPTION

	This module provides methods to read/write EXCEL files.

=cut

my $debug = 0;

sub new {
    my ( $class, $fn ) = @_;

    my $self = ();
    $self->{FILE} = $fn;

    # $self->{WB}    = Spreadsheet::WriteExcel::Big->new($fn);	# workbook
    $self->{WB} = Excel::Writer::XLSX->new($fn) or die "Cannot open XLS file : $fn" ;    # workbook
    bless( $self, $class );
    return $self;
}

sub debug {
    my ( $class, $flag ) = @_;
    $debug = $flag;
}

# Work on a worksheet.  If it does not exist, create it.
sub worksheet {
    my ( $class, $wsname ) = @_;

    my $sheets = $class->{SHEETS};

    foreach my $ws (@$sheets) {
        if ( $ws->{NAME} eq $wsname ) {
            $class->{CURRENT_WORKSHEET} = $ws;
            # print "Found $ws - returning  $k->{NAME}\n" ;
            return $ws;
        }
    }

# If we reach this stage, means cannot find worksheet, and has to create new one.
# $class->{CURRENT_WORKSHEET} = $class->{SHEET}->{$ws} ;
    my $wb        = $class->{WB};
    my $WORKSHEET = {
        NAME => $wsname,
        DATA => undef ,
		COMMENT => undef ,
		FORMAT => undef 
    };
    push( @{ $class->{SHEETS} }, $WORKSHEET );
    $class->{CURRENT_WORKSHEET} = $WORKSHEET;

    # print Data::Dumper->Dump ( [ $class->{SHEETS} ] , [ qw/AFTER/ ] ) ;
    return $WORKSHEET;
}

sub remove_worksheet {
    my ( $class, $ws ) = @_;
    my $sheets = $class->{SHEETS};

    # get the index where the worksheet occur
    my $cnt;
    $cnt = @{ $class->{SHEETS} };

    for ( my $i = 0 ; $i < @$sheets ; $i++ ) {

        if ( $sheets->[$i]->{NAME} eq $ws ) {
            splice( @$sheets, $i, 1 );
            last;
        }
    }
    $cnt = @{ $class->{SHEETS} };
    $class->{CURRENT_WORKSHEET} = undef;
}

# Set the format for a cell
sub setformat {
	my ( $class , $row , $col , $fmt ) = @_ ;
	my $ws = $class->{CURRENT_WORKSHEET};
    $ws->{FORMAT}[$row][$col] = $fmt;
}

# Get the format for a cell
sub getformat {
	my ( $class , $row , $col ) = @_ ;
	my $ws = $class->{CURRENT_WORKSHEET};
    return ( $ws->{FORMAT}[$row][$col] ) ;
}

#  Write a value to a row/column
sub write {
    my ( $class, $row, $col, $val ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    die "Define worksheet first before calling write" if ( !defined $ws->{NAME} );

    # print "Write $val to $row-$col , Worksheet $ws->{NAME}\n" ;
    $ws->{DATA}[$row][$col] = $val;
}

sub setcolwidth
{
	my ( $class, $colwidth ) = @_;
	my $ws = $class->{CURRENT_WORKSHEET};
	$ws->{COLWIDTH} = $colwidth ; 
}


# Get a value from a row/column
sub getcell {
    my ( $class, $row, $col ) = @_;

    my $ws = $class->{CURRENT_WORKSHEET};
    die "Define worksheet first before calling write" if ( !defined $ws->{NAME} );

    # print "Write $val to $row-$col , Worksheet $ws->{NAME}\n" ;
    my $val = $ws->{DATA}[$row][$col];
    return $val;
}

# Get the row values returned as an array
sub getrow {
    my ( $class, $row ) = @_;
	my @arr = () ;
    my $ws = $class->{CURRENT_WORKSHEET};
    die "Define worksheet first before calling write" if ( !defined $ws->{NAME} );
    @arr = @ { $ws->{DATA}[$row] } if ( defined $ws->{DATA}[$row] ) ;
    return @arr ;
}

# Get a value from a row/column.  This is an array
sub getcol {
    my ( $class, $col ) = @_;
	my @arr ;
    my $ws = $class->{CURRENT_WORKSHEET};
    die "Define worksheet first before calling write" if ( !defined $ws->{NAME} );
	for ( my $row = 0 ; $row < $class->numrows ; $row++ ) {
		push ( @arr , $ws->{DATA}[$row][$col] ) ;
	}
    return @arr ;
}

# Add value to current existing cell row/column
sub addval {
    my ( $class, $row, $col, $val ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    die "Define worksheet first before calling write" if ( !defined $ws->{NAME} );

    # print "Write $val to $row-$col , Worksheet $ws->{NAME}\n" ;
    $ws->{DATA}[$row][$col] += $val;
}

# Get the comment of a cell
sub getcomment {
	my ( $class, $row, $col ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    return ( $ws->{COMMENT}[$row][$col] ) ;
}

# Apply a comment to a row/column
sub comment {
    my ( $class, $row, $col, $val ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    $ws->{COMMENT}[$row][$col] = $val;
}

# Write an array of values to a row in reference $val starting at row/column
sub write_row {
    my ( $class, $row, $col, $val ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    foreach my $v (@$val) {
        $ws->{DATA}[$row][ $col++ ] = $v;
    }
}

# Write an array of values to a column in reference $val starting at row/column
sub write_col {
    my ( $class, $row, $col, $val ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    foreach my $v (@$val) {
        $ws->{DATA}[ $row++ ][$col] = $v;
    }
}

# return the number of rows for this worksheet.  if worksheet is not given, default to current worksheet
sub numrows {
    my ( $class ) = @_;
	
    my $ws      = $class->{CURRENT_WORKSHEET};
    my $data    = $ws->{DATA};                   # get data pointer
    my $numrows = @{$data};
    return $numrows;
}

# add a new row to this worksheet. $ptr is a array reference
sub new_row {
    my ( $class, $ptr ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};

    my $data    = $ws->{DATA};                   # get data pointer
    my $numrows = @{$data};
    write_row( $class, $numrows, 0, $ptr );
}

# Write an array of values to a column in reference $val starting at row/column
sub write_col {
    my ( $class, $row, $col, $val ) = @_;
    my $ws = $class->{CURRENT_WORKSHEET};
    foreach my $v (@$val) {
        $ws->{DATA}[ $row++ ][$col] = $v;
    }
}

# Append the value to column.  Returns the row it inserted
sub append_column {
    my ( $class, $col, $val ) = @_;
    my $wb = $class->{WB};
    my $ws = $class->{CURRENT_WORKSHEET};

    my $i;
    for ( $i = 0 ; $i < 65536 ; $i++ ) {
        last if ( !defined $ws->{DATA}[$i][$col] );
    }
    $ws->{DATA}[$i][$col] = $val;
    return $i;

    # print "Writing $ws->{NAME} [$i][$col] Value $val\n" ;
}

# Append the value to row.  Returns the column number
sub append_row {
    my ( $class, $row, $val ) = @_;
    my $wb = $class->{WB};
    my $ws = $class->{CURRENT_WORKSHEET};

    my $i;
    for ( $i = 0 ; $i < 65536 ; $i++ ) {
        last if ( !defined $ws->{DATA}[$row][$i] );
    }
    $ws->{DATA}[$row][$i] = $val;
    return $i;

    # print "Writing $ws->{NAME} [$row][$col] Value $val\n" ;
}

# Change the rows to columns, and columns to rows
sub transpose {

    my ( $class  ) = @_;
	
	my $ws = $class->{CURRENT_WORKSHEET};
	
	# New variables to hold the new data , comments , and format
	my ( $data , $comment , $format ) ;
	
	# For each row,col ,  becomes col/row
	my $numrows = $class->numrows() ;
    for ( my $row = 0 ; $row < $class->numrows() ; $row++ ) {
		my @r = $class->getrow($row) ;
		my $numcols = @r ;
		for ( my $col = 0 ; $col < $numcols ; $col++) {
			$data->[$col][$row] = $class->getcell($row,$col) ;
			$comment->[$col][$row] = $class->getcomment($row,$col) ;
			$format->[$col][$row] = $class->getformat($row,$col) ;
		}
	}

	# deallocate the old data , comment , format
    $ws->{DATA} = undef;       # reset data
	$ws->{COMMENT} = undef ;
	$ws->{FORMAT} = undef ;
	
	# point to the new data , comment , format
	$ws->{DATA}  = $data ;
	$ws->{COMMENT} = $comment ;
	$ws->{FORMAT} = $format ;
}

# Flush the contents of internal table into each worksheet.
sub flush_worksheet {

    my ( $class, $ws ) = @_;

    my $sheet = $ws->{PTR};
 	# print "Flushing WS name = $ws->{NAME} , Sheet = $sheet\n" ;
    for ( my $row   = 0 ; $row < $class->numrows ; $row++ ) {
        my @r = $class->getrow($row) ;
        for ( my $col = 0 ; $col < @r ; $col++ ) {
		
			my $value = $class->getcell( $row , $col ) ;
            next if ( ! defined $value );    # ignore if undefined
			
			# format the cell if there defined
            my $fmt = $class->getformat( $row, $col );
			my $format = undef ;
			if ( defined $fmt ) {
				$format = $class->{WB}->add_format(); # Add a format
				$format->set_format_properties ( %$fmt ) ;
=begin
				$format->set_bold() if ( $fmt->{bold} == 1 ) ;
				$format->set_color( $fmt->{color} ) if ( exists $fmt->{color} );
				$format->set_bg_color( $fmt->{bg_color} ) if ( exists $fmt->{bg_color} );
				$format->set_align( $fmt->{align} ) if ( exists $fmt->{align} );
				$format->set_border() ;
=cut
			}
			
			$sheet->write( $row, $col, $value , $format );
			undef $format ;
			
			my $c = $class->getcomment($row,$col) ;
			$sheet->write_comment( $row, $col, $c ) if ( defined $c ) ;
        }
    }
	
	foreach my $col ( keys %{$ws->{COLWIDTH}} ) {
		$sheet->set_column ( $col , $col , $ws->{COLWIDTH}->{$col} ) ;
		# print "$col => $ws->{COLWIDTH}->{$col}\n" ;
	}
}

# merge all rows from given worksheet into current worksheet
sub merge {
    my ( $class, $wsname ) = @_;

    my $curws = $class->{CURRENT_WORKSHEET};
    my $ws = wsptr( $class, $wsname );

    my $numrows = numrows( $class, $wsname );
    print "WSNAME = $wsname , rows = $numrows\n";
    for ( my $i = 1 ; $i < $numrows ; $i++ ) {

        # get row
        my $row = $ws->{DATA}->[$i];

        # write it to the main sheet
        print Data::Dumper->Dump( [$row], ["WS"] );
        new_row( $class, $row );

        # print "Writing row $i from $ws to Tablespace\n" ;
    }
}


# This operation has to be done before the tranposition.
sub deltas {
    my ( $class, $ws ) = @_;

    my $data = $class->{CURRENT_WORKSHEET}->{DATA};

    my $row = 0;
    my $col = 0;

    my $numrows = @{$data};
    for ( my $rownum = $numrows - 1 ; $rownum > 0 ; $rownum-- )
    {    # for every row starting from the back
        my $row = $data->[$rownum];    # get the current row pointer

        my $numcols = @{$row};
        for ( my $colnum = $numcols ; $colnum > 0 ; $colnum-- )
        {                              # for every column

            my $prevval = $data->[ $rownum - 1 ][$colnum];
            my $currval = $data->[$rownum][$colnum];

            # print "[$rownum][$colnum] : $v\n" ;
            # Do the diff only if this value and the value before it are numeric
            if ( $currval =~ m/^\d+$/ && $prevval =~ m/^\d+$/ ) {
                $data->[$rownum][$colnum] =
                  $currval - $prevval;    # write it out as a column
            }

# Do the special case for 1st value. Since it has no delta, set it to 0 if numeric
            if ( $rownum == 1 && $currval =~ m/^\d+$/ ) {
                $data->[$rownum][$colnum] = 0;    # write it out as a column
            }
        }

    }

}

# duplicate current worksheet to a different worksheet
sub copy {
    my ( $class, $newname ) = @_;

    # set to worksheet 1
    my $ws1 = $class->{CURRENT_WORKSHEET};

    # create the new worksheet
    worksheet( $class, $newname );
    my $ws2 = $class->{CURRENT_WORKSHEET};
    $ws2->{DATA} = dclone( $ws1->{DATA} );
	$ws2->{COMMENT} = dclone( $ws1->{COMMENT} );
	$ws2->{FORMAT} = dclone( $ws1->{FORMAT} );
}

# Get the data from a list of worksheets and insert into the new worksheet.  Assume same type and header.
sub consolidate {
    my ( $class, $newworksheet, @list ) = @_;

    my $newws = worksheet( $class, $newworksheet );

    my $nrow = 1;
    foreach (@list) {

        my $ws      = worksheet( $class, $_ );
        my $data    = $ws->{DATA};
        my $numrows = @{$data};

        $newws->{DATA}[0] = $ws->{DATA}[0];
        for ( my $i = 1 ; $i < $numrows ; $i++ ) {
            $newws->{DATA}[ $nrow++ ] = $ws->{DATA}[$i];
        }
        remove_worksheet( $class, $_ );
    }

}

sub close {
    my ($class) = @_;
    my $wb = $class->{WB};

    foreach my $ws ( @{ $class->{SHEETS} } ) {
		$class->worksheet ( $ws->{NAME} ) ; 
        $ws->{PTR} = $wb->add_worksheet( $ws->{NAME} ) ;
		$class->flush_worksheet( $ws );
    }
    $wb->close();
}

return 1;
