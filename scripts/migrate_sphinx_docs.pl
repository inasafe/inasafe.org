#!/usr/bin/env perl
# SPDX-FileCopyrightText: Kartoza
# Bulk, best-effort RST -> Markdown converter for the inasafe-doc -> inasafe.org
# mkdocs migration. Pandoc was unavailable in the sandbox this was written in
# (no working nix daemon, no python/pip); this is a line-based heuristic
# converter instead. Re-running through pandoc later for higher fidelity is
# recommended once a full nix environment is available.
#
# Usage: perl migrate_sphinx_docs.pl
# Idempotent: re-running overwrites previously generated output.

use strict;
use warnings;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Find;
use File::Copy;

my $REPO_ROOT   = File::Spec->rel2abs(dirname(__FILE__) . '/..');
my $DOC_SRC     = File::Spec->rel2abs("$REPO_ROOT/../inasafe-doc/docs/source");
my $RESOURCES   = "$DOC_SRC/../resources/en";
my $OUT_ROOT    = "$REPO_ROOT/docs";

# [source subtree relative to $DOC_SRC, destination subtree relative to $OUT_ROOT]
my @TREES = (
    ['user-docs', 'manual'],
    ['training/qgis',         'training/qgis'],
    ['training/osm',          'training/osm'],
    ['training/curriculum',   'training/curriculum'],
    ['training/tot',          'training/tot'],
    ['training/socialisation','training/socialisation'],
    # training/old-training deliberately excluded: superseded legacy content.
);

# RST substitution -> plain text (from conf.py's rst_prolog/rst_epilog).
my %SUBST = (
    project_name => 'InaSAFE',
    QGIS         => 'QGIS',
    osm          => 'OpenStreetMap',
    OSM          => 'OpenStreetMap',
    github       => 'GitHub',
    AIFDR        => 'AIFDR',
    BNPB         => 'BNPB',
    GoA          => 'Australian Government',
    GFDRR        => 'GFDRR',
    GA           => 'GA',
    Linfiniti    => 'Linfiniti',
    Kartoza      => 'Kartoza',
    HOT          => 'HOT',
    DFATAusAid   => 'DFAT-Australian Aid',
    updatedisclaimer => '*DISCLAIMER: This section of the documentation needs updating.*',
);

my %ADMONITION_MAP = (
    note => 'note', Note => 'note', warning => 'warning', tip => 'tip',
    important => 'important', hint => 'tip', error => 'danger',
    danger => 'danger', caution => 'warning', attention => 'warning',
    seealso => 'info', todo => 'note',
);

my $total_files = 0;
my @bad_pages;

for my $tree (@TREES) {
    my ($src_rel, $dst_rel) = @$tree;
    my $src_root = "$DOC_SRC/$src_rel";
    next unless -d $src_root;

    find({
        no_chdir => 1,
        wanted => sub {
            return unless -f $_ && /\.rst$/;
            my $rel = File::Spec->abs2rel($_, $src_root);
            my $dst_md = $rel;
            $dst_md =~ s/\.rst$/.md/;
            my $dst_path = "$OUT_ROOT/$dst_rel/$dst_md";
            make_path(dirname($dst_path));
            convert_file($_, $dst_path, "$dst_rel/" . dirname($dst_md));
            $total_files++;
        },
    }, $src_root);
}

print "Converted $total_files RST files.\n";
print "Pages flagged for manual follow-up (TODO markers left in content):\n";
print "  $_\n" for @bad_pages;

# ---------------------------------------------------------------------------

