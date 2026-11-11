# typed: false
# frozen_string_literal: true

require 'spec_helper'

describe RustLangsDownloaderTask do
  let(:task) { described_class.new }
  let(:fake_binary) { "#!/bin/sh\necho tmc-langs\n" }
  let(:executable) { "vendor/tmc-langs-rust/tmc-langs-cli-x86_64-unknown-linux-gnu-#{described_class::RUST_LANGS_VERSION}" }

  # The cwd is the emptied per-example tmp/tests, which stands in for Rails.root here.
  before :each do
    Dir.mkdir('vendor')
    allow(task).to receive(:sleep)
    allow(task).to receive(:system) do |*args|
      File.write(args.fetch(3), fake_binary)
      true
    end
  end

  it 'installs a download that matches the pinned SHA-256' do
    stub_const("#{described_class}::RUST_LANGS_SHA256", Digest::SHA256.hexdigest(fake_binary))
    task.run
    expect(File.executable?(executable)).to be(true)
    expect(File.readlink('vendor/tmc-langs-rust/current')).to eq(File.basename(executable))
  end

  it 'deletes and refuses a download that does not match the pinned SHA-256' do
    expect(Rails.logger).to receive(:error).with(/SHA-256/)
    expect { task.run }.to raise_error(described_class::ChecksumMismatch)
    expect(Dir.children('vendor/tmc-langs-rust')).to be_empty
  end

  it 'raises with the exit status when wget fails' do
    allow(task).to receive(:system) do |*args|
      File.write(args.fetch(3), 'partial')
      Kernel.system('sh', '-c', 'exit 8')
    end
    expect { task.run }.to raise_error(described_class::DownloadFailed, /exit 8/)
    expect(Dir.children('vendor/tmc-langs-rust')).to be_empty
  end

  it 'deletes a download that does not run and backs off' do
    stub_const("#{described_class}::RUST_LANGS_SHA256", Digest::SHA256.hexdigest("#!/bin/sh\nexit 1\n"))
    allow(task).to receive(:system) do |*args|
      File.write(args.fetch(3), "#!/bin/sh\nexit 1\n")
      true
    end
    expect(Rails.logger).to receive(:error).with(/did not run/)
    expect { task.run }.to raise_error(described_class::BinaryDoesNotRun)
    expect(Dir.children('vendor/tmc-langs-rust')).to be_empty
    expect(task.wait_delay).to eq(60)
  end

  it 'backs off after consecutive failures, up to an hour, and resets after a success' do
    allow(Rails.logger).to receive(:error)
    expect(task.wait_delay).to eq(1)
    delays = Array.new(8) do
      expect { task.run }.to raise_error(described_class::ChecksumMismatch)
      task.wait_delay
    end
    expect(delays).to eq([60, 120, 240, 480, 960, 1920, 3600, 3600])

    stub_const("#{described_class}::RUST_LANGS_SHA256", Digest::SHA256.hexdigest(fake_binary))
    task.run
    expect(task.wait_delay).to eq(1)
  end
end
