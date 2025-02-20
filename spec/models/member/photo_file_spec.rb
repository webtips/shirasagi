require 'spec_helper'

describe Member::PhotoFile, dbscope: :example do
  describe ".create_from_upload!" do
    let(:file_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
    let(:basename) { File.basename(file_path) }

    shared_examples "member/photo_file is" do
      context "without resizing" do
        subject do
          Fs::UploadedFile.create_from_file(file_path, basename: basename) do |upload_file|
            described_class.create_from_upload!(upload_file) do |new_file|
              new_file.site_id = cms_site.id
              new_file.user_id = cms_user.id
            end
          end
        end

        it do
          expect(subject).to be_persisted
          expect(subject).to be_valid
          expect(::Fs.size(subject.path)).to be > 0
          expect(subject.site_id).to eq cms_site.id
          expect(subject.user_id).to eq cms_user.id
          expect(subject.model).to eq "member/photo"
          expect(subject.image_dimension).to eq [ 712, 210 ]

          expect(subject.thumbs.count).to eq 2
          expect(subject.thumb_url).to be_present
          expect(subject.thumb).to be_present
          expect(subject.thumb.image_dimension).to eq [ 160, 47 ]
          expect(subject.thumb(:detail)).to be_present
          expect(subject.thumb(:detail).image_dimension).to eq [ 712, 210 ]
        end
      end

      context "with resizing" do
        subject do
          Fs::UploadedFile.create_from_file(file_path, basename: basename) do |upload_file|
            described_class.create_from_upload!(upload_file, resizing: [ 180, 180 ])
          end
        end

        it do
          expect(subject).to be_persisted
          expect(subject).to be_valid
          expect(subject.site_id).to be_blank
          expect(subject.user_id).to be_blank
          expect(subject.model).to eq "member/photo"
          expect(::Fs.size(subject.path)).to be > 0
          expect(subject.image_dimension).to eq [ 180, 53 ]

          expect(subject.thumbs.count).to eq 2
          expect(subject.thumb_url).to be_present
          expect(subject.thumb).to be_present
          expect(subject.thumb.image_dimension).to eq [ 160, 47 ]
          expect(subject.thumb(:detail)).to be_present
          expect(subject.thumb(:detail).image_dimension).to eq [ 180, 53 ]
        end
      end
    end

    context "with ImageMagick6" do
      around do |example|
        MiniMagick.with_cli(:imagemagick) do
          example.run
        end
      end

      include_context "member/photo_file is"
    end

    context "with GraphicsMagick" do
      around do |example|
        MiniMagick.with_cli(:graphicsmagick) do
          example.run
        end
      end

      include_context "member/photo_file is"
    end
  end
end
