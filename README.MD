Mail::SpamAssassin::Plugin::Esp

SpamAssassin plugin for Invaluement.com Service Provider DNSBLs ("SPBL"), 
Sendinblue and MailUp esp. 

The plugin doesn't download the data feed, the txt file should be downloaded using
"curl -z" or "wget -N" that only downloads the file when the server versions are newer.

Sample rule to enable the plugin: 

loadplugin Mail::SpamAssassin::Plugin::Esp Esp.pm

ifplugin Mail::SpamAssassin::Plugin::Esp

  sendgrid_feed /etc/mail/spamassassin/sendgrid-id-dnsbl.txt
  sendgrid_domains_feed /etc/mail/spamassassin/sendgrid-envelopefromdomain-dnsbl.txt

  header          SPBL_SENDGRID           eval:esp_sendgrid_check()
  describe        SPBL_SENDGRID           Message from Sendgrid abused account

endif
