require 'spec_helper'

describe Training do
  context 'Validations' do
    it 'should success' do
      training = FactoryGirl.create(:training)
      expect(training.valid?).to eq(true)
    end

    it 'should fail because Subject is nil' do
      training = FactoryGirl.build(:training, subject: nil)
      expect(training.valid?).to eq(false)
      expect(training.errors.full_messages).to eq(["Subject can't be blank"])
    end

    it 'should fail because objective is nil' do
      training = FactoryGirl.build(:training, objectives: nil)
      expect(training.valid?).to eq(false)
      expect(training.errors.full_messages).to eq(["Objectives can't be blank"])
    end

    it 'should fail because Duration is nil' do
      training = FactoryGirl.build(:training, duration: nil)
      expect(training.valid?).to eq(false)
      expect(training.errors.full_messages).to eq(["Duration can't be blank"])
    end
  end

  context 'Chapters' do
    it 'should pass if chapter is valid' do
      training = FactoryGirl.create(:training)
      chapter = FactoryGirl.create(:chapter, training: training)
      expect(training.reload.chapters.count).to eq(1)
      expect(training.reload.chapters[0]).to eq(chapter)
    end

    it 'should fail if chapter is invalid' do
      training = FactoryGirl.create(:training)
      chapter = FactoryGirl.build(:chapter, training: training, chapter_number: nil)
      expect(chapter.valid?).to eq(false)
      expect(chapter.errors.full_messages).to eq(["Chapter number can't be blank"])
    end

    it 'should fail if chapter_number is already present for training' do
      training = FactoryGirl.create(:training)
      chapter1 = FactoryGirl.create(:chapter, training: training, chapter_number: 1)
      expect(chapter1.valid?).to eq(true)
      chapter2 = FactoryGirl.build(:chapter, training: training, chapter_number: 1)
      expect(chapter2.valid?).to eq(false)
      expect(training.reload.chapters.count).to eq(1)
      expect(training.reload.chapters[0]).to eq(chapter1)
    end

    it 'should pass if chapter_number is same for different training' do
      training1 = FactoryGirl.create(:training)
      training2 = FactoryGirl.create(:training)
      chapter1 = FactoryGirl.create(:chapter, training: training1, chapter_number: 1)
      expect(chapter1.valid?).to eq(true)
      chapter2 = FactoryGirl.build(:chapter, training: training2, chapter_number: 1)
      expect(chapter2.valid?).to eq(true)
    end
  end
end
