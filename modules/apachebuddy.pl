#!/usr/bin/perl
#
# author: jacob walcik
# version: 0.3
# description: This will make some recommendations on tuning your Apache 
# configuration based on your current settings and Apache's memory usage
#
# acknowledgements: This script was inspired by Major Hayden's MySQL Tuner
# (http://mysqltuner.com). 

use diagnostics;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);
use POSIX;
use strict;
use Term::ANSIColor;

# here we're going to build a list of the files included by the Apache 
# configuration
sub build_list_of_files {
	my ($base_apache_config,$apache_root) = @_;

	# these to arrays will contain lists of Apache configuration files
	# this is going to be the ultimate list of files that will be parsed 
	# searching for arguments
	my @master_list;
	# this will be a "scratch" space to store a list of files that 
	# currently need to be searched for more "include" lines
	my @find_includes_in;

	# put the main configuration file into the list of files we're going
	# to include
	push(@master_list,$base_apache_config);

	# put the main configuratino file into the list of files we need to 
	# search for include lines
	push(@find_includes_in,$base_apache_config);

	#get the Include lines from the main apache config
	@master_list = find_included_files(\@master_list,\@find_includes_in,$apache_root);
}

# here we're going to build an array holding the content of all of the 
# available configuration files
sub build_config_array {
	my ($base_apache_config,$apache_root) = @_;

	# these to arrays will contain lists of Apache configuration files
	# this is going to be the ultimate list of files that will be parsed 
	# searching for arguments
	my @master_list;

	# this will be a "scratch" space to store a list of files that 
	# currently need to be searched for more "include" lines
	my @find_includes_in;

	# put the main configuration file into the list of files we're going
	# to include
	push(@master_list,$base_apache_config);

	# put the main configuratino file into the list of files we need to 
	# search for include lines
	push(@find_includes_in,$base_apache_config);

	#get the Include lines from the main apache config
	@master_list = find_included_files(\@master_list,\@find_includes_in,$apache_root);
}

# this will find all of the files that need to be included
sub find_included_files {
	my ($master_list, $find_includes_in, $apache_root) = @_; 

	# get the number of elements in the array
	my $count = @$find_includes_in;

	# this array will eventually hold the entire apache configuration
	my @master_config_array;

	# while there are still entries in this array, keep processing
	while ( $count > 0 ) {
		my $file = $$find_includes_in[0];
		
		print "VERBOSE: Processing ".$file."\n" if $main::VERBOSE;

		# open the file
		open(FILE,$file) || die("Unable to open file: ".$file."\n");
		
		# push the file into an array
		my @file = <FILE>;

		# put the file in the master configuration array
		push(@master_config_array,@file);

		# close the file
		close(FILE);

		# search the file for includes
		foreach (@file) {

			# this will be used to store a list of any new include
			# lines found
			# my @new_includes; 

			# if the file doesn't start with a comment, then we want to examine it
			if ( $_ !~ m/^\s*#/ ) {
				# find lines that include other files
				if ( $_ =~ m/\s*include\s+/i ) {

					# grab the included file name or file glob
					$_ =~ s/\s*include\s+(.*)\s*/$1/i;

					# prepend the Apache root for files or
					# globs that are relative
					if ( $_ !~ m/^\// ) {
						$_ = $apache_root."/".$_;
					}

					# check for file globbing
					if ( $_ =~ m/.*\*.*/ ) {
						my $glob = $_;
						my @include_files;
						chomp($glob);

						# if the include is a file glob,
						# expand it and add the files
						# to the list
						my @new_includes = expand_included_files(\@include_files, $glob, $apache_root);
						push(@$master_list,@new_includes);
						push(@$find_includes_in,@new_includes);
					}
					else {
						# if it is not a glob, push the 
						# line into the configuration 
						# array
						push(@$master_list,$_);
						push(@$find_includes_in,$_);
					}
				}
			}	
		}
		# trim the first entry off the array now that we have 
		# processed it
		shift(@$find_includes_in);

		# get the new count of files left to look at
		$count = @$find_includes_in;
	}

	# return the config array with the included files attached
	return @master_config_array;
}

