# ex:ts=8

package WWW::Scraper::ISBN::TWYlib_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.01';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::TWYlib_Driver - Search driver for TWYlib's online catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from the TWYlib's online catalog.

=cut

#--------------------------------------------------------------------------

###########################################################################
#Library Modules                                                          #
###########################################################################

use WWW::Scraper::ISBN::Driver;
use WWW::Mechanize;
use Template::Extract;

use Data::Dumper;

###########################################################################
#Constants                                                                #
###########################################################################

use constant	QUERY	=> 'http://tsearch.ylib.com/tsearch/tp.asp?query=%s';

#--------------------------------------------------------------------------

###########################################################################
#Inheritence                                                              #
###########################################################################

@ISA = qw(WWW::Scraper::ISBN::Driver);

###########################################################################
#Interface Functions                                                      #
###########################################################################

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the Ylib 
server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn
  ean
  title
  author
  book_link
  image_link
  pubdate
  publisher
  price_list
  price_sell

The book_link and image_link refer back to the Ylib website. 

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
	$self->found(0);
	$self->book(undef);

	my $url = sprintf(QUERY, $isbn);
	my $mechanize = WWW::Mechanize->new();
	$mechanize->get($url);
	return undef unless($mechanize->success());

	# The Search Results page
	my $template = <<END;
�ѦW[% ... %]<A HREF='[% book %]'>
END

	my $extract = Template::Extract->new;
	my $data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWYlib result page.")
		unless(defined $data);

	my $book = $data->{book};
	$mechanize->get($book);

	$template = <<END;
<!-- ���y�ԲӸ��  -->[% ... %]
<font color="#333333"><b>[% title %]</b>[% ... %]
<!--���y�ʭ� -->[% ... %]
<IMG SRC="[% image_link %]" [% ... %]
<!-- ���y�ԲӸ�� -->[% ... %]
<A HREF="[% ... %]">[% author %]</A> ��[% ... %]
�쪩�G[% pubdate %]�E �X���G[% publisher %]<BR>[% ... %]
���ơG[% pages %]��[% ... %]
ISBN�G[% isbn %]    �D EAN�G[% ean %]</p>[% ... %]
�w���G[% price_list %]��[% ... %]
�u�f���G[% ... %]<B>[% price_sell %]</B>
END

	$data = $extract->extract($template, $mechanize->content());

	return $self->handler("Could not extract data from TWYlib result page.")
		unless(defined $data);

	$data->{ean} =~ s/\s+$//;
	$data->{author} =~ s/\/��//;
	$data->{pubdate} =~ s/\s+$//;
	$data->{publisher} =~ s/\s+$//;
	$data->{price_sell} =~ s/^\s+//;

	my $bk = {
		'isbn'		=> $data->{isbn},
		'ean'		=> $data->{ean},
		'title'		=> $data->{title},
		'author'	=> $data->{author},
		'book_link'	=> "http://www.ylib.com/search/".$book,
		'image_link'	=> "http://www.ylib.com".$data->{image_link},
		'pubdate'	=> $data->{pubdate},
		'publisher'	=> $data->{publisher},
		'price_list'	=> $data->{price_list},
		'price_sell'	=> $data->{price_sell},
	};

	$self->book($bk);
	$self->found(1);
	return $self->book;
}

1;
__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>,
L<Template::Extract>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 AUTHOR

Ying-Chieh Liao E<lt>ijliao@csie.nctu.edu.twE<gt>

=head1 COPYRIGHT

Copyright (C) 2005 Ying-Chieh Liao E<lt>ijliao@csie.nctu.edu.twE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
