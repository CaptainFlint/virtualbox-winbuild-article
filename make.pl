#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

# Original template
my $src = 'article.tmpl';

# Language-specific configuration
my %langData = (
	'en' => {
		'href' => '//habr.com/en/post/357526/',
		'title' => 'Building VirtualBox for Windows'
	},
	'ru' => {
		'href' => '//habr.com/ru/post/357526/',
		'title' => 'Собираем VirtualBox под Windows'
	}
);

# Known target types and their handlers
my %typeHandler = (
	'habr' => sub ($$) {
		# Creating article contents for Habrabahr:
		# 1. Replace logo template with the specific image uploaded to Habrastorage.
		# 2. Replace bullet templates with corresponding images.
		# 3. Set the loopback logo link.
		my ($lang, $data_ref) = @_;
		$$data_ref =~ s!<%bullet%>!https://hsto.org/getpro/geektimes/post_images/9f8/505/49b/9f850549b13e79dc47d23f5f9e994379.png!gs;
		$$data_ref =~ s!<%logo%>!https://hsto.org/getpro/geektimes/post_images/122/274/f2b/122274f2b4098fd3b2d5eb703ce60fd3.png!gs;
		$$data_ref =~ s!<%selfref%>!$langData{$lang}->{'href'}!gs;
	},
	'raw'  => sub ($$) {
		# Creating stand-alone HTML article:
		# 1. Replace logo and bullet template with local images.
		# 2. Delete the loopback link target.
		# 3. Replace non-HTML tags with the standard ones.
		# 4. Cut off the UTF-8 BOM signature.
		# 5. Add HTML header and footer.
		my ($lang, $data_ref) = @_;
		$$data_ref =~ s!<%bullet%>!bullet.png!gs;
		$$data_ref =~ s!<%logo%>!header.png!gs;
		$$data_ref =~ s!<%selfref%>!!gs;
		$$data_ref =~ s!<cut text="[^\"]*" />!!gs;
		$$data_ref =~ s!<anchor>([^<>]*)</anchor>!<span id="$1"></span>!gs;
		$$data_ref =~ s!<source( [^<>]*|)>!<pre class="source"$1>!gs;
		$$data_ref =~ s!</source>!</pre>!gs;
		if (substr($$data_ref, 0, 3) eq "\xef\xbb\xbf") {
			$$data_ref = substr($$data_ref, 3);
		}
		$$data_ref = <<~DATA;
			<!DOCTYPE html>
			<html lang="$lang">
			<head>
			  <title>$langData{$lang}->{'title'}</title>
			  <meta charset='utf-8'>
			  <style type="text/css">
			    body {
			    	margin-left: 50%;
			    	font-family: Verdana;
			    	font-size: 14px;
			    	line-height: 22.4px;
			    }
			    div.wrapper {
			    	width: 740px;
			    	margin-left: -370px;
			    }
			    h4 {
			    	font-size: 16.8px;
			    	font-weight: 400;
			    	margin: 0;
			    }
			    h5 {
			    	font-size: 15.4px;
			    	font-weight: normal;
			    	margin: 0;
			    }
			    a {
			    	color: #6DA3BD;
			    	text-decoration: none;
			    }
			    blockquote {
			    	margin: 11px 0px;
			    	padding-left: 15px;
			    	border-left: 2px solid #BBBBBB;
			    }
			    pre.source {
			    	display: block;
			    	font-family: monospace, 'Courier New';
			    	font-size: 12px;
			    	background-color: #F8F8F8;
			    	white-space: pre-wrap;
			    }
			    code {
			    	font-size: 12px;
			    }
			    table {
			    	border-collapse: collapse;
			    	margin: 22px 0px;
			    }
			    th, td {
			    	border: 1px solid #BBBBBB;
			    	padding: 5px;
			    }
			  </style>
			</head>
			<body>
			<div class="wrapper">
			$$data_ref
			</div>
			</body>
			</html>
			DATA
	}
);

# Generic target maker
sub makeTarget($$) {
	my ($lang, $type) = @_;
	print "--> Making target: $lang-$type\n";
	my $dst = "article.$lang.$type.html";
	chdir($FindBin::Bin);
	my $f;
	my $data;
	# Reading the template contents
	open($f, '<', $src) or die "Failed to open source file '$src': $!";
	binmode($f);
	read($f, $data, -s $f);
	close($f);
	# Generate table of contents
	my $contents = '';
	while ($data =~ m!<anchor>([^<>]+)</anchor><h4><img src="<%bullet%>"/> (.*?)</h4>!gs) {
		$contents .= "» <a href=\"#$1\">$2</a><br/>\r\n";
	}
	$data =~ s!<%contents%>\r?\n!$contents!gs;
	# Delete the cosmetical EOLs between the language blocks and at the start/end of the source blocks.
	my @langs = sort(keys(%langData));
	my $langs_regexp = join('|', @langs);
	$data =~ s!(</$langs_regexp>)\r?\n(<$langs_regexp>)!$1$2!gs;
	$data =~ s!(<source[^<>]*>)\r?\n!$1!gs;
	$data =~ s!\r?\n(</source>)!$1!gs;
	# Language-specific processing: keep the text from the currently selected language tags, and delete all the others.
	for my $checkLang (sort(keys(%langData))) {
		if ($checkLang eq $lang) {
			$data =~ s!<$checkLang>(.*?)</$checkLang>!$1!gs;
		}
		else {
			$data =~ s!<$checkLang>(.*?)</$checkLang>!!gs;
		}
	}
	# Type-specific processing
	$typeHandler{$type}->($lang, \$data);
	# Dumping the output file
	open($f, '>', $dst) or die "Failed to open target file '$dst': $!";
	binmode($f);
	print $f $data;
	close($f);
	print "Success!\n\n";
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Main code

# List of all possible targets
my @all_targets = ();
for my $lang (sort(keys(%langData))) {
	for my $type (sort(keys(%typeHandler))) {
		push @all_targets, "$lang-$type";
	}
}

# User-specified list of targets to build (all targets by default)
my @targets = (scalar(@ARGV) ? @ARGV : @all_targets);

# Process the targets
for my $target (@targets) {
	my ($lang, $type) = split(m/-/, $target, 2);
	if (!$langData{$lang} || !$typeHandler{$type}) {
		print STDERR "ERROR! Skipping invalid make target: '$target'. Allowed targets: " . join(', ', @all_targets) . "\n\n";
	}
	else {
		makeTarget($lang, $type);
	}
}
