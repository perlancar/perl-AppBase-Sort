package AppBase::Sort;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

$SPEC{sort_appbase} = {
    v => 1.1,
    summary => 'A base for sort-like CLI utilities',
    description => <<'MARKDOWN',

This routine provides a base for Unix sort-like CLI utilities. It accepts
coderef as source of lines, which in the actual utilities can be from
stdin/files or other sources. It provides common options like `-i`, `-r`, and so
on.

Examples of CLI utilities that are based on this: <prog:sort-by-example> (which
is included in the `AppBase-Sort` distribution).

Why? For sorting lines from files or stdin and "standard" sorting criteria, this
utility is no match for the standard Unix `sort` (or its many alternatives). But
`AppBase::Sort` is a quick way to create sort-like utilities that sort
lines from alternative sources and/or using custom sort criteria.

MARKDOWN
    args => {
        ignore_case => {
            summary => 'If set to true, will search case-insensitively',
            schema => 'bool*',
            cmdline_aliases => {i=>{}},
            #tags => ['category:'],
        },
        reverse => {
            summary => 'Reverse sort order',
            schema => 'bool*',
            cmdline_aliases => {r=>{}},
            #tags => ['category:'],
        },
        _source => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to produce *chomped* lines of text to sort. Required.

Will be called with these arguments:

    ()

Should return the next line or undef if the source is exhausted.

MARKDOWN
        },
        _sortgen => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to generate sorting routine. Required.

Will be called with these arguments:

    ($args)

Should return the following:

    ($sort, $handle_ci_and_reverse)

where `$sort` is the sort routine which in turn will be called during sort with:

    ($a, $b)

and `$handle_ci_and_reverse` can be set to true if the sorting routine already
observes the `--ignore-case` (`-i`) and `--reverse` (`-r`). Otherwise,
AppBase::Sort will handle the case conversion and reversing.

MARKDOWN
        },
    },
};
sub sort_appbase {
    my %args = @_;

    my $opt_ci      = $args{ignore_case};
    my $opt_reverse = $args{reverse};

    my $source = $args{_source};
    my @lines;
    while (defined(my $line = $source->())) { push @lines, $line }

    my ($sort, $handle_ci_and_reverse) = $args{_sortgen}->(\%args);

    if ($handle_ci_and_reverse) {
        @lines = sort { $sort->($a, $b) } @lines;
    } else {
        if ($opt_ci) {
            if ($opt_reverse) {
                @lines = sort { $sort->(lc($b), lc($a)) } @lines;
            } else {
                @lines = sort { $sort->(lc($a), lc($b)) } @lines;
            }
        } else {
            if ($opt_reverse) {
                @lines = sort { $sort->($b, $a) } @lines;
            } else {
                @lines = sort { $sort->($a, $b) } @lines;
            }
        }
    }

    return [
        200,
        "OK",
        \@lines,
    ];
}

1;
# ABSTRACT:


=head1 ENVIRONMENT


=head1 SEE ALSO

L<App::subsort>
