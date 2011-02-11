package Conditions;
use strict;
use warnings FATAL => 'all';

use Scope::Upper qw( unwind :words );
use Package::Stash;
use Scalar::Util 'blessed';
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [qw( restart with_handlers bind_continue handle restart_case )],
    groups => {
        default => [qw( restart with_handlers bind_continue handle restart_case )]
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
                my $handler = $handlers{$handles};
                $handler = ${$handler}
                    if blessed($handler) && $handler->isa('Try::Tiny::Catch');
                unwind $handler->($err) => UP UP UP HERE;
                return "Well, it should never get here...";
            }
        }
    };
};

sub with_handlers (&@) {
    my ($code, %handles) = @_;
    %handlers = %handles; # XXX Should push onto each handler as a queue
    $code->();
    %handlers = ();
}

sub continue_with (&) {
    my @vals = @_;
    return sub { @vals }
}

sub restart {
    my $name = shift;
    my @args = @_;
    return sub {
        $cases{$name}->(@args)
    };
}

sub restart_case (&@) {
    my $error = shift->();
    %cases = @_;
    $error->throw;
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
