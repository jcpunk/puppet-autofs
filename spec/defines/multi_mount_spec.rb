# frozen_string_literal: true

require 'spec_helper'

describe 'autofs::multi_mount', type: :define do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        let(:title) { '/etc/auto.home' }
        let(:params) { { key: '*' } }

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_class('autofs')
          expect(subject).to contain_concat('/etc/auto.home')
            .with(ensure: 'present', replace: true, mode: '0644', order: 'numeric')
          expect(subject).to contain_concat__fragment('autofs::multi_mount//etc/auto.home::root')
            .with(target: '/etc/auto.home', order: 0)
            .with_content("* \\\n")
          expect(subject).to contain_concat__fragment('autofs::multi_mount//etc/auto.home::endline')
            .with(target: '/etc/auto.home', order: 999_999)
            .with_content("\n")
        end
      end

      context 'with entry options as a string' do
        let(:title) { '/etc/auto.home' }
        let(:params) do
          {
            key: '*',
            options: 'ro',
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat__fragment('autofs::multi_mount//etc/auto.home::root')
            .with_content("* -ro \\\n")
        end
      end

      context 'with entry options as an array' do
        let(:title) { '/etc/auto.home' }
        let(:params) do
          {
            key: '*',
            options: %w[ro noexec],
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat__fragment('autofs::multi_mount//etc/auto.home::root')
            .with_content("* -ro,noexec \\\n")
        end
      end

      context 'with explicit path' do
        let(:title) { 'home' }
        let(:params) do
          {
            path: '/etc/autofs/home', # an unconventional path
            key: '*',
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat('/etc/autofs/home')
            .with(ensure: 'present', replace: true)
          expect(subject).to contain_concat__fragment('autofs::multi_mount/home::root')
            .with(target: '/etc/autofs/home')
        end
      end

      context 'without replacement' do
        let(:title) { '/etc/auto.home' }
        let(:params) { { key: '*', replace: false } }

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat('/etc/auto.home')
            .with(ensure: 'present', replace: false)
        end
      end

      context 'with execute' do
        let(:title) { '/etc/auto.home' }
        let(:params) { { key: '*', execute: true } }

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat('/etc/auto.home')
            .with(ensure: 'present', mode: '0755')
        end
      end

      context 'without ensuring absence' do
        let(:title) { '/etc/auto.home' }
        let(:params) { { key: '*', ensure: 'absent' } }

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat('/etc/auto.home')
            .with(ensure: 'absent')
          expect(subject).to have_concat__fragment_resource_count(0)
        end
      end

      context 'with submounts' do
        let(:title) { '/etc/auto.home' }
        let(:params) do
          {
            key: '*',
            submounts: [
              { mountpoint: '/', fs: 'home.com:/export/home/&' },
              { mountpoint: '/scratch', fs: 'scratch.com:/export/scratch/&', order: 15 },
              { mountpoint: '/archive', options: 'ro', fs: 'archive.com:/export/archive/&' },
            ],
          }
        end

        it do
          expect(subject).to compile.with_all_deps
          expect(subject).to contain_concat('/etc/auto.home')
            .with(ensure: 'present')
          expect(subject).to have_autofs__submount_resource_count(3)
          expect(subject).to contain_autofs__submount('/etc/auto.home:/')
            .with(mapfile: '/etc/auto.home', mountpoint: '/', fs: 'home.com:/export/home/&')
          expect(subject).to contain_autofs__submount('/etc/auto.home:/scratch')
            .with(mapfile: '/etc/auto.home', mountpoint: '/scratch', fs: 'scratch.com:/export/scratch/&', order: 15)
          expect(subject).to contain_autofs__submount('/etc/auto.home:/archive')
            .with(mapfile: '/etc/auto.home', mountpoint: '/archive', options: 'ro', fs: 'archive.com:/export/archive/&')
        end
      end
    end
  end
end