# this will expand a glob into a list of individual files
sub expand_included_files {
	my ($include_files, $glob, $apache_root) = @_;

	# use a call to ls to get a list of the files from the glob
	my @files = `ls $glob`;

	# add the files from the glob to the array we're going to pass back
	foreach(@files) {
		chomp($_);
		push(@$include_files,$_);
		print "VERBOSE: Adding ".$_." to list of files for processing\n" if $main::VERBOSE;
	}

	# return the include_files array with the files from the glob attached
	return @$include_files;
}

# search the configuration array for a defined value that is not inside of a 
# virtual host
sub find_master_value {
	my ($config_array, $model, $config_element) = @_;

	# store our results in an array
	my @results;

	# used to control whether or not we are currently ignoring elements 
	# while searching the array
	my $ignore = 0;

	my $ignore_by_model = 0;
	my $ifmodule_count = 0;

	# apache has two available models - prefork and worker. only one can be
	# in use at a time. we have already determined which model is being 
	# used
	my $ignore_model;
	
	if ( $model =~ m/.*worker.*/i ) {
		$ignore_model = "prefork";
	} else {
		$ignore_model = "worker";
	}

	print "VERBOSE: Searching Apache configuration for the ".$config_element." directive\n" if $main::VERBOSE;

	# search for the string in the configuration array
	foreach (@$config_array) {
		# ignore lines that are comments
		if ( $_ !~ m/^\s*#/ ) {
			chomp($_);

			# we ignore lines that are within a Directory, Location, 
			# File, or Virtualhost block
		
			# check to see if we have an opening tag for one of the 
			# block types listed above
			if ( $_ =~ m/^\s*<(directory|location|files|virtualhost|ifmodule\s.*$ignore_model)/i ) {
				#print "Starting to ignore lines: ".$_."\n";
				$ignore = 1;
			}
			# check for a closing block to stop ignoring lines
			if ( $_ =~ m/^\s*<\/(directory|location|files|virtualhost|ifmodule)/i ) {
				#print "Starting to watch lines: ".$_."\n";
				$ignore = 0;
			}

			# if we're not ignoring lines, check and see if we've 
			# found the configuration element we're looking for
			if ( $ignore != 1 ) {		
				# if we find a match
				if ( $_ =~ m/^\s*$config_element\s+.*/i ) {
					chomp($_);
					$_ =~ s/^\s*$config_element\s+(.*)/$1/i;
					push(@results,$_);
				}
			}
		}
	}

	# if we find multiple definitions for the same element, we should 
	# return the last one
	my $result;

	if ( @results > 1 ) {
		$result = $results[@results - 1];
	}
	else {
		$result = $results[0];
	}

	#Result not found
	if (@results == 0) {
		$result = "CONFIG NOT FOUND";
	}

	print "VERBOSE: $result " if $main::VERBOSE;
	# Ubuntu does not store the Apache user, group, or pidfile definitions 
	# in the apache2.conf file. instead, variables are in the configuration 
	# file and the real values are in /etc/apache2/envvars. this is a 
	# workaround for that behavior.
	if ( $config_element =~ m/[users|group|pidfile]/i && $result =~ m/^\$/i ) {
		if ( -e "/etc/debian_version" && -e "/etc/apache2/envvars") {
			print "VERBOSE: Using Ubuntu workaround for: ".$config_element."\n" if $main::VERBOSE;
			print "VERBOSE: Processing /etc/apache2/envvars\n" if $main::VERBOSE;

			open(ENVVARS,"/etc/apache2/envvars") || die "Could not open file: /etc/apache2/envvars\n";	
			my @envvars = <ENVVARS>;
			close(ENVVARS);

			# change "pidfile" to match Ubuntu's "pid_file" 
			# definition
			if ( $config_element =~ m/pidfile/i ) {
				$config_element = "pid_file";
			}

			foreach (@envvars) {
				if ( $_ =~ m/.*$config_element.*/i ) {
					chomp($_);
					$_ =~ s/^.*=(.*)\s*$/$1/i;
					$result = $_;
				}
			}
		}
	}

	# return the value to the main program
	return $result;
}

