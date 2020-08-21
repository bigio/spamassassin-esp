install:
	pod2man Esp.pm > "man/man3p/Mail::SpamAssassin::Plugin::Esp.3p"
	perl -cw Esp.pm && podlint Esp.pm && sudo cp Esp.* /etc/mail/spamassassin/
