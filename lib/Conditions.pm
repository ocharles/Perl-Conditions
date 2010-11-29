package Conditions;
use strict;
use warnings FATAL => 'all';

use Scope::Upper qw( unwind :words );
use Package::Stash;
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [qw( with_handlers bind_continue handle restart_case )],
    groups => {
        default => [qw( with_handlers bind_continue handle restart_case )]
    }
};

our %handlers;
our %cases;

BEGIN {
    no strict 'refs';
    *{'CORE::GLOBAL::die'} = sub {
        my $err = shift;
        for my $handles (keys %handlers) {
            if($err->isa($handles)) {
                unwind $handlers{$handles}->($err) => UP UP HERE;
            }
        }
    };
};

sub with_handlers (&@) {
    my ($code, %handles) = @_;
    %handlers = %handles; # XXX Should push onto each handler as a queue
    $code->();
}

sub continue_with (&) {
    my @vals = @_;
    return sub { @vals }
}

sub restart_case (&@) {
    my $error = shift->();
    %cases = @_;
    $error->throw;
}

sub restart {
    if (ref($_[0]) eq 'CODE') {
        return shift;
    }
    else {
        my ($cont, @args) = @_;
        return sub {
            my $restart = $cases{$cont};
            $restart->(@args);
        }
    }
}

# Nom. Sugarz
sub handle {
    my ($handles, $code) = @_;
    return $handles => $code;
}

sub bind_continue {
    my ($restart, $code) = @_;
    return $restart => $code;
}
1;
