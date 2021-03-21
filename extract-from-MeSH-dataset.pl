#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;
use Encode;
use vars qw($opt_h $opt_i $opt_o);
&getopts('hi:o:');

# Usage
my $usage = <<_EOH_;

## Options ###########################################
## Required:
# -i    input dataset file (d2020.bin or c2020.bin)
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
my $ifh = openIfh( $inFile );
my $ofh = openOfh( $outFile );

# Extract from CTD disease dataset
my $cnt = 0;
writeHeader($ofh);
while( my $mesh = fetch($ifh) ) {
    last if !defined $mesh->{UI};
    ++$cnt;
    writeData( $ofh, $mesh );
}

print STDERR "Valid entry in the input dataset = $cnt\n";

# Close file handlers
close $ifh;
close $ofh;

sub openIfh {
    my $file = shift;
    my $ifh;
    open $ifh, $file or die "Can't open the file [ $file ] to read.";
    return $ifh;
}

sub openOfh {
    my $file = shift;
    my $ofh;
    open $ofh, ">$file" or die "Can't open the file [ $file ] to write.";
    return $ofh;
}

sub fetch {
    my $ifh = shift;
    my $mesh = {
	"UI"          => undef,
	"MH"          => [],
	"DS"          => [],
	"PRINT ENTRY" => [],
	"ENTRY"       => [],
	"MS"          => []
    };
    my $flag = 0;
    while(<$ifh>) {
	chomp;
	if( $_ eq "*NEWRECORD" ) {
	    $flag = 1;
	} elsif( $_ eq "" ) {
	    $flag = 0;
	    last;
	} elsif( $flag ) {
	    my @cols = split(" = ", $_);
	    if( scalar(@cols) >= 2 ) {
		my $tag = $cols[0];
		my $val = join( " = ", @cols[1..(scalar(@cols)-1)] );
		$mesh->{UI} = "MeSH:".$val if isUiTag( $tag );
		push( @{$mesh->{$tag}}, $val ) if isTargetTag( $tag );
	    } else {
		print STDERR "Invalid entry: $_\n";
	    }
	}
    }
    return $mesh;
}

sub isUiTag {
    my $tag = shift;
    return 1 if $tag eq "UI";
    return 0;
}

sub isTargetTag {
    my $tag = shift;
    return 1 if $tag eq "MH";
    return 1 if $tag eq "DS";
    return 1 if $tag eq "PRINT ENTRY";
    return 1 if $tag eq "ENTRY";
    return 1 if $tag eq "MS";
    return 0;
}

sub writeHeader {
    my $ofh = shift;
    print $ofh "Texts" . "\t" . "MeSH ID" . "\t" . "ParentIDs" . "\t" . "FLAG" . "\n";
}

sub writeData {
    my $ofh  = shift;
    my $mesh = shift;
    my $ui   = $mesh->{"UI"};

    # Write MH
    my $mh = $mesh->{"MH"};
    foreach my $val (@$mh) {
	writeLine( $ofh, $val, $ui, "", "MH" );
    }

    # Write DS
    my $ds = $mesh->{"DS"};
    foreach my $val (@$ds) {
	writeLine( $ofh, $val, $ui, "", "DS" );
    }

    # Write PRINT ENTRY
    my $print_entry = $mesh->{"PRINT ENTRY"};
    foreach my $val (@$print_entry) {
	my @cols = split('\|', $val);
	writeLine( $ofh, $cols[0], $ui, "", "PRINT ENTRY" );
    }

    # Write ENTRY
    my $entry = $mesh->{"ENTRY"};
    foreach my $val (@$entry) {
	my @cols = split('\|', $val);
	writeLine( $ofh, $cols[0], $ui, "", "ENTRY" );
    }

    # Write MS
    my $ms = $mesh->{"MS"};
    foreach my $val (@$ms) {
	my @defs = split( '\. ', $val );
	foreach my $def (@defs) {
	    $def =~ s/^ //;
	    $def = $def."." unless $def =~ /\.$/;
	    writeLine( $ofh, $def, $ui, "", "MS" );
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

