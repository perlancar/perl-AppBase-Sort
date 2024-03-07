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
        _gen_keygen => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to generate a key-generating (keygen) routine (routine that accepts a value
and converts it to another value (key) that can be compared using `cmp` or
`<=>`.

Either `_gen_comparer`, `_gen_keygen`, or `_gen_sorter` argument is required.

Will be called with these arguments:

    ($args)

Should return the following:

    ($keygen, $is_numeric)

where `$keygen` is the keygen routine and `$is_numeric` is a boolean value which
dictates whether key comparison will be done numerically (using `<=>`) or
asciibetically (using `cmp`).

MARKDOWN
        },
        _gen_sorter => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to generate a sorter routine (routine that accepts a list of values and
return the sorted values, like Perl's builtin `sort`.

Either `_gen_comparer`, `_gen_keygen`, or `_gen_sorter` argument is required.

Will be called with these arguments:

    ($args)

Should return the following:

    $sorter

where `$sorter` is the comparer routine which in turn will be called during sort
with:

    (@lines)

MARKDOWN
        },
        _gen_comparer => {
            schema => 'code*',
            tags => ['hidden'],
            description => <<'MARKDOWN',

Code to generate a comparer routine (routine that accepts two values and return
-1/0/1, like Perl's builtin `cmp` or `<=>`.

Either `_gen_comparer`, `_gen_keygen`, or `_gen_sorter` argument is required.

Will be called with these arguments:

    ($args)

Should return the following:

    $cmp

where `$cmp` is the comparer routine which in turn will be called during sort
with:

    ($a, $b)

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

    if ($args{_gen_comparer}) {
        my $cmp = $args{_gen_comparer}->(\%args);
        if ($opt_ci) {
            if ($opt_reverse) {
                @lines = sort { $cmp->(lc($b), lc($a)) } @lines;
            } else {
                @lines = sort { $cmp->(lc($a), lc($b)) } @lines;
            }
        } else {
            if ($opt_reverse) {
                @lines = sort { $cmp->($b, $a) } @lines;
            } else {
                @lines = sort { $cmp->($a, $b) } @lines;
            }
        }
    } elsif ($args{_gen_sorter}) {
        my $sorter = $args{_gen_sorter}->(\%args);
        @lines = $sorter->(@lines);
    } elsif ($args{_gen_keygen}) {
        my ($keygen, $is_numeric) = $args{_gen_keygen}->(\%args);
        require Sort::Key;
        if ($is_numeric) {
            if ($opt_reverse) {
                @lines = &Sort::Key::rnkeysort($keygen, @lines);
            } else {
                @lines = &Sort::Key::nkeysort ($keygen, @lines);
            }
        } else {
            if ($opt_reverse) {
                if ($opt_ci) {
                    @lines = &Sort::Key::rkeysort(sub { lc $keygen->($_[0]) }, @lines);
                } else {
                    @lines = &Sort::Key::rkeysort($keygen, @lines);
                }
            } else {
                if ($opt_ci) {
                    @lines = &Sort::Key::keysort (sub { lc $keygen->($_[0]) }, @lines);
                } else {
                    @lines = &Sort::Key::keysort ($keygen, @lines);
                }
            }
        }
    } else {
        die "Either _gen_comparer, _gen_sorter, or _gen_keygen must be specified";
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
