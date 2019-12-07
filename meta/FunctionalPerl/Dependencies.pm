#
# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Dependencies

=head1 SYNOPSIS

    use FunctionalPerl::Dependencies 'module_needs';

    #  if (my @needs= module_needs $module) {
    #      skip "- don't have @needs", 1;
    #  }

=head1 DESCRIPTION


=cut


package FunctionalPerl::Dependencies;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(have_module module_needs);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

# ------------------------------------------------------------------
# Non-core dependencies of modules to decide whether to skip testing
# them.  XX: keep these updated!

our %dependencies=
  (
   # Don't specify Sub::Call::Tail (if meta/tail-expand can expand it)!

   'Chj::Serialize'=> ['FP::Repl::Dependencies', 'B::Deparse'],
   'FP::Docstring'=> ['B::Deparse'],
   'FP::BigInt'=> ['Math::BigInt'],
   'FP::autobox'=> ['autobox'],
   'FP::Text::CSV'=> ['Text::CSV'],
   'FP::url_'=> ['URI'],
   'Chj::CPAN::ModulePODUrl'=> ['LWP::UserAgent'],
   'FP::DBI'=> ['DBI'],
   'FunctionalPerl::Htmlgen::UriUtil'=> [
       'Function::Parameters',
       'URI'
   ],
   'FunctionalPerl::Htmlgen::PathUtil'=> [
       'Function::Parameters',
       'File::Spec',
   ],
   'FunctionalPerl::Htmlgen::PathTranslate'=> [
       'Function::Parameters',
       'FunctionalPerl::Htmlgen::PathUtil'
   ],
   'FunctionalPerl::Htmlgen::Mediawiki'=> [
       'Function::Parameters',
       'Encode',
       'URI',
   ],
   'FunctionalPerl::Htmlgen::MarkdownPlus'=> [
       'Function::Parameters',
       'FunctionalPerl::Htmlgen::Htmlparse',
       'Text::Markdown',
       'FunctionalPerl::Htmlgen::Mediawiki'
   ],
   'FunctionalPerl::Htmlgen::Linking'=> [
       'Function::Parameters',
       'FunctionalPerl::Htmlgen::PathUtil',
       'Chj::CPAN::ModulePODUrl',
       'FunctionalPerl::Htmlgen::UriUtil',
   ],
   'FunctionalPerl::Htmlgen::Htmlparse'=> [
       'Function::Parameters',
       'HTML::TreeBuilder',
   ],
   'Chj::HTTP::Daemon'=> [
       'HTTP::Request',
   ],
   'FunctionalPerl::Htmlgen::PerlTidy'=> [
       'Function::Parameters',
       'Perl::Tidy',
   ],
   (map { $_ => [ 'Function::Parameters' ] }
    qw(
         FP::AST::Perl
         FunctionalPerl::Htmlgen::Toc
         FunctionalPerl::Htmlgen::PXMLMapper
         FunctionalPerl::Htmlgen::FileUtil
         FunctionalPerl::Htmlgen::default_config
         FunctionalPerl::Htmlgen::Cost
         FunctionalPerl::Htmlgen::Nav
         FunctionalPerl::Htmlgen::Sourcelang
    )),
   (map { $_ => ['FP::Repl::Dependencies'] }
    qw(
         FP::Repl::Dependencies
         FP::Repl::Repl
         FP::Repl::StackPlus
         FP::Repl::Trap
         FP::Repl::WithRepl
         FP::Repl
         FP::Trie::t
    )),
  );


# ------------------------------------------------------------------

my %have_module;
sub have_module {
    my ($modulename)=@_;
    return $have_module{$modulename}
      if exists $have_module{$modulename};
    $have_module{$modulename}= do {
        eval "require $modulename; 1" or 0
    }
}

sub module_needs {
    my ($modulename)=@_;
    if (my $ds= $dependencies{$modulename}) {
        grep {
            not have_module $_
        } sort @$ds
    } else {
        ()
    }
}

1
