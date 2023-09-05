package App::sort_by_example;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Sort;
use AppBase::Sort::File ();
use Perinci::Sub::Util qw(gen_modified_sub);

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'sort_by_example',
    base_name   => 'AppBase::Sort::sort_appbase',
    summary     => 'Sort lines of text by example',
    description => <<'_',

This is a sort-like utility that is based on <pm:AppBase::Sort>, mainly for
demoing and testing the module.

_
    add_args    => {
        %AppBase::Sort::File::argspecs_files,
        examples => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'example',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    modify_args => {
        files => sub {
            my $argspec = shift;
            delete $argspec->{pos};
            delete $argspec->{slurpy};
        },
    },
    modify_meta => sub {
        my $meta = shift;
        $meta->{links} //= [];
        push @{ $meta->{links} }, {url=>'pm:Sort::ByExample'};
    },
    output_code => sub {
        my %args = @_;
        my $examples = delete $args{examples};

        AppBase::Sort::File::set_source_arg(\%args);
        $args{_sortgen} = sub {
            my $args = shift;
            require Sort::ByExample;
            my $cmp = Sort::ByExample->cmp($examples);
            my $sort = sub {
                my ($a, $b) = @_;
                chomp($a); chomp($b);
                $cmp->($a, $b);
            };
            return ($sort);
        };
        AppBase::Sort::sort_appbase(%args);
    },
);

1;
# ABSTRACT:
