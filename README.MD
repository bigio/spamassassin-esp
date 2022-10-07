[![CI for Apache SpamAssassin Esp plugin](https://github.com/bigio/spamassassin-esp/actions/workflows/main.yml/badge.svg)](https://github.com/bigio/spamassassin-esp/actions/workflows/main.yml) [![GitHub license](https://img.shields.io/github/license/bigio/spamassassin-esp)](https://github.com/bigio/spamassassin-esp/blob/master/LICENSE) [![GitHub release](https://img.shields.io/github/release/bigio/spamassassin-esp.svg)](https://GitHub.com/bigio/spamassassin-esp/releases/)

Mail::SpamAssassin::Plugin::Esp

SpamAssassin plugin for Sendgrid, Sendinblue, MailUp, Maildome and Mailchimp esp. 

The plugin doesn't download the data feed, the txt file should be created by the user.  

Sample rule to enable the plugin (add the score you prefer to the rule):  

	loadplugin Mail::SpamAssassin::Plugin::Esp Esp.pm  

	ifplugin Mail::SpamAssassin::Plugin::Esp  

		sendgrid_feed /etc/mail/spamassassin/sendgrid-id-dnsbl.txt  
		sendgrid_domains_feed /etc/mail/spamassassin/sendgrid-envelopefromdomain-dnsbl.txt  

		header          SPBL_SENDGRID           eval:esp_sendgrid_check()  
		describe        SPBL_SENDGRID           Message from Sendgrid abused account 	

	endif