sub convert_file {
    my ($src, $dst, $page_dir_rel) = @_;
    open(my $in, '<', $src) or die "read $src: $!";
    my @lines = <$in>;
    close $in;
    chomp @lines;

    my @out;
    my %heading_level;   # adornment char -> level, in order of first use
    my $next_level = 1;
    my $has_todo = 0;
    my $i = 0;
    my $n = scalar @lines;

    while ($i < $n) {
        my $line = $lines[$i];

        # Drop :orphan: field and blank line immediately after.
        if ($line =~ /^:orphan:\s*$/) { $i++; next; }

        # Hyperlink target definitions used only for :ref: anchors, e.g. ".. _label:"
        if ($line =~ /^\.\.\s+_[\w-]+:\s*$/) { $i++; next; }
        # Role definitions, e.g. ".. role:: disclaimer" - no Markdown equivalent needed.
        if ($line =~ /^\.\.\s+role::/) { $i++; next; }

        # Section heading: text line followed by a line of repeated adornment chars.
        my $adorn_char;
        if ($i + 1 < $n && $lines[$i+1] =~ /^([=\-~^"'`#*+.:_])\1{2,}\s*$/) {
            $adorn_char = $1;
        }
        if (defined $adorn_char
            && length($lines[$i+1]) >= length($line) - 2 && $line =~ /\S/
            && $line !~ /^\.\./ ) {
            my $char = $adorn_char;
            unless (exists $heading_level{$char}) {
                $heading_level{$char} = $next_level++;
            }
            my $level = $heading_level{$char} > 6 ? 6 : $heading_level{$char};
            my $text = $line;
            $text =~ s/^\s+|\s+$//g;
            push @out, ('#' x $level) . ' ' . apply_inline($text);
            push @out, '';
            $i += 2;
            # Skip an optional overline that preceded the title (already consumed as $line).
            next;
        }

        # Admonition directives: .. note:: / .. warning:: / etc.
        if ($line =~ /^(\s*)\.\.\s+(\w+)::\s*(.*)$/ && exists $ADMONITION_MAP{$2}) {
            my ($indent, $kind, $rest) = ($1, $2, $3);
            my $mdkind = $ADMONITION_MAP{$kind};
            push @out, "!!! $mdkind";
            $i++;
            # Trailing same-line text after ".. note::" is RST body content
            # (the first line of the admonition paragraph), NOT a title -
            # directives take no title argument in RST.
            push @out, '    ' . apply_inline($rest) if $rest =~ /\S/;
            # Consume the indented body, re-indent by 4 spaces for mkdocs-material.
            while ($i < $n && ($lines[$i] =~ /^\s+\S/ || $lines[$i] =~ /^\s*$/)) {
                last if $lines[$i] =~ /^\S/; # dedent marks end of block
                my $body = $lines[$i];
                $body =~ s/^\s{0,4}//;
                push @out, '    ' . apply_inline($body);
                $i++;
                # Stop if next non-blank line is back at column 0 (new block).
                if ($i < $n && $lines[$i] =~ /^\S/) { last; }
            }
            push @out, '';
            next;
        }

        # image:: / figure::
        if ($line =~ /^(\s*)\.\.\s+(image|figure)::\s*(\S+)\s*$/) {
            my ($indent, $kind, $path) = ($1, $2, $3);
            $i++;
            # consume option/caption lines (indented) for figure
            my @caption;
            while ($i < $n && $lines[$i] =~ /^\s+\S/) {
                my $opt = $lines[$i];
                if ($opt !~ /^\s*:\w+:/) {
                    my $c = $opt; $c =~ s/^\s+//;
                    push @caption, $c if $c =~ /\S/;
                }
                $i++;
            }
            my $resolved = resolve_image($path);
            if ($resolved) {
                my $asset_dst = copy_asset($resolved, $path);
                my $rel_from_page = File::Spec->abs2rel("$OUT_ROOT/$asset_dst", "$OUT_ROOT/$page_dir_rel");
                push @out, '![' . apply_inline(join(' ', @caption)) . "]($rel_from_page)";
                if (@caption) { push @out, '*' . apply_inline(join(' ', @caption)) . '*'; }
            } else {
                push @out, "<!-- TODO: could not resolve image source: $path -->";
                $has_todo = 1;
            }
            push @out, '';
            next;
        }

        # toctree:: -> bullet list of links (best effort)
        if ($line =~ /^(\s*)\.\.\s+toctree::\s*$/) {
            $i++;
            while ($i < $n && ($lines[$i] =~ /^\s*:\w+:/ || $lines[$i] =~ /^\s*$/)) { $i++; } # options + blank lines
            while ($i < $n && ($lines[$i] =~ /^\s+\S/ || $lines[$i] =~ /^\s*$/)) {
                last if $lines[$i] =~ /^\S/; # dedent marks end of block
                my $entry = $lines[$i]; $entry =~ s/^\s+|\s+$//g;
                if ($entry =~ /\S/) {
                    push @out, "- [$entry]($entry.md)";
                }
                $i++;
            }
            push @out, '';
            next;
        }

        # table:: directive - pass body through as a fenced block, flag for manual fixup.
        if ($line =~ /^\s*\.\.\s+table::\s*(.*)$/) {
            my $caption = $1;
            push @out, "<!-- TODO: manually convert this RST table" . ($caption ? " ($caption)" : '') . " -->";
            push @out, '```';
            $has_todo = 1;
            $i++;
            while ($i < $n && ($lines[$i] =~ /^\s+\S/ || $lines[$i] =~ /^\s*$/)) {
                last if $lines[$i] =~ /^\S/;
                my $body = $lines[$i]; $body =~ s/^\s{0,4}//;
                push @out, $body;
                $i++;
            }
            push @out, '```', '';
            next;
        }

        # Any other unhandled directive -> flag and drop the directive line itself.
        if ($line =~ /^\s*\.\.\s+[\w-]+::/) {
            push @out, "<!-- TODO: unhandled RST directive: " . apply_inline($line) . " -->";
            $has_todo = 1;
            $i++;
            next;
        }

        # Literal block marker at end of a paragraph line: "text::" -> "text:" + fenced block
        my $lit_prefix;
        if ($line =~ /^(.*)::\s*$/) { $lit_prefix = $1; }
        if (defined $lit_prefix && $lit_prefix =~ /\S/ && $i + 1 < $n && $lines[$i+1] =~ /^\s*$/) {
            my $prefix = $lit_prefix;
            push @out, apply_inline($prefix) . ':';
            push @out, '';
            $i += 2; # skip the paragraph line and the following blank line
            if ($i < $n && $lines[$i] =~ /^\s+\S/) {
                push @out, '```';
                while ($i < $n && ($lines[$i] =~ /^\s+\S/ || $lines[$i] =~ /^\s*$/)) {
                    last if $lines[$i] =~ /^\S/;
                    my $body = $lines[$i]; $body =~ s/^\s{0,4}//;
                    push @out, $body;
                    $i++;
                }
                push @out, '```', '';
            }
            next;
        }

        # Bullet list marker normalisation: "* " -> "- "
        if ($line =~ /^(\s*)\*\s+(.*)$/) {
            push @out, "$1- " . apply_inline($2);
            $i++;
            next;
        }

        # Default: plain paragraph/content line, apply inline substitutions/roles.
        push @out, apply_inline($line);
        $i++;
    }

    open(my $out, '>', $dst) or die "write $dst: $!";
    print $out join("\n", @out) . "\n";
    close $out;

    push @bad_pages, File::Spec->abs2rel($dst, $OUT_ROOT) if $has_todo;
}

sub apply_inline {
    my ($text) = @_;
    return $text unless defined $text;

    # Substitutions |name|
    $text =~ s/\|(\w+)\|/exists $SUBST{$1} ? $SUBST{$1} : $1/ge;

    # Inline roles
    $text =~ s/:guilabel:`([^`]*)`/**$1**/g;
    $text =~ s/:menuselection:`([^`]*)`/**$1**/g;
    $text =~ s/:kbd:`([^`]*)`/`$1`/g;
    $text =~ s/:file:`([^`]*)`/`$1`/g;
    $text =~ s/:command:`([^`]*)`/`$1`/g;
    $text =~ s/:samp:`([^`]*)`/`$1`/g;
    $text =~ s/:sup:`([^`]*)`/<sup>$1<\/sup>/g;
    $text =~ s/:disclaimer:`([^`]*)`/*$1*/g;
    # :ref:`text` / :doc:`text` - drop the role, keep the label text (cross-ref
    # resolution across pages is out of scope for this automated first pass).
    $text =~ s/:ref:`([^`]*)`/$1/g;
    $text =~ s/:doc:`([^`]*)`/$1/g;

    # Double-backtick literals -> single backtick code spans.
    $text =~ s/``([^`]*)``/`$1`/g;

    return $text;
}

sub resolve_image {
    my ($path) = @_;
    $path =~ s{^/static/}{};
    my $base = "$RESOURCES/$path";
    if ($base =~ /\.\*$/) {
        (my $stem = $base) =~ s/\.\*$//;
        for my $ext (qw(png jpg jpeg gif svg PNG JPG)) {
            return "$stem.$ext" if -f "$stem.$ext";
        }
        return undef;
    }
    return -f $base ? $base : undef;
}

sub copy_asset {
    my ($abs_src, $orig_path) = @_;
    (my $rel = $orig_path) =~ s{^/static/}{};
    $rel =~ s/\.\*$//;
    my ($ext) = $abs_src =~ /\.(\w+)$/;
    $rel .= ".$ext" unless $rel =~ /\.\w+$/;
    my $dst_rel = "assets/$rel";
    my $dst_abs = "$OUT_ROOT/$dst_rel";
    make_path(dirname($dst_abs));
    copy($abs_src, $dst_abs) unless -f $dst_abs;
    return $dst_rel;
}
