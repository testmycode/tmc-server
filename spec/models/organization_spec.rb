# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'vips'

describe Organization, type: :model do
  let(:valid_params) do
    {
      name: 'TestOrganization',
      information: 'TestInformation',
      slug: 'test-organization',
      verified: true
    }
  end
  describe 'validation' do
    it 'accepts valid parameters' do
      expect { Organization.create!(valid_params).to_not raise_error }
    end

    it 'requires a name' do
      should_be_invalid_params(valid_params.merge(name: nil))
    end

    it 'requires name to be reasonably short' do
      should_be_invalid_params(valid_params.merge(name: 'a' * 41))
    end

    it 'requires name to be unique' do
      Organization.create!(valid_params)
      should_be_invalid_params(valid_params)
    end

    it 'requires information to be not too long' do
      should_be_invalid_params(valid_params.merge(information: 'a' * 501))
    end

    it 'requires a slug' do
      should_be_invalid_params(valid_params.merge(slug: nil))
    end

    it 'requires slug to be lowercase alphanumeric' do
      should_be_invalid_params(valid_params.merge(slug: 'slug.'))
      should_be_invalid_params(valid_params.merge(slug: 'test slug'))
      should_be_invalid_params(valid_params.merge(slug: 'SLUG'))
    end

    it 'requires a pending flag' do
      should_be_invalid_params(valid_params.merge(verified: nil))
    end

    it 'requires slug to be a non-reserved url' do
      should_be_invalid_params(valid_params.merge(slug: 'new'))
    end

    def should_be_invalid_params(params)
      expect { Organization.create!(params) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'initialization' do
    it 'creates a pending organization' do
      @user = FactoryBot.create(:user)
      @org = Organization.init(valid_params, @user)
      expect(@org.verified).to be(false)
    end

    it 'grants the requesting user teachership to the organization' do
      @user = FactoryBot.create(:user)
      @org = Organization.init(valid_params, @user)
      expect(@org.teachers.include?(@user))
    end
  end

  describe 'logo' do
    def attach_logo(organization, width, height)
      png = Vips::Image.black(width, height).pngsave_buffer
      organization.logo.attach(io: StringIO.new(png), filename: 'logo.png', content_type: 'image/png')
    end

    def dimensions(variant)
      image = Vips::Image.new_from_buffer(variant.processed.download, '')
      [image.width, image.height]
    end

    it 'scales a wide logo down to 100 px wide, keeping its aspect ratio' do
      organization = Organization.create!(valid_params)
      attach_logo(organization, 300, 120)
      expect(dimensions(organization.org_logo)).to eq([100, 40])
    end

    it 'does not enlarge a logo narrower than 100 px' do
      organization = Organization.create!(valid_params)
      attach_logo(organization, 60, 90)
      expect(dimensions(organization.org_logo)).to eq([60, 90])
    end

    it 'links logo_path to the scaled variant' do
      organization = Organization.create!(valid_params)
      attach_logo(organization, 300, 120)
      expect(organization.logo_path).to start_with('/rails/active_storage/representations/')
    end

    it 'keeps a WebP logo as WebP when scaling it' do
      organization = Organization.create!(valid_params)
      webp = Vips::Image.black(300, 120).webpsave_buffer
      organization.logo.attach(io: StringIO.new(webp), filename: 'logo.webp', content_type: 'image/webp')
      expect(organization.org_logo.processed.image.blob.content_type).to eq('image/webp')
    end
  end
end
