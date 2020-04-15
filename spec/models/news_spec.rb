require 'rails_helper'

RSpec.describe News, type: :model do
  # pending "add some examples to (or delete) #{__FILE__}"
  it { should have_fields(:date, :title, :link, :description, :image_url) }
  it 'should format the date' do
    news = FactoryGirl.create(:news, date: '22/04/2020')
    expect(news.formatted_date).to eq('22 Apr 2020')
  end
end
