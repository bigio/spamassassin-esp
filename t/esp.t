#!/usr/bin/perl

use lib '.'; use lib 't';

use Test::More;
plan tests => 2;

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

  sendgrid_feed t/data/sendgrid_id.txt
  header   SENDGRID_ID   eval:esp_sendgrid_check_id()
  describe SENDGRID_ID   Check Sendgrid id

  mailchimp_feed t/data/mailchimp.txt
  header   MAILCHIMP_ID   eval:esp_mailchimp_check()
  describe MAILCHIMP_ID   Check Mailchimp id
");

chomp($sarun);
my $test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/sendgrid_id.eml);
like($test, "/SENDGRID_ID/");

$test = qx($sarun -L -t --siteconfigpath=t/rules < t/data/mailchimp.eml);
like($test, "/MAILCHIMP_ID/");

tstcleanup();
