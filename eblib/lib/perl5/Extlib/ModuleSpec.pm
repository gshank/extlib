package Extlib::ModuleSpec;
use strict;
use warnings;
use Cwd;
use YAML::XS;
use IO::All;

=head1 NAME

Extlib::ModuleSpec

=head1 DESCRIPTION

Wrapper for YAML module specification file.

=head1 METHODS

=head2 new

=cut

sub new {
    my($class, $file) = @_;

    my $self = bless { file => $file }, $class;

    my $yaml < io($self->{file});
    my $config = Load $yaml;

    $self->{config} = $config;
    return $self;
}

sub config {
    my $self = shift;
    return $self->{config};
}

sub modules {
    my $self = shift;

    my $config = $self->config;
    my @modules =
        map  { $config->{$_}->{path} || $_ }
           keys  %{ $self->config };

    return @modules;
}

sub module_name_list {
    my $self = shift;
    my $config = $self->config;
    my @modules = keys %$config;
    return @modules;
}

sub modules_for_install {
    my $self = shift;

    my $config = $self->config;
    my @modules = keys %$config;
    return @modules;
}


sub pinned_unpinned_modules {
    my $self = shift;

    my $config = $self->config;
    my @pinned;
    my @unpinned;
    foreach my $module (  keys %{$config} ) {
        if ( $config->{$module}->{path} ) {
            push @pinned, $module->{path};
        }
        else {
            push @unpinned, $module;
        }
    }
    return (\@pinned, \@unpinned);
}

sub force_notforce_modules {
    my $self = shift;

    my $config = $self->config;
    my @force;
    my @notforce;
    foreach my $module (  keys %{$config} ) {
        my $path = $config->{$module}->{path};
        if ( $config->{$module}->{force} ) {
            push @force, $path || $module;
        }
        else {
            push @notforce, $path || $module;
        }
    }
    return (\@force, \@notforce);
}

sub needs_force {
    my ( $self, $module ) = @_;

    return 1 if $self->config->{$module}->{force};
    return 0;
}

sub is_pinned {
    my ( $self, $module ) = @_;
    return 1 if $self->config->{$module}->{path};
    return 0;
}

sub is_pinned_to {
    my ( $self, $module, $dist ) = @_;
    my $path = $self->config->{$module}->{path};
    return 0 unless $path;
    my ( undef, $pinned_dist, undef ) = $path =~ /^(.*\/)(.*)(\.tar.gz*)/;
    return 1 if $dist eq $pinned_dist;
    return 0;
}

sub notest {
    my ( $self, $module ) = @_;
    return 1 if $self->config->{$module}->{notest};
    return 0;
}

1;

