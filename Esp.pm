# <@LICENSE>
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>

# Author:  Giovanni Bechis <gbechis@apache.org>

=head1 NAME

Esp - checks ESP abused accounts

=head1 SYNOPSIS

  loadplugin    Mail::SpamAssassin::Plugin::Esp

=head1 DESCRIPTION

This plugin checks emails coming from ESP abused accounts.

=cut

package Mail::SpamAssassin::Plugin::Esp;

use strict;
use warnings;

use Errno qw(EBADF);
use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::PerMsgStatus;

use vars qw(@ISA);
our @ISA = qw(Mail::SpamAssassin::Plugin);

my $VERSION = 0.2;

sub dbg { Mail::SpamAssassin::Plugin::dbg ("Esp: @_"); }

sub new {
  my $class = shift;
  my $mailsaobject = shift;

  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsaobject);
  bless ($self, $class);

  $self->set_config($mailsaobject->{conf});
  $self->register_eval_rule('sendgrid_check',  $Mail::SpamAssassin::Conf::TYPE_HEAD_EVALS);
  $self->register_eval_rule('sendinblue_check',  $Mail::SpamAssassin::Conf::TYPE_HEAD_EVALS);
  $self->register_eval_rule('voxmail_check',  $Mail::SpamAssassin::Conf::TYPE_HEAD_EVALS);

  return $self;
}

=head1 ADMINISTRATOR SETTINGS

=over 4

=item sendgrid_feed [...]

A file with all abused Sendgrid accounts.
More info at https://www.invaluement.com/serviceproviderdnsbl/.
Data file can be downloaded from https://www.invaluement.com/spdata/sendgrid-id-dnsbl.txt.

=item sendgrid_domains_feed [...]

A file with abused domains managed by Sendgrid.
More info at https://www.invaluement.com/serviceproviderdnsbl/.
Data file can be downloaded from https://www.invaluement.com/spdata/sendgrid-envelopefromdomain-dnsbl.txt.

=item sendinblue_feed [...]

A file with abused Sendinblue accounts.

=item voxmail_domains_feed [...]

A file with abused Voxmail domains, domains are usually accountname.voxmail.it

=back

=cut

sub set_config {
  my($self, $conf) = @_;
  my @cmds = ();

  push(@cmds, {
    setting => 'sendgrid_feed',
    is_admin => 1,
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
    }
  );
  push(@cmds, {
    setting => 'sendgrid_domains_feed',
    is_admin => 1,
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
    }
  );
  push(@cmds, {
    setting => 'sendinblue_feed',
    is_admin => 1,
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
    }
  );
  push(@cmds, {
    setting => 'voxmail_domains_feed',
    is_admin => 1,
    type => $Mail::SpamAssassin::Conf::CONF_TYPE_STRING,
    }
  );
  $conf->{parser}->register_commands(\@cmds);
}

sub finish_parsing_end {
  my ($self, $opts) = @_;
  $self->_read_configfile($self);
}

