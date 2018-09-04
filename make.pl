#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

my @targets = (scalar(@ARGV) ? @ARGV : ('gt', 'html'));
my $src = 'article.tmpl';

my %makeFuncs = ('gt' => \&makeGT, 'html' => \&makeHTML);

sub makeGT() {
	print "--> Making target: gt\n";
	my $dst = 'article.gt.html';
	chdir($FindBin::Bin);
	my $f;
	my $data;
	open($f, '<', $src) or die "Failed to open source file '$src': $!";
	binmode($f);
	read($f, $data, -s $f);
	close($f);
	$data =~ s!<%bullet%>!https://habrastorage.org/getpro/geektimes/post_images/9f8/505/49b/9f850549b13e79dc47d23f5f9e994379.png!gs;
	$data =~ s!<%logo%>!https://habrastorage.org/getpro/geektimes/post_images/122/274/f2b/122274f2b4098fd3b2d5eb703ce60fd3.png!gs;
	$data =~ s!<%selfref%>!//habr.com/post/357526/!gs;
	open($f, '>', $dst) or die "Failed to open target file '$dst': $!";
	binmode($f);
	print $f $data;
	close($f);
	print "Success!\n\n";
}

sub makeHTML() {
	print "--> Making target: gt\n";
	my $dst = 'article.html';
	chdir($FindBin::Bin);
	my $f;
	my $data;
	open($f, '<', $src) or die "Failed to open source file '$src': $!";
	binmode($f);
	read($f, $data, -s $f);
	close($f);
	$data =~ s!<%bullet%>!bullet.png!gs;
	$data =~ s!<%logo%>!header.png!gs;
	$data =~ s!<%selfref%>!!gs;
	$data =~ s!<cut text="[^\"]*" />!!gs;
	$data =~ s!<anchor>([^<>]*)</anchor>!<span id="$1"></span>!gs;
	$data =~ s!<source( [^<>]*|)>!<pre class="source"$1>!gs;
	$data =~ s!</source>!</pre>!gs;
	open($f, '>', $dst) or die "Failed to open target file '$dst': $!";
	binmode($f);
	print $f <<DATA;
<!DOCTYPE html>
<html lang="ru">
<head>
  <title>Building VirtualBox for Windows</title>
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
DATA
	print $f $data;
	print $f <<DATA;
</div>
</body>
</html>
DATA
	close($f);
	print "Success!\n\n";
}

for my $target (@targets) {
	die "Invalid make target: '$target'. Allowed targets: " . join(', ', sort(keys(%makeFuncs))) . "\n" if (!$makeFuncs{$target});
}
for my $target (@targets) {
	$makeFuncs{$target}->();
}
