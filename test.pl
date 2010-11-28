use strict;
use warnings FATAL => 'all';

package MalformedLogEntry;
use Moose;
extends 'Throwable::Error';

package MyApp;
use Conditions;
use Devel::Dwarn;

# XXX Can we make this `sub parse_log_entry` ?
dangerous parse_log_entry => sub {
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
    print parse_log_entry('Oh no bad data'), "\n";
}
handle(MalformedLogEntry => sub {
    return 'I can use my own handler';
});
