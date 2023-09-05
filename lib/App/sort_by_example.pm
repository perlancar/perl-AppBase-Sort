package App::abgrep;

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
        },
    },
    modify_args => sub {
        my $args = shift;
        delete $args->{files}{pos};
        delete $args->{files}{slurpy};
    },
    output_code => sub {
        my %args = @_;
        my $examples = delete $args{examples};

        AppBase::Sort::File::set_source_arg(\%args);
        $args{_sortgen} = sub {
            my $args = shift;
            require Sort::ByExample;
            my $sort = Sort::ByExample::sbe($examples);
            return ($sort);
        };
        AppBase::Sort::sort_appbase(%args);
    },
);

1;
# ABSTRACT:
