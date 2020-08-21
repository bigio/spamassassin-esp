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

TinyURL - checks ESP hacked accounts

=head1 SYNOPSIS

  loadplugin    Mail::SpamAssassin::Plugin::Esp

=head1 DESCRIPTION

This plugin checks emails coming from ESP hacked accounts.

=cut

package Mail::SpamAssassin::Plugin::Esp;

use strict;
use warnings;

use Errno qw(EBADF);
use Mail::SpamAssassin::Plugin;
use Mail::SpamAssassin::PerMsgStatus;

use vars qw(@ISA);
our @ISA = qw(Mail::SpamAssassin::Plugin);

my $VERSION = 0.1;

sub dbg { Mail::SpamAssassin::Plugin::dbg ("Esp: @_"); }

sub new {
  my $class = shift;
  my $mailsaobject = shift;

  $class = ref($class) || $class;
  my $self = $class->SUPER::new($mailsaobject);
  bless ($self, $class);

  $self->set_config($mailsaobject->{conf});
  $self->register_eval_rule('sendgrid_check',  $Mail::SpamAssassin::Conf::TYPE_HEAD_EVALS);

  return $self;
}

=head1 ADMINISTRATOR SETTINGS

=over 4

=item sendgrid_feed [...]

A file with all hacked Sendgrid accounts.
Data file can be downloaded from https://www.invaluement.com/spdata/sendgrid-id-dnsbl.txt.

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

  local *F;
  if ( defined($conf->{sendgrid_feed}) && ( -f $conf->{sendgrid_feed} ) ) {
    open(F, '<', $conf->{sendgrid_feed});
    for ($!=0; <F>; $!=0) {
        chomp;
        #lines that start with pound are comments
        next if(/^\s*\#/);
        $sendgrid_id = $_;
        if ( defined $sendgrid_id ) {
          push @{$self->{ESP}->{$sendgrid_id}}, $sendgrid_id;
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
  
  my $sg_eid = $pms->get("X-SG-EID", undef);
  return if not defined $sg_eid;
  
  my $rulename = $pms->get_current_eval_rule_name();
  my $envfrom = $pms->get("EnvelopeFrom:addr", undef);
  
  if($envfrom =~ /bounces\+(\d+)\-/) {
    $sendgrid_id = $1;
    # dbg("ENVFROM: $envfrom ID: $sendgrid_id");  
    if(defined $sendgrid_id) {
	  if ( exists $self->{ESP}->{$sendgrid_id} ) {
        dbg("HIT! $sendgrid_id customer id found in Sendgrid Invaluement feed");
        $pms->test_log("Sendgrid id: $sendgrid_id");
        $pms->got_hit($rulename, "", ruletype => 'eval');
        return 1;
      }	
	}
  } 
}

1;
