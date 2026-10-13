# A type representing a single submount within a multi-mount map entry:
# the mountpoint at which one filesystem is mounted relative to the
# multi-mount's key, the filesystem itself, and optional per-mount options
# and ordering.  The "_mapping" suffix mirrors Autofs::Fs_mapping (data for
# an autofs::mapping resource); a bare Autofs::Submount would collide with
# the resource type of the autofs::submount defined type.  The mountpoint
# is restricted to a non-blank string since it appears within a
# backslash-continued multi-mount line, and the order to values between the
# reserved first (0) and last (999999) lines of a multi-mount map file.
#
# @example Typical submount within a multi-mount entry
#   { 'mountpoint' => '/data', 'options' => 'ro', 'fs' => 'data.com:/export/data' }
#
type Autofs::Submount_mapping = Struct[
  {
    mountpoint => Pattern[/\A\S+\z/],
    options    => Optional[Autofs::Options],
    order      => Optional[Integer[1, 999998]],
    fs         => Variant[String[1], Array[String[1]]],
  }
]
