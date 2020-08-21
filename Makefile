install:
	perl -cw Esp.pm && podlint Esp.pm && sudo cp Esp.* /etc/mail/spamassassin/
