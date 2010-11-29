use strict;
use warnings FATAL => 'all';

package MalformedLogEntry;
use Moose;
extends 'Throwable::Error';

package MyApp;
use Conditions;
use Devel::Dwarn;

sub parse_log_entry {
    my $entry = shift or die "Must specify entry";
    if($entry =~ /(\d+-\d+-\d+) (\d+:\d+:\d+) (\w+) (.*)/) {
        return ($1, $2, $3, $4);
    }
    else {
        restart_case {
            MalformedLogEntry->new($entry),
        }
        bind_continue(use_value => sub { return shift }),
        bind_continue(log => sub {
            warn "*** Invalid entry: $entry";
            return undef;
        });
    }
};

with_handlers {
    Dwarn [ parse_log_entry('2010-01-01 10:09:5 WARN Test') ];
    Dwarn [ parse_log_entry('Oh no bad data') ];
    Dwarn [ parse_log_entry('2010-10-12 12:11:03 INFO Notice it still carries on!') ];
}
handle(MalformedLogEntry => cont { 'log' });
