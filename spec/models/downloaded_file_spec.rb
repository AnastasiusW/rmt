require 'spec_helper'
require 'rails_helper'


describe DownloadedFile, type: :model do
  describe '#add_file!' do
    let(:test_file_1_path) { file_fixture('dummy_product/product/apples-0.1-0.x86_64.rpm').to_s }
    let(:test_file_2_path) { file_fixture('dummy_product/product/apples-0.2-0.x86_64.rpm').to_s }

    before do
      add_downloaded_file('foo', 'bar', test_file_1_path)
      add_downloaded_file('foobar', 'barfoo', test_file_2_path)
    end

    it 'has file1' do
      expect(DownloadedFile.find_by(checksum_type: 'foo', checksum: 'bar').local_path).to eq(test_file_1_path)
    end

    it 'has the file size of file1' do
      expect(DownloadedFile.find_by(checksum_type: 'foo', checksum: 'bar').file_size).to eq(File.size(test_file_1_path))
    end

    it 'has file2' do
      expect(DownloadedFile.find_by(checksum_type: 'foobar', checksum: 'barfoo').local_path).to eq(test_file_2_path)
    end

    it 'has the file size of file2' do
      expect(DownloadedFile.find_by(checksum_type: 'foobar', checksum: 'barfoo').file_size).to eq(File.size(test_file_2_path))
    end

    it 'handles duplicates' do
      add_downloaded_file('foo', 'bar', test_file_2_path)
      expect(DownloadedFile.find_by(checksum_type: 'foo', checksum: 'bar').local_path).to eq(test_file_1_path)
    end
  end

  describe '#valid_local_file?' do
    let(:checksum_type) { 'SHA256' }
    let(:checksum) { '5c4e3fa1624bd23251eecdda9c7fcefad045995a9eaed527d06dd8510cfe2851' }
    let(:test_file_path) { file_fixture('dummy_product/product/apples-0.1-0.x86_64.rpm').to_s }

    it 'returns true if the file is valid' do
      add_downloaded_file(checksum_type, checksum, test_file_path)
      expect(DownloadedFile.valid_local_file?(checksum_type, checksum, test_file_path)).to be(true)
    end

    it 'returns false for invalid files' do
      add_downloaded_file(checksum_type, checksum, test_file_path)
      expect(DownloadedFile.valid_local_file?(checksum_type, checksum.sub('5', '2'), test_file_path)).to be(false)
    end

    it 'returns false when file does not exist yet' do
      expect(DownloadedFile.valid_local_file?(checksum_type, checksum, 'foo.rpm')).to be(false)
    end

    it 'tracks the file again if not yet tracked' do
      file = add_downloaded_file(checksum_type, checksum, test_file_path)
      file.destroy

      expect(DownloadedFile.where(local_path: test_file_path).count).to eq(0)
      expect(DownloadedFile.valid_local_file?(checksum_type, checksum, test_file_path)).to be(true)
      expect(DownloadedFile.where(local_path: test_file_path).count).to eq(1)
    end

    it 'stops tracking invalid files' do
      add_downloaded_file(checksum_type, checksum.sub('5', '2'), test_file_path)
      expect(DownloadedFile.where(local_path: test_file_path).count).to eq(1)
      expect(DownloadedFile.valid_local_file?(checksum_type, checksum, test_file_path)).to be(false)
      expect(DownloadedFile.where(local_path: test_file_path).count).to eq(0)
    end
  end

  describe '#get_local_path_by_checksum' do
    let(:checksum_type) { 'SHA256' }
    let(:checksum) { '5c4e3fa1624bd23251eecdda9c7fcefad045995a9eaed527d06dd8510cfe2851' }
    let(:test_file_path) { file_fixture('dummy_product/product/apples-0.1-0.x86_64.rpm').to_s }
    let(:test_file_2_path) { file_fixture('dummy_product/product/apples-0.2-0.x86_64.rpm').to_s }

    it 'gets the correct path with proper checksum' do
      file = add_downloaded_file(checksum_type, checksum, test_file_path)
      expect(DownloadedFile.get_local_path_by_checksum(checksum_type, checksum)).to eq(file)
    end

    it 'returns nil if files has been changed' do
      add_downloaded_file(checksum_type, checksum, test_file_path)
      file = DownloadedFile.find_by(checksum_type: checksum_type, checksum: checksum)
      file.update(local_path: test_file_2_path)
      expect(DownloadedFile.get_local_path_by_checksum(checksum_type, 'foo')).to be_nil
    end

    it 'handles missing files' do
      add_downloaded_file(checksum_type, checksum, '/foo/bar')
      expect(DownloadedFile.get_local_path_by_checksum(checksum_type, checksum)).to be_nil
    end
  end
end
