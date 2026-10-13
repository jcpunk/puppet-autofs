# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'autofs::multi_mount used standalone' do
  context 'with simple configuration' do
    it 'applies' do
      pp = <<-EOS
        autofs::multi_mount { '/etc/auto.home':
          key     => '*',
          options => 'ro',
          submounts => [
            { 'mountpoint' => '/', 'fs' => 'home.net:/export/home/&' },
            { 'mountpoint' => '/archive', 'options' => 'ro', 'fs' => 'archive.net:/export/archive/&', 'order' => 20 },
          ],
        }
        autofs::submount { '/etc/auto.home:/scratch':
          mapfile    => '/etc/auto.home',
          mountpoint => '/scratch',
          fs         => 'scratch.net:/export/scratch/&',
          order      => 30,
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.home') do
      it 'exists and belongs to root' do
        expect(subject).to exist
        expect(subject).to be_owned_by 'root'
        expect(subject).to be_grouped_into 'root'
      end

      its(:content) do
        is_expected.to match %r{\A##}
        is_expected.to match(%r{^\* -ro \\\s*$})
        is_expected.to match(%r{^\s+/\\\s+home.net:/export/home/& \\\s*$})
        is_expected.to match(%r{^\s+/archive\s+-ro\s+archive.net:/export/archive/& \\\s*$})
        is_expected.to match(%r{^\s+/scratch\s+\s+scratch.net:/export/scratch/& \\\s*$})
      end

      it 'orders the root line first and terminates the entry' do
        lines = subject.content.lines.grep_v(%r{^#|^\s*\z})
        expect(lines.first).to match(%r{\A\* -ro \\\s*\z})
        expect(lines.last).to match(%r{\A\s+/scratch\s.* \\\s*\z})
      end
    end
  end

  context 'without ensuring absence' do
    it 'applies' do
      pp = <<-EOS
        autofs::multi_mount { '/etc/auto.home':
          ensure => 'absent',
          key    => '*',
        }
      EOS

      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    describe file('/etc/auto.home') do
      it { is_expected.not_to exist }
    end
  end
end