# this will examine the memory usage of the apache processes and return one of
# three different outputs: average usage across all processes, the memory usage
# by the largest process, or the memory usage by the smallest process
sub get_memory_usage {
	my ($process_name, $apache_user, $search_type) = @_;

	my (@proc_mem_usages, $result);

	# get a list of the pid's for apache running as the appropriate user
	my @pids = `ps aux | grep $process_name | grep -v root | grep $apache_user | awk \'{ print \$2 }\'`;

	# figure out how much memory each process is using
	foreach (@pids) {
		chomp($_);

		# pmap -d is used to determine the memory usage for the 
		# individual processes
		my $pid_mem_usage = `pmap -d $_ | grep writeable/private | awk \'{ print \$4 }\'`;
		$pid_mem_usage =~ s/K//;
		chomp($pid_mem_usage);

		print "VERBOSE: Memory usage by PID ".$_." is ".$pid_mem_usage."K\n" if $main::VERBOSE;
		
		# on a busy system, the grep output will return the pid for the
		# grep process itself, which will be gone by the time we get 
		# around to running pmap
		if ( $pid_mem_usage ne "" ) {
			push(@proc_mem_usages, $pid_mem_usage);
		}
	}

	# examine the array 
	if ( $search_type eq "high" ) {
		# to find the largest process, sort the values from largest to
		# smallest and take the first one
		@proc_mem_usages = sort { $b <=> $a } @proc_mem_usages;
		$result = $proc_mem_usages[0] / 1024;
	}
	if ( $search_type eq "low" ) {
		# to find the smallest process, sort the values from smallest to
		# largest and take the first one
		@proc_mem_usages = sort { $a <=> $b } @proc_mem_usages;
		$result = $proc_mem_usages[0] / 1024;
	}
	if ( $search_type eq "average" ) {
		# to get the average, add up the total amount of memory used by
		# each process, and then divide by the number of processes
		my $sum = 0; 
		my $count;
		foreach (@proc_mem_usages) {
			$sum = $sum + $_;
			$count++;
		} 

		# our result is in kilobytes, convert it to megabytes before 
		# returning it
		$result = $sum / $count / 1024;
	}
	
	# round off the result
	$result = round($result);

	return $result;
}

# this function accepts the path to a file and then tests to see whether the 
# item at that path is an Apache binary
sub test_process {
	my ($process_name) = @_;

	# the first line of output from "httpd -V" should tell us whether or
	# not this is Apache
	my @output = `$process_name -V`;

	print "VERBOSE: First line of output from \"$process_name -V\": $output[0]" if $main::VERBOSE;

	my $return_val = 0;

	# check for output matching Apache's
	if ( $output[0] =~ m/^Server version.*Apache\/[0-9].*/ ) {
		$return_val = 1;
	} 
	else {
		$return_val = 0;
	}

	return $return_val;
}

# this will return the pid for the process listening on the port specified
sub get_pid {
	my ( $port ) = @_;

	# find the pid for the software listening on the specified port. this
	# might return multiple values depending on Apache's listen directives
	my @pids = `netstat -ntap | grep LISTEN | grep \":$port \" | awk \'{ print \$7 }\' | cut -d / -f 1`;

	print "VERBOSE: ".@pids." found listening on port 80\n" if $main::VERBOSE;

	# set an initial, invalid PID. 
	my $pid = 0;;
	foreach (@pids) {
		chomp($_);
		$_ =~ s/(.*)\/.*/$1/;
		if ( $pid == 0 ) {
			$pid = $_;
		}
		elsif ( $pid != $_ ) {
			print "There are multiple PIDs listening on port 80.";
			exit;
		}
		else { 
			$pid = $_;
		}
	}

	# return the pid, or 0 if there is no process listening on that port
	if ( $pid eq '' ) {
		$pid = 0;
	}

	print "VERBOSE: Returning a PID of ".$pid."\n" if $main::VERBOSE;

	return $pid;
}

# this will return the path to the application running with the specified pid
sub get_process_name {
	my ( $pid ) = @_;

	print "VERBOSE: Finding process running with a PID of ".$pid."\n" if $main::VERBOSE;

	# based on the process name, we can figure out where the binary lives
	my $process_name = `ps ax | grep "\^[[:space:]]*$pid\[[:space:]]" | awk \'{print \$5 }\'`;
	chomp($process_name);

	print "VERBOSE: Found process ".$process_name."\n" if $main::VERBOSE;

	# return the process name, or 0 if there is no name found
	if ( $process_name eq '' ) {
		$process_name = 0;
	}

	return $process_name;
}

