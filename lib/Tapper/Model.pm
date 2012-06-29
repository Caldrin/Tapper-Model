package Tapper::Model;
# ABSTRACT: Tapper - Context sensitive connected DBIC schema

use warnings;
use strict;

use 5.010;

# avoid these warnings
#   Subroutine initialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 70.
#   Subroutine uninitialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 88.
#   Subroutine reinitialize redefined at /2home/ss5/perl510/lib/site_perl/5.10.0/Class/C3.pm line 101.
# by forcing correct load order.

use Class::C3;
use MRO::Compat;

use Memoize;
use Tapper::Config;
use parent 'Exporter';

our @EXPORT_OK = qw(model get_hardware_overview);

=head2 model

Returns a connected schema, depending on the environment (live,
development, test).

@param 1. $schema_basename - optional, default is "Tests", meaning the
          Schema "Tapper::Schema::Tests"

@return $schema

=cut

memoize('model');
sub model
{
        my ($schema_basename) = @_;

        $schema_basename ||= 'TestrunDB';

        my $schema_class = "Tapper::Schema::$schema_basename";

        # lazy load class
        eval "use $schema_class"; ## no critic (ProhibitStringyEval)
        if ($@) {
                print STDERR $@;
                return;
        }
        my $model =  $schema_class->connect(Tapper::Config->subconfig->{database}{$schema_basename}{dsn},
                                            Tapper::Config->subconfig->{database}{$schema_basename}{username},
                                            Tapper::Config->subconfig->{database}{$schema_basename}{password});
        return $model;
}

=head2 get_or_create_user

Search a user based on login name. Create a user with this login name if
not found.

@param string - login name

@return success - id (primary key of user table)
@return error   - undef

=cut

sub get_or_create_user {
        my ($login) = @_;
        my $user_search = model('TestrunDB')->resultset('User')->search({ login => $login });
        my $user_id;
        if (not $user_search->count) {
                my $user = model('TestrunDB')->resultset('User')->new({ login => $login });
                $user->insert;
                return $user->id;
        } else {
                my $user = $user_search->first; # at least one user
                return $user->id;

        }
        return;
}

=head2 free_hosts_with_features

Return list of free hosts with their features and queues.

=cut


=head2 get_hardware_overview

Returns an overview of a given machine revision.

@param int - machine lid

@return success - hash ref
@return error   - undef

=cut

use Carp;

sub get_hardware_overview
{
        my ($host_id) = @_;

        my $host = model('TestrunDB')->resultset('Host')->find($host_id);
        return qq(Host with id '$host_id' not found) unless $host;

        my %all_features;

        foreach my $feature ($host->features) {
                $all_features{$feature->entry} = $feature->value;
        }
        return \%all_features;

}

=head1 SYNOPSIS

    use Tapper::Model 'model';
    my $testrun = model('TestrunDB')->schema('Testrun')->find(12);
    my $testrun = model('ReportsDB')->schema('Report')->find(7343);

=cut

1; # End of Tapper::Model
