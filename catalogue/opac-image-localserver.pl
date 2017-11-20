#!/usr/bin/perl
#
# Copyright (C) 2011 C & P Bibliography Services
# Jared Camins-Esakov <jcamins@cpbibliograpy.com>
#
# based on patronimage.pl
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
#

use strict;
use warnings;

use CGI;
use C4::Context;
use C4::Images;
use Image::Grab qw(grab);
use GD;

$| = 1;

my $DEBUG = 0;
my $data  = new CGI;
my $imagenumber;

=head1 NAME

opac-image.pl - Script for retrieving and formatting local cover images for display

=head1 SYNOPSIS

<img src="opac-image.pl?imagenumber=X" />
<img src="opac-image.pl?biblionumber=X" />
<img src="opac-image.pl?imagenumber=X&thumbnail=1" />
<img src="opac-image.pl?biblionumber=X&thumbnail=1" />

=head1 DESCRIPTION

This script, when called from within HTML and passed a valid imagenumber or
biblionumber, will retrieve the image data associated with that biblionumber
if one exists, format it in proper HTML format and pass it back to be displayed.
If the parameter thumbnail has been provided, a thumbnail will be returned
rather than the full-size image. When a biblionumber is provided rather than an
imagenumber, a random image is selected.

=cut

sub _fetch_image 
{
	my ($imagenumber, $size ) = @_;

	my $dbh = C4::Context->dbh;
	my $barcodeQuery = q/select barcode from items where barcode is not NULL and barcode not like '#%' and biblionumber = ? /;

	my $sth = $dbh->prepare($barcodeQuery); 
	$sth->execute($imagenumber); 
	my @row;

	my @barcodelist;

	while ( @row = $sth->fetchrow_array ) {
	        push (@barcodelist,join('',@row));
	}

	my $barcodes=join(",",@barcodelist); 

	my $query = "select SUBSTRING_INDEX(isbn,' ', 1) as isbn  from biblioitems WHERE biblionumber= ? "; 
	$sth = $dbh->prepare($query);
	$sth->execute($imagenumber);
	my $row = $sth->fetchrow_hashref();
		
	if ( $row ) { 
		my $isbn = $row->{'isbn'} // '';
		if ( length( $isbn ) > 0 || length ( $barcodes) > 0  ) {
			my $barcode_str='';
			my $isbn_str='';
			if ( length ( $isbn ) > 0 )  {
				$isbn_str="?isbn=".$isbn;
			}
			if ( length ( $barcodes ) > 0 )  {
				if ( length ( $isbn ) > 0 ) {  
					$barcode_str="&barcode=".$barcodes; 
				}
				else {
					$barcode_str="?barcode=".$barcodes; 
				}
				
			}

			my $url_string=$isbn_str.$barcode_str;
			my $srcimage=grab(URL=>'https://covers.nlg.gr/'.$url_string.'&wm=no&size='.$size);
				
			return $srcimage;
		}
		else {
			return;
		}
	}



}

my ( $image, $mimetype ) = C4::Images->NoImage;
if ( C4::Context->preference("OPACLocalCoverImages") ) {
	    my $biblionumber = $data->param('biblionumber');
	    my $size='large';
	    if ( $data->param('thumbnail') ) {
		$size  = 'med';
	    }


	    $image=_fetch_image($biblionumber,$size) // '';

}
print $data->header(
    -type            => 'image/jpeg',
    -expires         => '+30m',
    -Content_Length  => length($image)
), $image;

=head1 AUTHOR

Chris Nighswonger cnighswonger <at> foundations <dot> edu

modified for local cover images by Koustubha Kale kmkale <at> anantcorp <dot> com

=cut