# this will return the apache root directory when given the full path to an
# Apache binary
sub get_apache_root {
	my ( $process_name ) = @_;
	# use the identified Apache binary to figure out where the root directory is 
	# for the Apache instance
	my $apache_root = `$process_name -V | grep \"HTTPD_ROOT\"`;
	$apache_root =~ s/.*=\"(.*)\"/$1/;
	chomp($apache_root);

	if ( $apache_root eq '' ) {
		$apache_root = 0;
	}

	return $apache_root;
}

# this will return the apache configuration file, relative to the apache root
# for the provided apache binary
sub get_apache_conf_file {
	my ( $process_name ) = @_;
	my $apache_conf_file = `$process_name -V | grep \"SERVER_CONFIG_FILE\"`;
	$apache_conf_file =~ s/.*=\"(.*)\"/$1/;
	chomp($apache_conf_file);

	# return the apache configuration file, or 0 if there is no result
	if ( $apache_conf_file eq '' ) {
		$apache_conf_file = 0;
	}

	return $apache_conf_file;
}

# this will determine whether this apache is using the worker or the prefork
# model based on the way the binary was built
sub get_apache_model {
	my ( $process_name ) = @_;
	my $model = `$process_name -l | egrep "worker.c|prefork.c"`;
	chomp($model);
	$model =~ s/\s*(.*)\.c/$1/;

	# return the name of the MPM, or 0 if there is no result
	if ( $model eq '' ) {
		$model = 0 ;
	}

	return $model;
}

# this will get the Apache version string
sub get_apache_version {
	my ( $process_name ) = @_;
	my $version = `$process_name -V | grep "Server version"`;
	chomp($version);
	$version =~ s/.*:\s(.*)$/$1/;

	if ( $version eq '' ) {
		$version = 0;
	}

	return $version
}

# this will us ps to determine the Apache uptime. it returns an array 
sub get_apache_uptime {
	my ( $pid ) = @_;

	# this will return the running time for the given pid in the format 
	# "days-hours:minutes:seconds"
	my $uptime = `ps -eo \"\%p \%t\" | grep $pid | grep -v grep | awk \'{ print \$2 }\'`;
	chomp($uptime);

	print "VERBOSE: Raw uptime: $uptime\n" if $main::VERBOSE;

	# check to see if we've been running for multiple days
	my ($days, $hours, $minutes, $seconds);
	if ( $uptime =~ m/^.*-.*:.*:.*$/ ) {	
		$days = $uptime;
		$days =~ s/([0-9]*)-.*/$1/;

		# trim the days off of our uptime value
		$uptime =~ s/.*-(.*)/$1/;
	
		($hours, $minutes, $seconds) = split(':', $uptime);
	}
	elsif ( $uptime =~ m/^.*:.*:.*/ ) {
		$days = 0;
		($hours, $minutes, $seconds) = split(':', $uptime);
	}
	elsif ( $uptime =~ m/^.*:.*/) {
		$days = 0;
		$hours = 0;
		($minutes, $seconds) = split(':', $uptime);	
	}
	else {
		$days = 0;
		$hours = 0;
		$minutes = 00;
		$seconds = 00;
	}

	# push everything into an array to pass back
	my @apache_uptime = ( $days, $hours, $minutes, $seconds );

	

	return @apache_uptime;
}

# return the global value for a PHP setting
sub get_php_setting {
	my ( $php_bin, $element ) = @_;	

	# this will return an array with all of the local and global PHP 
	# settings
	my @php_config_array = `php -r "phpinfo(4);"`;

	my @results;

	# search the array for our desired setting
	foreach (@php_config_array) {
		chomp($_);
		if ( $_ =~ m/^\s*$element\s*/ ) {
			chomp($_);
			$_ =~ s/.*=>\s+(.*)\s+=>.*/$1/;
			push(@results, $_);
		}
	}

        # if we find multiple definitions for the same element, we should 
        # return the last one (just in case)
        my $result;

        if ( @results > 1 ) {
                $result = $results[@results - 1];
        }
        else {
                $result = $results[0];
        }

	# some PHP directives are measured in MB. we want to trim the "M" off
	# here for those that are
	$result =~ s/^(.*)M$/$1/;

        # return the value to the main program
        return $result;
}