sub _read_configfile {
  my ($self) = @_;
  my $conf = $self->{main}->{registryboundaries}->{conf};
  my $sendgrid_id;
  my $sendgrid_domain;
  my $sendinblue_id;
  my $voxmail_domain;

  local *F;
  if ( defined($conf->{sendgrid_feed}) && ( -f $conf->{sendgrid_feed} ) ) {
    open(F, '<', $conf->{sendgrid_feed});
    for ($!=0; <F>; $!=0) {
      chomp;
      #lines that start with pound are comments
      next if(/^\s*\#/);
      $sendgrid_id = $_;
      if ( defined $sendgrid_id ) {
        push @{$self->{ESP}->{SENDGRID}->{$sendgrid_id}}, $sendgrid_id;
      }
    }

    defined $_ || $!==0  or
      $!==EBADF ? dbg("ESP: error reading config file: $!")
                : die "error reading config file: $!";
    close(F) or die "error closing config file: $!";
  }

  if ( defined($conf->{sendgrid_domains_feed}) && ( -f $conf->{sendgrid_domains_feed} ) ) {
    open(F, '<', $conf->{sendgrid_domains_feed});
    for ($!=0; <F>; $!=0) {
      chomp;
      #lines that start with pound are comments
      next if(/^\s*\#/);
      $sendgrid_domain = $_;
      if ( defined $sendgrid_domain ) {
        push @{$self->{ESP}->{SENDGRID_DOMAIN}->{$sendgrid_domain}}, $sendgrid_domain;
      }
    }

    defined $_ || $!==0  or
      $!==EBADF ? dbg("ESP: error reading config file: $!")
                : die "error reading config file: $!";
    close(F) or die "error closing config file: $!";
  }

  if ( defined($conf->{sendinblue_feed}) && ( -f $conf->{sendinblue_feed} ) ) {
    open(F, '<', $conf->{sendinblue_feed});
    for ($!=0; <F>; $!=0) {
      chomp;
      #lines that start with pound are comments
      next if(/^\s*\#/);
      $sendinblue_id = $_;
      if ( ( defined $sendinblue_id ) and ($sendinblue_id =~ /[0-9]+/) ) {
        push @{$self->{ESP}->{SENDINBLUE}->{$sendinblue_id}}, $sendinblue_id;
      }
    }

    defined $_ || $!==0  or
      $!==EBADF ? dbg("ESP: error reading config file: $!")
                : die "error reading config file: $!";
    close(F) or die "error closing config file: $!";
  }

  if ( defined($conf->{voxmail_domains_feed}) && ( -f $conf->{voxmail_domains_feed} ) ) {
    open(F, '<', $conf->{voxmail_domains_feed});
    for ($!=0; <F>; $!=0) {
      chomp;
      #lines that start with pound are comments
      next if(/^\s*\#/);
      $voxmail_domain = $_;
      if ( defined $voxmail_domain ) {
        push @{$self->{ESP}->{VOXMAIL_DOMAIN}->{$voxmail_domain}}, $voxmail_domain;
      }
    }

    defined $_ || $!==0  or
      $!==EBADF ? dbg("ESP: error reading config file: $!")
                : die "error reading config file: $!";
    close(F) or die "error closing config file: $!";
  }

}

sub sendgrid_check {
  my ($self, $pms) = @_;
  my $sendgrid_id;
  my $sendgrid_domain;

  # All Sendgrid emails have the X-SG-EID header
  my $sg_eid = $pms->get("X-SG-EID", undef);
  return if not defined $sg_eid;

  my $rulename = $pms->get_current_eval_rule_name();
  my $envfrom = $pms->get("EnvelopeFrom:addr", undef);

  # Find the customer id from the Return-Path
  if($envfrom =~ /bounces\+(\d+)\-/) {
    $sendgrid_id = $1;
    # dbg("ENVFROM: $envfrom ID: $sendgrid_id");
    if(defined $sendgrid_id) {
      if ( exists $self->{ESP}->{SENDGRID}->{$sendgrid_id} ) {
        dbg("HIT! $sendgrid_id customer id found in Sendgrid Invaluement feed");
        $pms->test_log("Sendgrid id: $sendgrid_id");
        $pms->got_hit($rulename, "", ruletype => 'eval');
        return 1;
      }
    }
  }

  # Find the domain from the Return-Path
  if($envfrom =~ /\@(\w+\.)?([\w\.]+)\>?$/) {
    $sendgrid_domain = $2;
    # dbg("ENVFROM: $envfrom domain: $sendgrid_domain");
    if(defined $sendgrid_domain) {
      if ( exists $self->{ESP}->{SENDGRID_DOMAIN}->{$sendgrid_domain} ) {
        dbg("HIT! $sendgrid_domain domain found in Sendgrid Invaluement feed");
        $pms->test_log("Sendgrid domain: $sendgrid_domain");
        $pms->got_hit($rulename, "", ruletype => 'eval');
        return 1;
      }
    }
  }
}

sub sendinblue_check {
  my ($self, $pms) = @_;
  my $sendinblue_id;

  my $rulename = $pms->get_current_eval_rule_name();

  # All Sendinblue emails have the X-Mailer header set to Sendinblue
  my $xmailer = $pms->get("X-Mailer", undef);
  if((not defined $xmailer) or ($xmailer !~ /Sendinblue/)) {
    return;
  }

  $sendinblue_id = $pms->get("X-Mailin-Client", undef);
  chomp($sendinblue_id);
  if(defined $sendinblue_id) {
    if ( exists $self->{ESP}->{SENDINBLUE}->{$sendinblue_id} ) {
      dbg("HIT! $sendinblue_id ID found in Sendinblue feed");
      $pms->test_log("Sendinblue id: $sendinblue_id");
      $pms->got_hit($rulename, "", ruletype => 'eval');
      return 1;
    }
  }

}

sub voxmail_check {
  my ($self, $pms) = @_;
  my $voxmail_domain;

  my $rulename = $pms->get_current_eval_rule_name();

  # All Voxmail emails have the List-Id header that must match
  $voxmail_domain = $pms->get("List-Id", undef);
  return if not defined $voxmail_domain;
  $voxmail_domain =~ s/(^\<|\>$)//g;
  chomp($voxmail_domain);
  if(defined $voxmail_domain) {
    if ( exists $self->{ESP}->{VOXMAIL_DOMAIN}->{$voxmail_domain} ) {
      dbg("HIT! $voxmail_domain domain found in Voxmail feed");
      $pms->test_log("Voxmail domain: $voxmail_domain");
      $pms->got_hit($rulename, "", ruletype => 'eval');
      return 1;
    }
  }

}

1;
