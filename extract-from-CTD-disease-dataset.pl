#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Parse::CSV;
use Encode;
use vars qw($opt_h $opt_i $opt_o);
&getopts('hi:o:');

# Usage
my $usage = <<_EOH_;

## Options ###########################################
## Required:
# -i    input dataset file (CTD_diseases.csv)
# -o    output file (tab-delimited)

## Optional:

## Others:
# -h print help

_EOH_
    ;

die $usage if $opt_h;

# Get command line options
my $inFile  = $opt_i or die $usage;
my $outFile = $opt_o or die $usage;

# Open file handlers
my $ifh = Parse::CSV->new( file => $inFile );
my $ofh = openOfh( $outFile );

# Extract from CTD disease dataset
my $cnt = 0;
writeHeader($ofh);
while( my $cols = $ifh->fetch ) {
    next if $cols->[0] =~ /^#/;
    
    if( scalar(@$cols) == 9 ) {
	writeData( $ofh, $cols );
	++$cnt;
    } else {
	print STDERR "Warning: Invalid number of columns: " . scalar(@$cols) . "\n"
	    . join("\t", @$cols) . "\n";
	exit
    }
    
}

print STDERR "Valid entry in the input dataset = $cnt\n";

# Close file handlers
close $ofh;


sub openOfh {
    my $file = shift;
    my $ofh;
    open $ofh, ">$file" or die "Can't open the file [ $file ] to write.";
    return $ofh;
}

sub writeHeader {
    my $ofh = shift;
    print $ofh "Texts" . "\t" . "DiseaseID" . "\t" . "ParentIDs" . "\t" . "FLAG" . "\n";
}

sub writeData {
    my $ofh  = shift;
    my $cols = shift;

    my ($DiseaseName, $DiseaseID, $AltDiseaseIDs, $Definition, $ParentIDs,
	$TreeNumbers, $ParentTreeNumbers, $Synonyms, $SlimMappings) = @$cols;

    # Write disease name
    writeLine( $ofh, $DiseaseName, $DiseaseID, $ParentIDs, "1" );

    # Write alt disease IDs
    $AltDiseaseIDs =~ s/\|/ /g;
    writeLine( $ofh, $AltDiseaseIDs, $DiseaseID, $ParentIDs, "3" );

    # Write difinition
    my @defs = split( '\. ', $Definition );
    foreach my $def (@defs) {
	$def =~ s/^ //;
	$def = $def."." unless $def =~ /\.$/;
	writeLine( $ofh, $def, $DiseaseID, $ParentIDs, "4" );
    }

    # Write synonyms
    my @synos = split( '\|', $Synonyms );
    writeLine( $ofh, join(" | ", @synos), $DiseaseID, $ParentIDs, "80" );
    for( my $i=0 ; $i<scalar(@synos) ; ++$i ) {
	writeLine( $ofh, $synos[$i], $DiseaseID, $ParentIDs, "81" );
    }
    for( my $i=0 ; $i<scalar(@synos) ; ++$i ) {
	for( my $j=$i+1 ; $j<scalar(@synos) ; ++$j ) {
	    writeLine( $ofh, $synos[$i]." | ".$synos[$j], $DiseaseID, $ParentIDs, "82" );
	}
    }
}

sub writeLine {
    my $ofh       = shift;
    my $texts     = shift;
    my $DiseaseID = shift;
    my $ParentIDs = shift;
    my $FLAG      = shift;
    return 0 if $texts eq "";
    $texts = encode('utf-8', $texts) if utf8::is_utf8($texts);
    print $ofh $texts . "\t" . $DiseaseID . "\t" . $ParentIDs . "\t" . $FLAG . "\n";
}

