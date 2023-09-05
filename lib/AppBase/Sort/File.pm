package AppBase::Sort::File;

use strict;
use warnings;
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

our %argspecs_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*'],
        cmdline_aliases => {f=>{}},
        pos => 1,
        slurpy => 1,
    },
    recursive => {
        summary => 'Read all files under each directory, recursively, following symbolic links only if they are on the command line',
        schema => 'true*',
        cmdline_aliases => {R => {}},
    },
    dereference_recursive => {
        summary => 'Read all files under each directory, recursively, following all symbolic links, unlike -r',
        schema => 'true*',
        cmdline_aliases => {R => {}},
    },
);

sub _find_files {
    my ($dir, $ary, $follow) = @_;

    require File::Find;
    File::Find::find({
        follow => $follow,
        wanted => sub {
            if (-f $_) {
                no warnings 'once';
                my $path = "$File::Find::dir/$_";
                push @$ary, $path;
            }
        },
    }, $dir);
}

# will set $args->{_source}
sub set_source_arg {
    my $args = shift;

    my @files = @{ $args->{files} // [] };

    if ($args->{recursive} || $args->{dereference_recursive}) {
        my $i = -1;
        while (++$i < @files) {
            if (-d $files[$i]) {
                my $more_files = [];
                my $follow = $args->{dereference_recursive} ? 1:0;
                _find_files($files[$i], $more_files, $follow);
                splice @files, $i, 1, @$more_files;
                $i += @$more_files-1;
            }
        }
    }

    my ($fh, $file);

    $args->{_source} = sub {
      READ_LINE:
        {
            if (!defined $fh) {
                return unless @files;
                $file = shift @files;
                log_trace "Opening file '$file' ...";
                open $fh, "<", $file or do {
                    warn "Can't open '$file': $!, skipped\n";
                    undef $fh;
                };
                redo READ_LINE;
            }

            my $line = <$fh>;
            if (defined $line) {
                return $line;
            } else {
                undef $fh;
                redo READ_LINE;
            }
        }
    };
}

1;
# ABSTRACT: Resources for AppBase::Sort-based scripts that use file sources

=head1 FUNCTIONS

=head2 set_source_arg