sub generate_standard_report {
	my ( $available_mem, $maxclients, $apache_proc_highest, $model, $threadsperchild ) = @_;


	# print a report header
	print color 'bold white' if ! $main::NOCOLOR;
	print "### GENERAL REPORT ###\n";
	print color 'reset' if ! $main::NOCOLOR;

	# show what we're going to use to generate our numbers
	print "\nSettings considered for this report:\n\n";

	print "\tYour server's physical RAM:\t\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $available_mem."MB\n";
	print color 'reset' if ! $main::NOCOLOR;

	print "\tApache's MaxClients directive:\t\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $maxclients."\n";
	print color 'reset' if ! $main::NOCOLOR;

	print "\tApache MPM Model:\t\t\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $model ."\n";
	print color 'reset' if ! $main::NOCOLOR;

	print "\tLargest Apache process (by memory):\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $apache_proc_highest."MB\n";
	print color 'reset' if ! $main::NOCOLOR;

	if ($model eq "prefork") {
		# based on the Apache memory usage (size of the largest process, 
		# check to see if the maxclients setting for Apache is sane
		my $max_rec_maxclients = $available_mem / $apache_proc_highest;
		$max_rec_maxclients = floor($max_rec_maxclients);

		# determine the maximum potential memory usage by Apache
		my $max_potential_usage = $maxclients * $apache_proc_highest;
		my $max_potential_usage_pct = round(($max_potential_usage/$available_mem)*100);
		if ( $maxclients <= $max_rec_maxclients ) {
			print color 'bold green' if ! $main::NOCOLOR;
			print "[ OK ]"; 
			print color 'reset' if ! $main::NOCOLOR;
			print "\tYour MaxClients setting is within an acceptable range.\n";
			print "\tMax potential memory usage: \t\t";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage." MB" ;
			print color 'reset';
			print "\n\n";

			print "\tPercentage of RAM allocated to Apache\t";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage_pct." %" ;
			print color 'reset';
			print "\n\n";
		}
		else {
			print color 'bold red' if ! $main::NOCOLOR;
			print "[ !! ]";
			print color 'reset' if ! $main::NOCOLOR;
			print "\tYour MaxClients setting is too high. It should be no greater than ";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_rec_maxclients.".\n";
			print color 'reset';
			print "\tMax potential memory usage: ";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage." MB" ."($max_potential_usage_pct % of available RAM)" ;
			print color 'reset';
			print "\n\n";

			print "\tPercentage of RAM allocated to Apache\t\t";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage_pct." %" ;
			print color 'reset';
			print "\n\n";
		}
	}
	if ($model eq "worker") {
		my $max_rec_maxclients = int((($available_mem/$apache_proc_highest) * $threadsperchild)/25)*25;

		my $max_potential_usage = ($maxclients/$threadsperchild) * $apache_proc_highest;
		$max_potential_usage = round($max_potential_usage);
		my $max_potential_usage_pct = round(($max_potential_usage/$available_mem)*100);
		if ( $maxclients <= $max_rec_maxclients ) {
			print color 'bold green' if ! $main::NOCOLOR;
			print "[ OK ]"; 
			print color 'reset' if ! $main::NOCOLOR;
			print "\tYour MaxClients setting is within an acceptable range.\n";
			print "\t(Max potential memory usage: ";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage." MB" ."($max_potential_usage_pct % of available RAM)" ;
			print color 'reset';
			print ")\n\n";
			
			print "\tPercentage of RAM allocated to Apache\t\t";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage_pct." %" ;
			print color 'reset';
			print "\n\n";

		}
		else {
			print color 'bold red' if ! $main::NOCOLOR;
			print "[ !! ]";
			print color 'reset' if ! $main::NOCOLOR;
			print "\tYour MaxClients setting is too high. It should be no greater than ";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_rec_maxclients.".\n";
			print color 'reset';
			print "\tMax potential memory usage: ";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage." MB" ."($max_potential_usage_pct % of available RAM)" ;
			print color 'reset';
			print ")\n\n";

			print "\tPercentage of RAM allocated to Apache\t\t";
			print color 'bold white' if ! $main::NOCOLOR;
			print $max_potential_usage_pct." %" ;
			print color 'reset';
			print "\n\n";
		}
	}

	print "-----------------------------------------------------------------------\n";
}

# generate the optional report based on the server's PHP settings
sub generate_php_report {
	my ( $available_mem, $maxclients ) = @_;

	# get the php memory_limit setting
	my $apache_proc_php = get_php_setting('/usr/bin/php', 'memory_limit');

	# make a second recommendation based on potential PHP memory usage
	my $max_rec_maxclients = $available_mem / $apache_proc_php;
	$max_rec_maxclients = floor($max_rec_maxclients);

	# calculate the largest potential memory usage
	my $max_potential_usage = $apache_proc_php * $maxclients;

	# print a report header
	print color 'bold white' if ! $main::NOCOLOR;
	print "### PHP REPORT ###\n";
	print color 'reset' if ! $main::NOCOLOR;

	# show what we're going to use to generate our numbers
	print "\nSettings considered for this report:\n\n";
	print "\tYour server's physical RAM:\t\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $available_mem."MB\n";
	print color 'reset' if ! $main::NOCOLOR;
	print "\tApache's MaxClients directive:\t\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $maxclients."\n";
	print color 'reset' if ! $main::NOCOLOR;
	print "\tPHP's memory_limit setting:\t\t";
	print color 'bold' if ! $main::NOCOLOR;
	print $apache_proc_php."MB\n";
	print color 'reset' if ! $main::NOCOLOR;
	print "-----------------------------------------------------------------------\n";

	# see if the maxclients directive is below the calculated threshold
	if ( $maxclients <= $max_rec_maxclients ) {
		print color 'bold green' if ! $main::NOCOLOR;
		print "[ OK ]";
		print color 'reset' if ! $main::NOCOLOR;
		print "\tYour MaxClients setting is within an acceptable range.\n";
		print "\t(max potential memory usage by PHP under Apache: ";
		print color 'bold white';
		print $max_potential_usage."MB";
		print color 'reset';
		print ")\n\n";
	}
	else {
		print color 'bold red' if ! $main::NOCOLOR;
		print "[ !! ]";
		print color 'reset' if ! $main::NOCOLOR;
		print "\tYour MaxClients setting is too high. It should be no greater\n\tthan ";
		print color 'bold white' if ! $main::NOCOLOR;
		print $max_rec_maxclients.".\n";
		print color 'reset';
		print "\t(max potential memory usage by PHP under Apache: ";
		print color 'bold white';
		print $max_potential_usage."MB";
		print color 'reset';
		print ")\n\n";
	}
}

# this rounds a value to the nearest hundreth
sub round {
	my ( $value ) = @_;

	# add five thousandths
	$value = $value + 0.005;

	# truncat the result
	$value = sprintf("%.2f", $value);

	return $value;
}	

#Return the number of CPU cores
sub get_cores {
    my $cmd = 'egrep ' . "'". '^physical id|^core id|^$' . "'" . ' /proc/cpuinfo | awk '. "'" . 'ORS=NR%3?",":"\n"' . "'" . '| sort | uniq | wc -l';
    my $cmd_out = `$cmd`;
    chomp $cmd_out;
    return $cmd_out;
}


# print usage
sub usage {
	print "Usage: apachebuddy.pl [OPTIONS]\n";
	print "If no options are specified, the basic tests will be run.\n";
	print "\n";
	print "\t-h, --help\tPrint this help message\n";
	print "\t-p, --port=PORT\tSpecify an alternate port to check (default: 80)\n";
	print "\t-P, --php\tInclude the PHP memory_limit setting when making the recommendation\n";
	print "\t-v, --verbose\tUse verbose output (this is very noisy, only useful for debugging)\n";
	print "\n";
}

# print a header
sub print_header {
	print color 'bold white' if ! $main::NOCOLOR;
	print "########################################################################\n";
	print "# Apache Buddy v 0.2 ###################################################\n";
	print "########################################################################\n";
	print color 'reset' if ! $main::NOCOLOR;
}

########################
# GATHER CMD LINE ARGS #
########################

# if help is not asked for, we do not give it
my $help = "";

# if no port is specified, we default to 80
my $port = 80;

# by default, do not include PHP in the check
my $php = 0;

# by default, do not use verbose output
our $VERBOSE = "";

# by default, use color output
our $NOCOLOR = 0;

# grab the command line arguments
GetOptions('help|h' => \$help, 'port|p:i' => \$port, 'php|P' => \$php, 'verbose|v' => \$VERBOSE, 'nocolor' => \$main::NOCOLOR);

# check for invalid options, bail if we find any and print the usage output
if ( @ARGV > 0 ) {
	print "Invalid option: ";
	foreach (@ARGV) {
		print $_." ";
	}
	print "\n";
	usage;
	exit;
}

########################
# BEGIN MAIN EXECUTION #
########################

# make sure the script is being run as root
my $uid = `id -u`;
chomp($uid);

print "VERBOSE: UID of user is: ".$uid."\n" if $VERBOSE;

# we need to run as root to ensure that we can access all of the appropriate 
# files
if ( $uid ne '0' ) {
	print "This script must be run as root.\n";
	exit;
}

# this script uses pmap to determine the memory mapped to each apache 
# process. make sure that pmap is available.
my $pmap = `which pmap`;
chomp($pmap);

# make sure that pmap is available within our path
if ( $pmap !~ m/.*\/pmap/ ) { 
	print "Unable to locate the pmap utility. This script requires pmap to analyze Apache's memory consumption.\n";
	exit;
}

# make sure PHP is available before we proceed
if ( $php == 1 ) {
	# check to see if there is a binary called "php" in our path
	my $check = `which php`;

	if ( $check eq '' ) {
		print "Unable to locate the PHP binary.\n";

		my $path = `echo \$PATH`;
		chomp($path);
		print "VERBOSE: Path: $path\n" if $VERBOSE;

		exit;
	}
}

