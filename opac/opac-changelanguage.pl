#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use C4::Templates;
use CGI qw ( -utf8 );

my $query    = new CGI;
my $language = $query->param('language');

# Detect where the user came from and save that url
my $requestedUrl = $query->url( -base => 1 );

# Use referer url if it matches $requestedUrl else use $requestedUrl as the url .
my $url =
  $query->referer() =~ $requestedUrl ? $query->referer() : $requestedUrl;

# warn "Language : $query // $language // $url";

# If language was set by an external URL the parameter
# 'language=' should be removed from url string, otherwise
# the language picker will not work
$url =~ s|(.)language=[\w-]*&?|$1|;
$url =~ s|(&\|\?)$||;    # Remove extraneous ? or &

C4::Templates::setlanguagecookie( $query, $language, $url );
