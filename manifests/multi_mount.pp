# @summary Defined type to manage a single multi-mount entry, stored as an
#   autofs map file.
#
# A multi-mount is a single map entry whose map field specifies multiple
# filesystems, mounted together under one key: a single lookup of the key
# mounts every filesystem of the entry at once.  The map file consists of a
# root line holding the entry key (optionally followed by map-wide
# options), and one or more continuation lines, each contributed by an
# autofs::submount resource targeting this map file.  Continuation lines
# are ordered numerically; orders 0 and 999999 are reserved for the root
# line and the map file's terminating line respectively.
#
# This resource implements Autofs's 'sun' map format, which is the default.
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
# @param key the autofs map key that roots the multi-mount; every submount
#     of the entry is mounted at or below this key.  For an indirect map
#     (e.g. a per-user map for /home) this is typically a name or the
#     wildcard '*'; for a direct map it is a path.
# @param ensure Whether the mapfile should be present on the target system
# @param path An absolute path to the map file
# @param submounts an array of submounts to enroll in the file.  Additional
#     submounts can be specified for this mapfile via autofs::submount
#     resources
# @param options default (map-wide) mount options for the entry; per-submount
#     options are appended to these.  A comma-delimited mount options string
#     or an array of individual mount options; neither individual options nor
#     the overall option list should be specified with a leading hyphen (-)
# @param replace Whether to replace the contents of any an existing file
#     at the specified path
# @param execute Whether to make the mapfile executable or not
#
# @example Per-user homes with per-user subdirectories from other servers
#   autofs::multi_mount { '/etc/auto.home':
#     key       => '*',
#     submounts => [
#       { 'mountpoint' => '/',        'fs' => 'homefs.example.com:/export/home/&' },
#       { 'mountpoint' => '/archive', 'options' => 'ro', 'fs' => 'archivefs.example.com:/export/archive/&' },
#     ],
#   }
#
define autofs::multi_mount (
  Pattern[/\A\S+\z/] $key,
  Enum['present', 'absent'] $ensure   = 'present',
  Stdlib::Absolutepath $path          = $title,
  Array[Autofs::Submount_mapping] $submounts = [],
  Optional[Autofs::Options] $options  = undef,
  Boolean $replace                    = true,
  Boolean $execute                    = false,
) {
  include 'autofs'

  unless $autofs::package_ensure == 'absent' {
    if $autofs::reload_command {
      Concat {
        before => Service[$autofs::service_name],
        notify => Exec['automount-reload'],
      }
    } else {
      Concat {
        notify => Service[$autofs::service_name],
      }
    }
  }

  $mapfile_mode = $execute ? {
    true => '0755',
    false => '0644'
  }

  concat { $path:
    ensure  => $ensure,
    owner   => $autofs::map_file_owner,
    group   => $autofs::map_file_group,
    mode    => $mapfile_mode,
    replace => $replace,
    order   => 'numeric',
    require => Class['autofs::package'],
    warn    => template('autofs/mapfile.banner.erb'),
  }

  if $ensure == 'present' {
    # Format the map-wide options string for the multi-mount root line
    $formatted_options = autofs::format_options($options)

    # The root line introduces the multi-mount and is always ordered first
    $root_content = $formatted_options ? {
      ''      => "${key} \\\n",
      default => "${key} ${formatted_options} \\\n",
    }
    concat::fragment { "autofs::multi_mount/${title}::root":
      target  => $path,
      content => $root_content,
      order   => 0,
    }

    # Every submount line ends with a backslash continuation; this blank
    # line terminates the multi-mount entry and is always ordered last
    concat::fragment { "autofs::multi_mount/${title}::endline":
      target  => $path,
      content => "\n",
      order   => 999999,
    }

    $submounts.each |$submount| {
      autofs::submount { "${path}:${submount[mountpoint]}":
        ensure  => 'present',
        mapfile => $path,
        *       => $submount,
      }
    }
  }
}
