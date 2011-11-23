#!/usr/bin/perl -w
# parsar
# parse sar logs into a more readable, condensed format
# v0.13
# Jonathan Kelly (jkelly@rackspace.com)

# BUG: No year in timestamp, so on year rollover data is printed out of sequence

use strict;
use warnings;
use Getopt::Long;

# subroutine declarations go here
sub print_help;
sub print_values; #TIMESTAMP, CPU, IOWAIT, MEMORY, MEMORY_FREE, SWAP
sub print_header;

# global variables go here
my %data; # $data{date}{time}{metric} = $value
my $date;

# get options
my %args;
my $options_ok = GetOptions ( \%args,
    'verbose|v',
    'help|h',
    'daily|d',
    'raw|r',
    'peak|p',
    'peakonly|o'
);

if ( ! $options_ok ) {
    print_help;
    die "Error: Invalid option\n";
}

if ( $args{daily} && $args{raw} ) {
    die "--daily and --raw are mutually exclusive\n";
}
elsif ( $args{raw} && $args{peak} ) {
    die "--raw and --peak are mutually exclusive\n";
}

# print help and exit
if ( $args{help} ) {
    print_help;
}

# get list of sar files
# TODO: customizable log directory via config file
my @logs = glob("/var/log/sa/sa[0-9]*");
if ( ! @logs ) { die "No sar logs found in /var/log/sa/sa*\n"; }
if ( $args{verbose} ) {
    print "Found logs: \n";
    for ( @logs ) {
        print "$_\n";
    }
    print "\n";
}

# process logs
# we want CPU, IOWait, Memory and Swap
for ( @logs ) {
    my $log = $_;
    if ( $args{verbose} ) { print "Processing: $log\n"; }
    my $FH;
    # get CPU data
    open( $FH, "sar -f $log|egrep -v \"CPU|^\$|RESTART|Average\"|" );
    # get the day in mm/dd format, since I am into the whole brevity thing
    my $line = <$FH>;
    $line =~ /\s+(\d+\/\d+)\/\d+$/;
    $date = $1;
    chomp($date);
    while ( <$FH> ) {
        # ghetto fix
        my $line = $_;
        my ($time, $ampm, $junk, $user, $nice, $system, $iowait, @junk);
        if ( $line =~ m/(AM|PM)/ ) {
            ($time, $ampm, $junk, $user, $nice, $system, $iowait, @junk) =
            split(/\s+/, $line);
            # convert time and ampm to military
            $time =~ /(\d+):(\d+)/;
            $time = $1 . $2;
            # special case for 12AM and 12PM, 12AM=0000, 12pm=1200
            if ( $time <= 1259 && $time >= 1200 ) { $time -= 1200; }
            if ( $ampm eq "PM" ) { $time += 1200; }
        }
        else {
            ($time, $junk, $user, $nice, $system, $iowait, @junk) =
            split(/\s+/, $line);
            $time =~ /(\d+):(\d+)/;
            $time = $1 . $2;
        }
        $data{$date}{$time}{cpu} = $user + $nice + $system;
        $data{$date}{$time}{io} = $iowait;
    }
    close($FH);

    # get memory data
    open( $FH, "sar -r -f $log|egrep -v \"mem|^\$|Average|RESTART|Linux\"|" );
    while ( <$FH> ) {
        my $line = $_;
        my ($time, $ampm, $mfree, $mused, $junk, $mbuf, $mcache, $jnk, $swap);
        if ( $line =~ m/(AM|PM)/ ) {
            ($time, $ampm, $mfree, $mused, $junk, $mbuf, $mcache, $jnk, $swap) =
            split(/\s+/, $line);
            # convert time and ampm to military
            $time =~ /(\d+):(\d+)/;
            $time = $1 . $2;
            # special case for 12AM and 12PM, 12AM=0000, 12pm=1200
            if ( $time <= 1259 && $time >= 1200 ) { $time -= 1200; }
            if ( $ampm eq "PM" ) { $time += 1200; }
        }
        else {
            ($time, $mfree, $mused, $junk, $mbuf, $mcache, $jnk, $swap) =
            split(/\s+/, $line);
            $time =~ /(\d+):(\d+)/;
            $time = $1 . $2;
        }
        $data{$date}{$time}{mem} = ($mused - $mbuf - $mcache) / 1024.0; # in Megs
        $data{$date}{$time}{memfree} = ($mfree + $mbuf + $mcache) / 1024.0; # in Megs
        $data{$date}{$time}{swap} = $swap / 1024.0; # in Megs
    }
    close($FH);
}

# output data day by day
# note that the time range is from 0010-2350, no 0000
# also, some times may be missing due to downtime/load
my ($cpu, $io, $mem, $memfree, $swap) = (0,0,0,0,0);
my ($pcpu, $pio, $pmem, $pmemfree, $pswap) = (0,0,0,0,0);
my ($curhour, $prevhour);
my $count = 1;

