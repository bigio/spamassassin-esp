#!/usr/bin/perl

use lib '.'; use lib 't';

use Test::More;
plan tests => 9;

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

  ecmessenger_feed t/data/ecmessenger.txt
  header   ECMESSENGER_ID eval:esp_ecmessenger_check()
  describe ECMESSENGER_ID Check Ec-Messenger id

  emlbest_feed t/data/emlbest.txt
  header   EMLBEST_ID eval:esp_emlbest_check()
  describe EMLBEST_ID Check Emlbest id

  mailchimp_feed t/data/mailchimp.txt
  header   MAILCHIMP_ID   eval:esp_mailchimp_check()
  describe MAILCHIMP_ID   Check Mailchimp id

  mdengine_feed t/data/mdengine.txt
  header   MDENGINE_ID   eval:esp_mdengine_check()
  describe MDENGINE_ID   Check MDengine id

  mdrctr_feed t/data/mdrctr.txt
  header   MDRCTR_ID   eval:esp_mdrctr_check()
  describe MDRCTR_ID   Check Mdrctr id

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

my $test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/ecmessenger.eml);
like($test, "/ECMESSENGER_ID/");

my $test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/emlbest.eml);
like($test, "/EMLBEST_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/mailchimp.eml);
like($test, "/MAILCHIMP_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/mdengine.eml);
unlike($test, "/MAILCHIMP_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/mdengine.eml);
like($test, "/MDENGINE_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/mdrctr.eml);
like($test, "/MDRCTR_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/sendgrid_id.eml);
like($test, "/SENDGRID_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/sendgrid_dom.eml);
like($test, "/SENDGRID_DOM/");

tstcleanup();
