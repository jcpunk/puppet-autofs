# @summary Defined type to manage a single submount within a multi-mount
#   map entry.
#
# When ensured 'present', an autofs::multi_mount resource managing the
# overall target map file must also be present in the catalog.  The submount
# is rendered as an indented, backslash-continued line of that file; the
# multi-mount entry itself is closed by the map file's terminating line.
# This resource implements Autofs's 'sun' map format, which is the default.
#
# It is not supported to declare multiple autofs::submounts with the
# same mountpoint, targeting the same map file, and ensured 'present'.
#
# Based on the original multi-mount work contributed by Chip Schweiss in
# https://github.com/voxpupuli/puppet-autofs/pull/164
#
# @see https://voxpupuli.org/puppet-autofs Home
# @see https://voxpupuli.org/puppet-autofs/puppet_classes/autofs.html puppet_classes::autofs
# @see https://www.github.com/voxpupuli/puppet-autofs Github
# @see https://forge.puppet.com/puppet/autofs Puppet Forge
# @see autofs(5) man page, section "Multiple Mounts"
#
# @author Vox Pupuli <voxpupuli@groups.io>
# @author David Hollinger III <david.hollinger@moduletux.com>
#
# @param ensure Whether the submount should be present in the target
#     mapfile; ensuring 'absent' is not meaningfully different from omitting
#     the resource declaration altogether
# @param fs the remote filesystem to mount
# @param mountpoint where this filesystem is mounted within the
#     multi-mount, relative to the multi-mount's key; '/' refers to the key
#     itself
# @param mapfile the absolute path to the file containing the multi-mount
#     map to which this submount belongs
# @param options a comma-delimited mount options string or an array of
#     individual mount options; these are appended to the multi-mount's
#     default options; neither individual options nor the overall option
#     list should be specified with a leading hyphen (-); that is part of
#     the map file format, not of the options themselves, and it is
#     provided by this resource
# @param order an integer describing the relative order of the submount
#     represented by this resource within the target map file (default 10).
#     Orders 0 and 999999 are reserved for the multi-mount root line and
#     the map file's terminating line respectively.
#
# @example A read-only archive submount within a per-user home multi-mount
#   autofs::submount { '/etc/auto.home:/archive':
#     mapfile    => '/etc/auto.home',
#     mountpoint => '/archive',
#     options    => 'ro',
#     fs         => 'archivefs.example.com:/export/archive/&'
#   }
#
define autofs::submount (
  Stdlib::Absolutepath $mapfile,
  Pattern[/\A\S+\z/] $mountpoint,
  Variant[String[1], Array[String[1]]] $fs,
  Enum['present', 'absent'] $ensure  = 'present',
  Optional[Autofs::Options] $options = undef,
  Integer[1, 999998] $order          = 10,
) {
  unless $ensure == 'absent' {
    $formatted_options = autofs::format_options($options)
    $formatted_fs = [$fs].flatten.map |$value| { if $value =~ /[[:blank:]"]/ { "\"${value.regsubst(/\\/, '\\\\', 'G').regsubst(/"/, '\"', 'G')}\"" } else { $value } }.join(' ')

    # Declare an appropriate fragment of the target map file
    concat::fragment { "autofs::submount/${title}":
      target  => $mapfile,
      content => "  ${mountpoint}\t${formatted_options}\t${formatted_fs} \\\n",
      order   => $order,
    }
  }
}
