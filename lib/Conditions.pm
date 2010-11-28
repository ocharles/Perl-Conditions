package Conditions;
use strict;
use warnings FATAL => 'all';

use Continuation::Escape;
use Package::Stash;
use Try::Tiny;

use Sub::Exporter -setup => {
    exports => [qw( dangerous with_handlers bind_continue handle restart_case )],
    groups => {
        default => [qw( dangerous with_handlers bind_continue handle restart_case )]
    }
};

our %handlers;
our %cases;

sub with_handlers (&@) {
    my ($code, %handles) = @_;
    %handlers = %handles; # XXX Should push onto each handler as a queue
    $code->();
}

sub dangerous {
    my ($name, $body) = @_;
    my $caller = caller(0);
    my $stash = Package::Stash->new($caller);
    my $code = sub {
        my @args = @_;
        call_cc {
            my $cc = shift;
            try {
                $cc->($body->(@args));
            }
            catch {
                my $err = $_;
                for my $handles (keys %handlers) {
                    if($err->isa($handles)) {
                        $cc->( $handlers{$handles}->($err) );
                    }
                }
                die $err;
            }
        }
    };

    $stash->add_package_symbol("&$name" => $code);
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