# we're going to maintain a running average, to account for missing
# data more easily
for ( sort keys ( %data ) ) {
    my $prevdate;
    if ( defined ($date) ) { $prevdate = $date; }
    $date = $_;
    my %dd = %{$data{$date}}; # date data
    # first run, print headers
    if ( ! defined $curhour ) {
        print "\n";
        print "$date\n" unless $args{daily};
        print_header;
    }

    for ( sort { $a <=> $b } keys( %dd ) ) {
        my $time = $_;
        my %ddt = %{$dd{$time}}; # data at a specific time
        # some kinda weird time tracking here... will be easier
        # from a database with timestamps
        if ( defined($curhour) ) { $prevhour = $curhour; }
        $curhour = int ($time / 100);
        my $ptime = sprintf("%04d", $time); # 0-padded time
        my $timestamp = $date . ":" . $ptime;
        # don't want to test any of this on our first pass
        if ( defined($prevhour) ) {
            if ( $prevhour > $curhour ) { # new day
                # date header goes here
                if ( $args{daily} ) {
                    my $timestamp = "$prevdate" . ":" . "$ptime";
                    print_values($timestamp,$cpu,$io,$mem,$memfree,$swap) unless $args{peakonly};
                    if ( $args{peak} || $args{peakonly} ) {
                        my $timestamp = "$prevdate" . ":peak";
                        print_values($timestamp,$pcpu,$pio,$pmem,$pmemfree,$pswap);
                    }
                    ($cpu, $io, $mem, $memfree, $swap) = (0,0,0,0,0);
                    ($pcpu, $pio, $pmem, $pmemfree, $pswap) = (0,0,0,0,0);
                    $count = 1;
                }
                else {
                    print "\n$date\n";
                    print_header;
                }
            }
            elsif ( $args{raw} ) {
                print_values($timestamp,$ddt{cpu},$ddt{io},$ddt{mem},$ddt{memfree},$ddt{swap});
                next;
            }
            elsif ( $curhour > $prevhour && ! $args{daily} ) { # new hour
                print_values($timestamp,$cpu,$io,$mem,$memfree,$swap) unless $args{peakonly};
                if ( $args{peak} || $args{peakonly} ) {
                    my $timestamp = $ptime . ":peak";
                    print_values($timestamp,$pcpu,$pio,$pmem,$pmemfree,$pswap);
                }
                ($cpu, $io, $mem, $memfree, $swap) = (0,0,0,0,0);
                ($pcpu, $pio, $pmem, $pmemfree, $pswap) = (0,0,0,0,0);
                $count = 1;
            }
        }
        if ( $args{peak} || $args{peakonly} ) {
            if ( $ddt{cpu} > $pcpu ) { $pcpu = $ddt{cpu}; }
            if ( $ddt{io} > $pio ) { $pio = $ddt{io}; }
            if ( $ddt{mem} > $pmem ) { $pmem = $ddt{mem}; }
            if ( $ddt{memfree} > $pmemfree ) { $pmemfree = $ddt{memfree}; }
            if ( $ddt{swap} > $pswap ) { $pswap = $ddt{swap}; }
        }
        $cpu = ($cpu * (($count-1)/$count)) + ($ddt{cpu}/$count);
        $io = ($io * (($count-1)/$count)) + ($ddt{io}/$count);
        $mem = ($mem * (($count-1)/$count)) + ($ddt{mem}/$count);
        $memfree = ($memfree * (($count-1)/$count)) + ($ddt{memfree}/$count);
        $swap = ($swap * (($count-1)/$count)) + ($ddt{swap}/$count);
    }
}

# subroutine definitions go here
# -----

# print help and exit
sub print_help {
    print "usage: parsar [options]\n";
    print "--daily/-d       Print daily summaries, rather than hourly\n";
    print "--raw/-r         Print 10-minute raw data, rather than hourly\n";
    print "--peak/-p        Print peak usage for each interval\n";
    print "--peakonly/-o    Print only peak usage data\n";
    print "--help/-h        Print this help message\n";
    print "--verbose/-v     Loquacious, elaborative output\n";
    exit;
}

# print values in a console-friendly manner
sub print_values { # $time, $cpu, $io, $mem, $memfree, $swap
    my ($t, $c, $i, $m, $mf, $s) = @_;
    printf("%10s %7.1f %9.1f %10.1fM %10.1fM %12.1fM\n", $t, $c, $i, $m, $mf, $s);
}

# print headers for the beginning of a set of values
sub print_header {
    print "TIMESTAMP     CPU%   IOWAIT%    MEM USED    MEM FREE     SWAP USED\n";
    print "---------     ----   -------    --------    --------     ---------\n";
}
