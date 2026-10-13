# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::submount', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:title) { '/etc/auto.home:/archive' }

      context 'with no options' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            fs: 'archive.host.net:/export/archive/&',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).not_to contain_class('autofs')
          expect(subject).to have_concat_resource_count(0)
          expect(subject).to have_concat__fragment_resource_count(1)
          expect(subject).to contain_concat__fragment('autofs::submount//etc/auto.home:/archive')
            .with(target: '/etc/auto.home', order: 10)
            .with_content("  /archive\t\tarchive.host.net:/export/archive/& \\\n")
        end
      end

      context 'with options as a string' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            options: 'ro',
            fs: 'archive.host.net:/export/archive/&',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat__fragment('autofs::submount//etc/auto.home:/archive')
            .with_content("  /archive\t-ro\tarchive.host.net:/export/archive/& \\\n")
        end
      end

      context 'with options as an array' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            options: %w[ro noexec],
            fs: 'archive.host.net:/export/archive/&',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat__fragment('autofs::submount//etc/auto.home:/archive')
            .with_content("  /archive\t-ro,noexec\tarchive.host.net:/export/archive/& \\\n")
        end
      end

      context 'with order' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            fs: 'archive.host.net:/export/archive/&',
            order: 20,
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat__fragment('autofs::submount//etc/auto.home:/archive')
            .with(order: 20)
        end
      end

      context 'with reserved order' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            fs: 'archive.host.net:/export/archive/&',
            order: 0,
          }
        end

        it { is_expected.to compile.and_raise_error(%r{order}) }
      end

      context 'with ensure absent' do
        let(:params) do
          {
            ensure: 'absent',
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            fs: 'archive.host.net:/export/archive/&',
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to have_concat__fragment_resource_count(0)
        end
      end

      context 'with replicated filesystems' do
        let(:params) do
          {
            mapfile: '/etc/auto.home',
            mountpoint: '/archive',
            options: 'ro',
            fs: [
              'archive.host.net:/export/archive/&',
              'backup.host.net:/export/archive/&',
            ],
          }
        end

        it do
          expect(subject).to compile
          expect(subject).to contain_concat__fragment('autofs::submount//etc/auto.home:/archive')
            .with_content("  /archive\t-ro\tarchive.host.net:/export/archive/& backup.host.net:/export/archive/& \\\n")
        end
      end
    end
  end
end
