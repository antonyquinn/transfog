#!/usr/bin/perl

#
# Create sample GFF file from IPI xrefs
# @author   Antony Quinn
# @version  09-Dec-04
# @todo     Put all Bash code in here
# @todo     Write entries not in UniProt to STDERR
#

use strict;

main();

sub main {
    unless(@ARGV) {
	    print "Usage: $0 file skip-lines max-lines\n\n";
	    exit;
    }
    print getGff("$ARGV[0]", $ARGV[1], $ARGV[2]);
}

sub getGff	{
    my ($file, $skipLines, $maxLines) = @_;
    open (FILE, $file) || die("Can't open $file: $!");
    my $gff = "";
    $gff .= "##gff-version 2\n";
    $gff .= "##date ".localtime."\n";
    $gff .= "# IntelliJ doesn't get the tabs right for some reason - use text editor to be safe\n";
    $gff .= "# <seqname> 	<source> 	<feature> <start> <end> <score> <strand> <frame> [attributes] [comments]\n";
    my $lineNumber = 1;
    while (my $record = <FILE>)	{
       if ($lineNumber <= $maxLines && $lineNumber > $skipLines)	{
       	$gff .= convertRecord($record, $lineNumber - $skipLines);
       }
       $lineNumber++;
    }
    return $gff;
}

sub convertRecord	{
    my ($record, $rank) = @_;
    my $start=0;
    my $end=0;
    $record =~ s/.*IPI/IPI/g;
    $record =~ s/(IPI[0-9]*).*/$1\tTR:000\tscreening\t$start\t$end\t$rank\t.\t.\tOntology_id "TR:001" ; Note "Experimental notes for candidate $rank"/g;
    return $record;
}