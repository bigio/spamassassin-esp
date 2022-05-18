#!/usr/bin/perl

use lib '.'; use lib 't';

use Test::More;
plan tests => 4;

sub tstprefs {
  my $rules = shift;
  open(OUT, '>', 't/rules/esp.cf') or die("Cannot write to rules directory: $!");
  print OUT $rules;
  close OUT;
}

sub tstcleanup {
  unlink('t/rules/esp.cf');
}

my $sarun = qx{which spamassassin 2>&1};

tstprefs("
  loadplugin Mail::SpamAssassin::Plugin::Esp ../../Esp.pm

  fordem_feed t/data/4dem.txt
  header   FORDEM_ID   eval:esp_4dem_check()
  describe FORDEM_ID   Check 4Dem id

  mailchimp_feed t/data/mailchimp.txt
  header   MAILCHIMP_ID   eval:esp_mailchimp_check()
  describe MAILCHIMP_ID   Check Mailchimp id

  sendgrid_feed t/data/sendgrid_id.txt
  header   SENDGRID_ID   eval:esp_sendgrid_check_id()
  describe SENDGRID_ID   Check Sendgrid id

  sendgrid_domains_feed t/data/sendgrid_dom.txt
  header   SENDGRID_DOM eval:esp_sendgrid_check_domain()
  describe SENDGRID_DOM Check Sendgrid domains
");

chomp($sarun);
my $test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/4dem.eml);
like($test, "/FORDEM_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/mailchimp.eml);
like($test, "/MAILCHIMP_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/sendgrid_id.eml);
like($test, "/SENDGRID_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/sendgrid_dom.eml);
like($test, "/SENDGRID_DOM/");

tstcleanup();