# if the user has added the help flag, or if they have defined a port  
if ( $help eq 1 || $port eq 0 ) {
	usage();
	exit;
}
elsif ( $port < 0 || $port > 65534 ) {
	print "INVALID PORT: $port\n";
	print "Valid port numbers are 1-65534\n";
	exit;
}
else {
	# print the header
	print_header;

	print color 'bold white' if ! $NOCOLOR;
	print "Gathering information...\n";
	print color 'reset' if ! $NOCOLOR;

	# first thing we do is get the pid of the process listening on the 
	# specified port
	print "We are checking the service running on port ".$port."\n";
	my $pid = get_pid($port);

	print "VERBOSE: PID is ".$pid."\n" if $VERBOSE;

	if ( $pid eq 0 ) {
		print "Unable to determine PID of the process.";
		exit;
	}

	# now we get the name of the process running with the specified pid
	my $process_name = get_process_name($pid);
	print "The process listening on port ".$port." is ".$process_name."\n";
	if ( $process_name eq 0 ) {
		print "Unable to determine the name of the process.";
		exit;
	}

	# check to see if there is a file in the file system at the path 
	# identified
	if  ( ! -e $process_name ) {
		print "File .".$process_name." does not exist.\n";
		exit;
	}

	# check to see if the process we have identified is Apache
	my $is_it_apache = test_process($process_name);

	if ( $is_it_apache == 1 ) {
		my $apache_version = get_apache_version($process_name);

		print "VERBOSE: Apache version: $apache_version\n" if $VERBOSE;

		# if we received a "0", just print "Apache"
		if ( $apache_version eq 0 ) {
			$apache_version = "Apache";	
		}

		print "The process running on port 80 is $apache_version\n";
	}
	else {
		print "The process running on port 80 is not Apache\n";
		exit;
	}

	# determine the Apache uptime
	my @apache_uptime = get_apache_uptime($pid);
	print "Apache has been running ".$apache_uptime[0]."d ".$apache_uptime[1]."h ".$apache_uptime[2]."m ".$apache_uptime[3]."s\n";

	# find the apache root	
	my $apache_root = get_apache_root($process_name);

	print "VERBOSE: The Apache root is: ".$apache_root."\n" if $VERBOSE;
	
	# find the apache configuration file (relative to the apache root)
	my $apache_conf_file = get_apache_conf_file($process_name);
	print "VERBOSE: The Apache config file is: ".$apache_conf_file."\n" if $VERBOSE;

	# piece together the full path to the configuration file, if a server 
	# does not have the HTTPD_ROOT value defined in its apache build, then
	# try just using the path to the configuration file
	my $full_apache_conf_file_path;
	if ( -e $apache_conf_file ) {
		$full_apache_conf_file_path = $apache_conf_file;
		print "The full path to the Apache config file is: ".$full_apache_conf_file_path."\n";
	}
	elsif ( -e $apache_root."/".$apache_conf_file ) {
		$full_apache_conf_file_path = $apache_root."/".$apache_conf_file;
		print "The full path to the Apache config file is: ".$full_apache_conf_file_path."\n";
	}
	else {
		print "Apache configuration file does not exist: ".$full_apache_conf_file_path."\n";
		exit;
	}

	# find out if we're using worker or prefork
	my $model = get_apache_model($process_name);	
	if ( $model eq 0 ) {
		print "Unable to determine whether Apache is using worker or prefork\n";
	}
	else {
		print "Apache is using $model model\n";
	}

	print color 'bold white' if ! $NOCOLOR;
	print "\nExamining your Apache configuration...\n";
	print color 'reset' if ! $NOCOLOR;

	# get the entire config, including included files, into an array
	my @config_array = build_config_array($full_apache_conf_file_path,$apache_root);

	# determine what user apache runs as 
	my $apache_user = find_master_value(\@config_array, $model, 'user');
	print "Apache runs as ".$apache_user."\n";

	# determine what the max clients setting is 
	my $maxclients = find_master_value(\@config_array, $model, 'maxclients');
	print "Your max clients setting is ".$maxclients."\n";

	#calculate ThreadsPerChild. This is useful for the worker MPM calculations
       	my $threadsperchild = find_master_value(\@config_array, $model, 'threadsperchild');
       	my $serverlimit = find_master_value(\@config_array, $model, 'serverlimit');

	if ($model eq "worker") {
		print "Your ThreadsPerChild setting for worker MPM is  ".$threadsperchild."\n";
		print "Your ServerLimit setting for worker MPM is  ".$serverlimit."\n";
	}

	print color 'bold white' if ! $NOCOLOR;
	print "\nAnalyzing memory use...\n";
	print color 'reset' if ! $NOCOLOR;

	# figure out how much RAM is in the server
	my $available_mem = `free | grep \"Mem:\" | awk \'{ print \$2 }\'` / 1024;
	$available_mem = floor($available_mem);

	print "Your server has ".$available_mem." MB of memory\n";

	my $apache_proc_highest = get_memory_usage($process_name, $apache_user, 'high');
	my $apache_proc_lowest = get_memory_usage($process_name, $apache_user, 'low');
	my $apache_proc_average = get_memory_usage($process_name, $apache_user, 'average');


	if ( $model eq "prefork") {
		print "The largest apache process is using ".$apache_proc_highest." MB of memory\n";
		print "The smallest apache process is using ".$apache_proc_lowest." MB of memory\n";
		print "The average apache process is using ".$apache_proc_average." MB of memory\n";

		my $average_potential_use = $maxclients * $apache_proc_average;
		$average_potential_use = round($average_potential_use);
		my $average_potential_use_pct = round(($average_potential_use/$available_mem)*100);
		print "Going by the average Apache process, Apache can potentially use ".$average_potential_use." MB RAM ($average_potential_use_pct % of available RAM)\n" ;

		my $highest_potential_use = $maxclients * $apache_proc_highest;
		$highest_potential_use = round($highest_potential_use);
		my $highest_potential_use_pct = round(($highest_potential_use/$available_mem)*100);
		print "Going by the largest Apache process, Apache can potentially use ".$highest_potential_use." MB RAM ($highest_potential_use_pct % of available RAM)\n" ;
	}

	if ( $model eq "worker") {
		print "The largest apache process is using ".$apache_proc_highest." MB of memory\n";
		print "The smallest apache process is using ".$apache_proc_lowest." MB of memory\n";
		print "The average apache process is using ".$apache_proc_average." MB of memory\n";

		my $highest_potential_use = ($maxclients/$threadsperchild) * $apache_proc_highest;
		$highest_potential_use = round($highest_potential_use);
		my $highest_potential_use_pct = round(($highest_potential_use/$available_mem)*100);
		print "Going by the largest Apache process, Apache can potentially use ".$highest_potential_use." MB RAM ($highest_potential_use_pct % of available RAM)\n" ;
	}
	print color 'bold white' if ! $NOCOLOR;
	print "\nGenerating reports...\n";
	print color 'reset' if ! $NOCOLOR;

	# determine which report we're generating
	if ( $php == 1 ) {
		generate_php_report($available_mem, $maxclients);
	}
	else {
		generate_standard_report($available_mem, $maxclients, $apache_proc_highest, $model, $threadsperchild);
	}
}

print "-----------------------------------------------------------------------\n";
